<?php

namespace App\Http\Controllers\Admin;

use App\Services\QuietTimeVideoService;
use App\Services\SupabaseAdminService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;
use Throwable;

class QuietTimeVideoAdminController extends Controller
{
    public function __construct(
        private readonly QuietTimeVideoService $videoService,
        private readonly SupabaseAdminService $supabase,
    ) {
    }

    // ── List ──────────────────────────────────────────────────────────────

    public function index(Request $request): View
    {
        $filters = [
            'session_type' => 'eq.video',
            'order' => 'sort_order.asc',
            'select' => '*,quiet_time_categories(name,slug)',
        ];

        if ($request->filled('status')) {
            $filters['status'] = 'eq.' . $request->string('status');
        }

        if ($request->filled('search')) {
            $term = '%' . trim((string) $request->string('search')) . '%';
            $filters['or'] = "title.ilike.$term,description.ilike.$term";
        }

        $sessions   = $this->supabase->listRows('quiet_time_sessions', $filters);
        $categories = $this->supabase->quietTimeCategories();

        return view('admin.quiet_time_videos.index', compact('sessions', 'categories'));
    }

    // ── Create ────────────────────────────────────────────────────────────

    public function create(): View
    {
        $categories = $this->supabase->quietTimeCategories();
        return view('admin.quiet_time_videos.create', compact('categories'));
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'title'              => ['required', 'string', 'max:200'],
            'description'        => ['nullable', 'string', 'max:1000'],
            'category_id'        => ['required', 'string'],
            'duration_minutes'   => ['required', 'integer', 'min:1', 'max:180'],
            'scripture_reference'=> ['nullable', 'string', 'max:200'],
            'reflection_prompt'  => ['nullable', 'string', 'max:500'],
            'difficulty_level'   => ['nullable', 'in:beginner,intermediate,advanced'],
            'is_premium'         => ['nullable', 'boolean'],
            'status'             => ['required', 'in:draft,published,hidden,archived'],
            'video'              => ['nullable', 'file', 'mimetypes:video/mp4,video/quicktime,video/x-m4v,video/webm', 'max:512000'],
        ]);

        $slug = $this->generateSlug((string) $data['title']);

        $payload = [
            'category_id'        => $data['category_id'],
            'title'              => $data['title'],
            'slug'               => $slug,
            'description'        => $data['description'] ?? null,
            'duration_minutes'   => (int) $data['duration_minutes'],
            'session_type'       => 'video',
            'scripture_reference'=> $data['scripture_reference'] ?? null,
            'reflection_prompt'  => $data['reflection_prompt'] ?? null,
            'difficulty_level'   => $data['difficulty_level'] ?? null,
            'is_premium'         => (bool) ($data['is_premium'] ?? false),
            'is_active'          => true,
            'status'             => $data['status'],
            'sort_order'         => 0,
        ];

        try {
            $rows      = $this->supabase->insert('quiet_time_sessions', $payload);
            $sessionId = (string) (is_array($rows) ? ($rows[0]['id'] ?? '') : '');

            if ($request->hasFile('video') && $sessionId !== '') {
                $this->videoService->uploadVideoForSession(
                    sessionId: $sessionId,
                    video: $request->file('video'),
                    status: (string) $data['status'],
                );
            }
        } catch (ValidationException $e) {
            return back()->withErrors($e->errors())->withInput();
        } catch (Throwable $e) {
            report($e);
            return back()
                ->withErrors(['title' => 'Failed to create session: ' . $e->getMessage()])
                ->withInput();
        }

        return redirect()->route('admin.qt-videos.index')
            ->with('status', 'Quiet Time video session created.');
    }

    // ── Edit ─────────────────────────────────────────────────────────────

    public function edit(string $sessionId): View
    {
        $session = $this->supabase->firstBy('quiet_time_sessions', ['id' => "eq.$sessionId"]);
        abort_unless(is_array($session), 404, 'Session not found.');

        $categories = $this->supabase->quietTimeCategories();
        $chapters   = $this->supabase->quietTimeVideoChapters($sessionId);

        return view('admin.quiet_time_videos.edit', compact('session', 'categories', 'chapters'));
    }

    public function update(Request $request, string $sessionId): RedirectResponse
    {
        $data = $request->validate([
            'title'              => ['required', 'string', 'max:200'],
            'description'        => ['nullable', 'string', 'max:1000'],
            'category_id'        => ['required', 'string'],
            'duration_minutes'   => ['required', 'integer', 'min:1', 'max:180'],
            'scripture_reference'=> ['nullable', 'string', 'max:200'],
            'reflection_prompt'  => ['nullable', 'string', 'max:500'],
            'difficulty_level'   => ['nullable', 'in:beginner,intermediate,advanced'],
            'is_premium'         => ['nullable', 'boolean'],
            'status'             => ['required', 'in:draft,published,hidden,archived'],
        ]);

        try {
            $this->supabase->updateByFilters(
                'quiet_time_sessions',
                ['id' => "eq.$sessionId"],
                [
                    'category_id'        => $data['category_id'],
                    'title'              => $data['title'],
                    'description'        => $data['description'] ?? null,
                    'duration_minutes'   => (int) $data['duration_minutes'],
                    'scripture_reference'=> $data['scripture_reference'] ?? null,
                    'reflection_prompt'  => $data['reflection_prompt'] ?? null,
                    'difficulty_level'   => $data['difficulty_level'] ?? null,
                    'is_premium'         => (bool) ($data['is_premium'] ?? false),
                    'status'             => $data['status'],
                    'updated_at'         => now()->toISOString(),
                ],
            );
        } catch (Throwable $e) {
            report($e);
            return back()->withErrors(['title' => 'Update failed: ' . $e->getMessage()])->withInput();
        }

        return redirect()->route('admin.qt-videos.edit', $sessionId)
            ->with('status', 'Session updated successfully.');
    }

    // ── Upload video ──────────────────────────────────────────────────────

    public function upload(Request $request, string $sessionId): RedirectResponse
    {
        $payload = $request->validate([
            'video'  => ['required', 'file', 'mimetypes:video/mp4,video/quicktime,video/x-m4v,video/webm', 'max:512000'],
            'status' => ['nullable', 'in:draft,published,hidden,archived'],
        ]);

        try {
            $this->videoService->uploadVideoForSession(
                sessionId: $sessionId,
                video: $payload['video'],
                status: (string) ($payload['status'] ?? 'draft'),
            );
        } catch (ValidationException $e) {
            return back()->withErrors($e->errors())->withInput();
        } catch (Throwable $e) {
            report($e);
            return back()->withErrors(['video' => 'Upload failed: ' . $e->getMessage()])->withInput();
        }

        return redirect()->route('admin.qt-videos.edit', $sessionId)
            ->with('status', 'Video uploaded. Signed playback URL is now active.');
    }

    // ── Publish / Archive ─────────────────────────────────────────────────

    public function publish(string $sessionId): RedirectResponse
    {
        $this->supabase->updateByFilters(
            'quiet_time_sessions',
            ['id' => "eq.$sessionId"],
            [
                'status'     => 'published',
                'is_active'  => true,
                'updated_at' => now()->toISOString(),
            ],
        );

        return back()->with('status', 'Session is now live in the app.');
    }

    public function destroy(string $sessionId): RedirectResponse
    {
        $this->supabase->updateByFilters(
            'quiet_time_sessions',
            ['id' => "eq.$sessionId"],
            [
                'status'     => 'archived',
                'is_active'  => false,
                'updated_at' => now()->toISOString(),
            ],
        );

        return redirect()->route('admin.qt-videos.index')
            ->with('status', 'Session archived and removed from the app.');
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private function generateSlug(string $title): string
    {
        $slug = strtolower(trim(
            (string) preg_replace('/[^A-Za-z0-9\-]/', '-', $title),
        ));
        $slug = (string) preg_replace('/-+/', '-', $slug);
        $slug = trim($slug, '-');

        return $slug . '-' . substr(md5(uniqid('', true)), 0, 6);
    }
}
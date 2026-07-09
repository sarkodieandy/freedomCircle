<?php

namespace App\Http\Controllers\Admin;

use App\Actions\RecordAuditAction;
use App\Models\AdminUser;
use App\Services\SupabaseAdminService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Arr;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class AdminModuleController extends Controller
{
    public function __construct(
        private readonly SupabaseAdminService $supabase,
        private readonly RecordAuditAction $audit
    ) {
    }

    public function index(string $module, Request $request): View
    {
        $definition = $this->resolveModule($module, $request);
        $table = (string) ($definition['table'] ?? '');
        $filters = $this->requestFilters($request);

        if ($module === 'quiet-time-videos') {
            $filters['session_type'] = 'eq.video';
        }

        $records = $table !== ''
            ? $this->supabase->listRows($table, $filters)
            : [];

        return view('admin.modules.index', [
            'moduleKey' => $module,
            'module' => $definition,
            'records' => $records,
            'filters' => $filters,
        ]);
    }

    public function show(string $module, string $id, Request $request): View
    {
        $definition = $this->resolveModule($module, $request);
        $table = (string) ($definition['table'] ?? '');

        $record = $this->supabase->firstBy($table, ['id' => "eq.$id"]);
        if (! is_array($record)) {
            abort(404, 'Record not found.');
        }

        return view('admin.modules.show', [
            'moduleKey' => $module,
            'module' => $definition,
            'record' => $record,
        ]);
    }

    public function edit(string $module, string $id, Request $request): View
    {
        $definition = $this->resolveModule($module, $request);
        $table = (string) ($definition['table'] ?? '');
        $record = $this->supabase->firstBy($table, ['id' => "eq.$id"]);
        if (! is_array($record)) {
            abort(404, 'Record not found.');
        }

        return view('admin.modules.edit', [
            'moduleKey' => $module,
            'module' => $definition,
            'record' => $record,
        ]);
    }

    public function store(string $module, Request $request): RedirectResponse
    {
        $definition = $this->resolveModule($module, $request);
        $table = (string) ($definition['table'] ?? '');
        if ($table === '') {
            throw ValidationException::withMessages(['module' => 'This module does not support create.']);
        }

        $payload = $this->safePayload($request);
        $this->supabase->insert($table, $payload);
        $this->recordAudit($request, 'create', $module, null, $payload);

        return redirect()->route('admin.module.index', ['module' => $module])
            ->with('status', 'Record created successfully.');
    }

    public function update(string $module, string $id, Request $request): RedirectResponse
    {
        $definition = $this->resolveModule($module, $request);
        $table = (string) ($definition['table'] ?? '');
        $payload = $this->safePayload($request);

        $this->supabase->updateByFilters($table, ['id' => "eq.$id"], $payload);
        $this->recordAudit($request, 'update', $module, $id, $payload);

        return redirect()->route('admin.module.show', ['module' => $module, 'id' => $id])
            ->with('status', 'Record updated successfully.');
    }

    public function destroy(string $module, string $id, Request $request): RedirectResponse
    {
        $definition = $this->resolveModule($module, $request);
        $table = (string) ($definition['table'] ?? '');

        $this->supabase->updateByFilters($table, ['id' => "eq.$id"], [
            'status' => 'archived',
            'updated_at' => now()->toISOString(),
        ]);

        $this->recordAudit($request, 'archive', $module, $id, []);

        return redirect()->route('admin.module.index', ['module' => $module])
            ->with('status', 'Record archived successfully.');
    }

    public function bulk(string $module, Request $request): JsonResponse
    {
        $this->resolveModule($module, $request);
        $payload = $request->validate([
            'action' => ['required', 'string', 'max:100'],
            'ids' => ['required', 'array', 'min:1'],
            'ids.*' => ['required', 'string'],
        ]);

        $admin = $this->adminFromRequest($request);
        $this->audit->execute(
            $admin,
            'bulk.' . (string) $payload['action'],
            $module,
            null,
            ['ids' => $payload['ids']]
        );

        return response()->json([
            'message' => 'Bulk action logged. Add worker/queue handlers for action execution.',
            'action' => $payload['action'],
            'count' => count($payload['ids']),
        ]);
    }

    private function resolveModule(string $module, Request $request): array
    {
        $definition = config('admin.modules.' . $module);
        if (! is_array($definition)) {
            abort(404, 'Unknown admin module.');
        }

        $permission = (string) ($definition['permission'] ?? '');
        if ($permission !== '') {
            $admin = $this->adminFromRequest($request);
            if (! $admin->hasPermission($permission)) {
                abort(403, 'You do not have permission to access this module.');
            }
        }

        return $definition;
    }

    private function requestFilters(Request $request): array
    {
        $filters = [
            'order' => (string) $request->query('order', 'updated_at.desc'),
            'limit' => min(max((int) $request->query('limit', 25), 1), 100),
        ];

        if ($request->filled('status')) {
            $filters['status'] = 'eq.' . $request->string('status');
        }

        if ($request->filled('search')) {
            $term = trim((string) $request->query('search'));
            $filters['or'] = "name.ilike.%$term%,title.ilike.%$term%,email.ilike.%$term%,username.ilike.%$term%";
        }

        return $filters;
    }

    private function safePayload(Request $request): array
    {
        $payload = Arr::except($request->all(), [
            '_token',
            '_method',
            'password',
            'access_token',
            'refresh_token',
            'service_role_key',
            'supabase_service_role_key',
            'revenuecat_secret',
            'paystack_secret_key',
        ]);

        return $payload;
    }

    private function recordAudit(
        Request $request,
        string $action,
        string $targetType,
        ?string $targetId,
        array $metadata
    ): void {
        $admin = $this->adminFromRequest($request);

        $this->audit->execute($admin, $action, $targetType, $targetId, $metadata);
    }

    private function adminFromRequest(Request $request): AdminUser
    {
        $admin = $request->attributes->get('admin_user');
        if (! $admin instanceof AdminUser) {
            abort(401, 'Admin user context missing.');
        }

        return $admin;
    }
}

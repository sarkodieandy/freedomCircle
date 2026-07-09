<?php

namespace App\Services;

use Illuminate\Auth\AuthenticationException;
use Illuminate\Http\UploadedFile;
use Illuminate\Validation\ValidationException;

class QuietTimeVideoService
{
    public function __construct(
        private readonly SupabaseAdminService $supabase,
        private readonly SupabaseStorageService $storage
    ) {
    }

    public function issueSignedVideoUrl(string $sessionId, string $accessToken, int $expiresIn = 900): array
    {
        $user = $this->storage->resolveUserFromAccessToken($accessToken);
        if (! is_array($user) || ! isset($user['id'])) {
            throw new AuthenticationException('Invalid or expired auth token.');
        }

        $session = $this->supabase->firstBy('quiet_time_sessions', [
            'id' => "eq.$sessionId",
        ]);

        if (! is_array($session)) {
            throw ValidationException::withMessages([
                'session_id' => 'Quiet Time session not found.',
            ]);
        }

        if (($session['is_active'] ?? false) !== true || ($session['status'] ?? 'draft') !== 'published') {
            throw ValidationException::withMessages([
                'session_id' => 'Quiet Time session is not published.',
            ]);
        }

        if (($session['session_type'] ?? 'audio') !== 'video') {
            throw ValidationException::withMessages([
                'session_id' => 'This Quiet Time session is not a video session.',
            ]);
        }

        $path = trim((string) ($session['video_storage_path'] ?? ''));
        if ($path === '') {
            throw ValidationException::withMessages([
                'session_id' => 'Video file is not configured for this session.',
            ]);
        }

        $isPremium = (bool) ($session['is_premium'] ?? false);
        if ($isPremium) {
            $userId = (string) $user['id'];
            $hasVideoPremium = $this->supabase->verifyEntitlement($userId, 'quiet_time_premium_video_library');
            $hasLegacyPremium = $this->supabase->verifyEntitlement($userId, 'quiet_time_premium_library');

            if (! $hasVideoPremium && ! $hasLegacyPremium) {
                throw ValidationException::withMessages([
                    'entitlement' => 'Premium Quiet Time video access is required.',
                ]);
            }
        }

        $signed = $this->storage->createSignedUrl('quiet-time-videos', $path, $expiresIn);

        return [
            'session_id' => $sessionId,
            'signed_url' => $signed['signed_url'],
            'expires_in' => $signed['expires_in'],
        ];
    }

    public function uploadVideoForSession(string $sessionId, UploadedFile $video, string $status = 'draft'): array
    {
        $session = $this->supabase->firstBy('quiet_time_sessions', [
            'id' => "eq.$sessionId",
        ]);
        if (! is_array($session)) {
            throw ValidationException::withMessages([
                'session_id' => 'Quiet Time session not found.',
            ]);
        }

        $safeName = preg_replace('/[^A-Za-z0-9_\-.]/', '-', $video->getClientOriginalName() ?: 'video.mp4') ?: 'video.mp4';
        $path = 'sessions/' . $sessionId . '/' . now()->format('YmdHis') . '-' . $safeName;

        $this->storage->uploadObject('quiet-time-videos', $path, $video);

        $normalizedStatus = in_array($status, ['draft', 'published', 'hidden', 'archived'], true)
            ? $status
            : 'draft';

        $this->supabase->updateByFilters('quiet_time_sessions', ['id' => "eq.$sessionId"], [
            'session_type' => 'video',
            'video_storage_path' => $path,
            'video_provider' => 'supabase',
            'status' => $normalizedStatus,
            'updated_at' => now()->toISOString(),
        ]);

        $updated = $this->supabase->firstBy('quiet_time_sessions', [
            'id' => "eq.$sessionId",
        ]);

        return is_array($updated) ? $updated : [];
    }
}
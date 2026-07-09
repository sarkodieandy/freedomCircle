<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;

class SupabaseStorageService
{
    public function uploadObject(string $bucket, string $path, UploadedFile $file): array
    {
        return Http::withHeaders([
            'apikey' => $this->serviceRoleKey(),
            'Authorization' => 'Bearer ' . $this->serviceRoleKey(),
            'Content-Type' => $file->getMimeType() ?: 'application/octet-stream',
            'x-upsert' => 'true',
        ])->withBody(
            file_get_contents($file->getRealPath()) ?: '',
            $file->getMimeType() ?: 'application/octet-stream'
        )->post($this->baseUrl() . '/storage/v1/object/' . rawurlencode($bucket) . '/' . ltrim($path, '/'))
            ->throw()
            ->json();
    }

    public function createSignedUrl(string $bucket, string $path, int $seconds = 600): array
    {
        $payload = Http::withHeaders([
            'apikey' => $this->serviceRoleKey(),
            'Authorization' => 'Bearer ' . $this->serviceRoleKey(),
            'Content-Type' => 'application/json',
        ])->post($this->baseUrl() . '/storage/v1/object/sign/' . rawurlencode($bucket) . '/' . ltrim($path, '/'), [
            'expiresIn' => $seconds,
        ])->throw()->json();

        $signedPath = (string) ($payload['signedURL'] ?? $payload['signedUrl'] ?? '');
        $signedUrl = $signedPath;
        if ($signedPath !== '' && ! str_starts_with($signedPath, 'http')) {
            $signedUrl = rtrim($this->baseUrl(), '/') . '/storage/v1/' . ltrim($signedPath, '/');
        }

        return [
            'signed_url' => $signedUrl,
            'expires_in' => $seconds,
            'raw' => $payload,
        ];
    }

    public function resolveUserFromAccessToken(string $accessToken): ?array
    {
        if ($accessToken === '') {
            return null;
        }

        $response = Http::withHeaders([
            'apikey' => $this->anonKey(),
            'Authorization' => 'Bearer ' . $accessToken,
        ])->get($this->baseUrl() . '/auth/v1/user');

        if ($response->failed()) {
            return null;
        }

        $payload = $response->json();
        return is_array($payload) ? $payload : null;
    }

    private function baseUrl(): string
    {
        return rtrim((string) config('services.supabase.url'), '/');
    }

    private function serviceRoleKey(): string
    {
        return (string) config('services.supabase.service_role_key');
    }

    private function anonKey(): string
    {
        return (string) config('services.supabase.anon_key');
    }
}
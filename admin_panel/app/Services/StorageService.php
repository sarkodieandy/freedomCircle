<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class StorageService
{
    public function __construct(private readonly SupabaseAdminService $supabase)
    {
    }

    public function listAssets(array $filters = []): array
    {
        return $this->supabase->listRows('storage_assets', array_merge([
            'order' => 'created_at.desc',
        ], $filters));
    }

    public function deleteUnsafeFile(string $bucket, string $path): array
    {
        return Http::withHeaders([
            'apikey' => $this->serviceRoleKey(),
            'Authorization' => 'Bearer ' . $this->serviceRoleKey(),
            'Content-Type' => 'application/json',
        ])->delete($this->baseUrl() . '/storage/v1/object/' . rawurlencode($bucket) . '/' . ltrim($path, '/'))
            ->throw()
            ->json();
    }

    public function createSignedUrl(string $bucket, string $path, int $seconds = 600): array
    {
        return Http::withHeaders([
            'apikey' => $this->serviceRoleKey(),
            'Authorization' => 'Bearer ' . $this->serviceRoleKey(),
            'Content-Type' => 'application/json',
        ])->post($this->baseUrl() . '/storage/v1/object/sign/' . rawurlencode($bucket) . '/' . ltrim($path, '/'), [
            'expiresIn' => $seconds,
        ])->throw()->json();
    }

    private function baseUrl(): string
    {
        return rtrim((string) config('services.supabase.url'), '/');
    }

    private function serviceRoleKey(): string
    {
        return (string) config('services.supabase.service_role_key');
    }
}

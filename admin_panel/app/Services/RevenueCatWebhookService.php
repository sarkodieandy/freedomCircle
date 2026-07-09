<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use RuntimeException;

class RevenueCatWebhookService
{
    public function __construct(private readonly SupabaseAdminService $supabase)
    {
    }

    public function verifySecret(?string $headerSecret): bool
    {
        $secret = (string) config('services.revenuecat.webhook_secret');
        if ($secret === '' || ! is_string($headerSecret)) {
            return false;
        }

        return hash_equals($secret, $headerSecret);
    }

    public function process(array $payload): void
    {
        $eventId = (string) ($payload['event']['id'] ?? $payload['id'] ?? '');
        if ($eventId === '') {
            throw new RuntimeException('RevenueCat event id missing.');
        }

        if ($this->isDuplicate($eventId)) {
            return;
        }

        $event = $payload['event'] ?? $payload;
        $appUserId = (string) ($event['app_user_id'] ?? '');
        $type = (string) ($event['type'] ?? 'unknown');

        $this->storeWebhookEvent($eventId, $type, $payload);

        if ($appUserId === '') {
            return;
        }

        $isPremium = in_array($type, ['INITIAL_PURCHASE', 'RENEWAL', 'UNCANCELLATION'], true);

        $this->supabase->upsertByFilters('revenuecat_customers', ['user_id' => "eq.$appUserId"], [
            'user_id' => $appUserId,
            'revenuecat_app_user_id' => $appUserId,
            'latest_customer_info' => $payload,
            'is_premium' => $isPremium,
            'last_synced_at' => now()->toISOString(),
            'updated_at' => now()->toISOString(),
        ]);
    }

    private function isDuplicate(string $eventId): bool
    {
        return DB::table('webhook_events')
            ->where('provider', 'revenuecat')
            ->where('provider_event_id', $eventId)
            ->exists();
    }

    private function storeWebhookEvent(string $eventId, string $type, array $payload): void
    {
        DB::table('webhook_events')->insert([
            'provider' => 'revenuecat',
            'provider_event_id' => $eventId,
            'event_type' => $type,
            'payload' => json_encode($payload, JSON_THROW_ON_ERROR),
            'processed_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}

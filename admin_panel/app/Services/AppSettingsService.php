<?php

namespace App\Services;

use App\Actions\RecordAuditAction;
use App\Models\AdminUser;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Cache;
use InvalidArgumentException;

class AppSettingsService
{
    public function __construct(
        private readonly SupabaseAdminService $supabase,
        private readonly RecordAuditAction $audit
    ) {
    }

    public function get(string $key, mixed $default = null): mixed
    {
        $row = $this->supabase->firstBy('app_settings', ['key' => "eq.$key"]);
        if (! is_array($row)) {
            return $default;
        }

        return $row['value'] ?? $default;
    }

    public function set(string $key, mixed $value, AdminUser $updatedBy): array
    {
        $existing = $this->supabase->firstBy('app_settings', ['key' => "eq.$key"]);
        $type = (string) ($existing['type'] ?? get_debug_type($value));

        $this->validateSetting($key, $value, $type);

        $payload = [
            'value' => $value,
            'updated_by' => $updatedBy->id,
            'updated_at' => now()->toISOString(),
        ];

        $updated = is_array($existing)
            ? $this->supabase->updateByFilters('app_settings', ['key' => "eq.$key"], $payload)
            : $this->supabase->insert('app_settings', array_merge([
                'key' => $key,
                'group' => $this->resolveGroupFromKey($key),
                'type' => $type,
                'description' => ucfirst(str_replace('_', ' ', $key)),
                'is_public' => $this->isPublicKey($key),
            ], $payload));

        $this->recordAuditLog($updatedBy, 'app_settings.updated', 'app_settings', $key, [
            'new_value' => $value,
        ]);

        Cache::forget('app_public_settings');

        return $updated;
    }

    public function getGroup(string $group): array
    {
        return $this->supabase->listRows('app_settings', [
            'group' => "eq.$group",
            'order' => 'key.asc',
        ]);
    }

    public function updateGroup(string $group, array $settings, AdminUser $updatedBy): array
    {
        $updated = [];
        foreach ($settings as $key => $value) {
            $updated[] = $this->set((string) $key, $value, $updatedBy);
        }

        return $updated;
    }

    public function resetToDefault(string $key, AdminUser $updatedBy): ?array
    {
        $default = $this->defaultSettings()[$key] ?? null;
        if ($default === null) {
            return null;
        }

        return $this->set($key, $default, $updatedBy);
    }

    public function validateSetting(string $key, mixed $value, ?string $type = null): void
    {
        $type = $type ?? get_debug_type($value);

        if ($type === 'bool' || $type === 'boolean') {
            if (! is_bool($value)) {
                throw new InvalidArgumentException("Setting [$key] requires boolean value.");
            }
            return;
        }

        if (str_contains($key, 'limit') || str_contains($key, 'count') || str_contains($key, 'percent')) {
            if (! is_int($value) && ! is_float($value)) {
                throw new InvalidArgumentException("Setting [$key] requires numeric value.");
            }
        }
    }

    public function recordAuditLog(
        AdminUser $updatedBy,
        string $action,
        string $targetType,
        ?string $targetId,
        array $metadata = []
    ): void {
        $this->audit->execute($updatedBy, $action, $targetType, $targetId, $metadata);
    }

    public function publicSettings(): array
    {
        return Cache::remember('app_public_settings', now()->addMinutes(5), function (): array {
            $rows = $this->supabase->listRows('app_settings', [
                'is_public' => 'eq.true',
                'order' => 'key.asc',
            ]);

            $mapped = [];
            foreach ($rows as $row) {
                $key = (string) ($row['key'] ?? '');
                if ($key === '') {
                    continue;
                }
                $mapped[$key] = Arr::get($row, 'value');
            }

            return $mapped;
        });
    }

    private function resolveGroupFromKey(string $key): string
    {
        foreach (config('admin.settings_groups', []) as $group) {
            if (str_starts_with($key, $group . '_')) {
                return (string) $group;
            }
        }

        return 'general';
    }

    private function isPublicKey(string $key): bool
    {
        $privateNeedles = [
            'secret',
            'service_role',
            'commission',
            'fee',
            'moderation_threshold',
        ];

        foreach ($privateNeedles as $needle) {
            if (str_contains($key, $needle)) {
                return false;
            }
        }

        return true;
    }

    private function defaultSettings(): array
    {
        return [
            'app_name' => 'FreedomCircle',
            'maintenance_mode' => false,
            'minimum_supported_app_version' => '1.0.0',
            'groups_enabled' => true,
            'chat_enabled' => true,
            'premium_paywall_enabled' => true,
            'paywall_enabled' => true,
            'soft_upgrade_cards_enabled' => true,
            'milestone_upgrade_prompt_enabled' => true,
            'free_group_join_limit' => 2,
            'free_recovery_goal_limit' => 1,
            'free_journal_entry_limit' => 5,
            'free_quiet_time_session_limit' => 4,
            'free_advanced_insights' => false,
            'free_premium_groups' => false,
            'free_helper_matching' => false,
            'free_guided_programs' => false,
            'premium_weekly_price' => ['amount' => 3, 'currency' => 'USD'],
            'premium_monthly_price' => ['amount' => 10, 'currency' => 'USD'],
            'premium_yearly_price' => ['amount' => 30, 'currency' => 'USD'],
            'premium_currency' => 'USD',
            'recommended_plan' => 'premium_yearly',
            'yearly_best_value_enabled' => true,
            'max_voice_note_seconds' => 180,
            'typing_indicator_enabled' => true,
            'read_receipts_enabled' => true,
            'chat_reactions_enabled' => true,
            'push_notifications_enabled' => true,
            'quiet_time_premium_enabled' => true,
            'default_goal_duration_days' => 30,
        ];
    }
}

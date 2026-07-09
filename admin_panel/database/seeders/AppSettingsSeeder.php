<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AppSettingsSeeder extends Seeder
{
    public function run(): void
    {
        $defaults = [
            ['key' => 'app_name', 'value' => 'FreedomCircle', 'group' => 'general', 'type' => 'string', 'is_public' => true],
            ['key' => 'maintenance_mode', 'value' => false, 'group' => 'general', 'type' => 'boolean', 'is_public' => true],
            ['key' => 'minimum_supported_app_version', 'value' => '1.0.0', 'group' => 'general', 'type' => 'string', 'is_public' => true],
            ['key' => 'groups_enabled', 'value' => true, 'group' => 'feature_toggles', 'type' => 'boolean', 'is_public' => true],
            ['key' => 'chat_enabled', 'value' => true, 'group' => 'feature_toggles', 'type' => 'boolean', 'is_public' => true],
            ['key' => 'premium_paywall_enabled', 'value' => true, 'group' => 'feature_toggles', 'type' => 'boolean', 'is_public' => true],
            ['key' => 'paywall_enabled', 'value' => true, 'group' => 'feature_toggles', 'type' => 'boolean', 'is_public' => true],
            ['key' => 'soft_upgrade_cards_enabled', 'value' => true, 'group' => 'feature_toggles', 'type' => 'boolean', 'is_public' => true],
            ['key' => 'milestone_upgrade_prompt_enabled', 'value' => true, 'group' => 'feature_toggles', 'type' => 'boolean', 'is_public' => true],
            ['key' => 'free_group_join_limit', 'value' => 2, 'group' => 'free_plan_limits', 'type' => 'integer', 'is_public' => true],
            ['key' => 'free_recovery_goal_limit', 'value' => 1, 'group' => 'free_plan_limits', 'type' => 'integer', 'is_public' => true],
            ['key' => 'free_journal_entry_limit', 'value' => 5, 'group' => 'free_plan_limits', 'type' => 'integer', 'is_public' => true],
            ['key' => 'free_quiet_time_session_limit', 'value' => 4, 'group' => 'free_plan_limits', 'type' => 'integer', 'is_public' => true],
            ['key' => 'free_advanced_insights', 'value' => false, 'group' => 'free_plan_limits', 'type' => 'boolean', 'is_public' => true],
            ['key' => 'free_premium_groups', 'value' => false, 'group' => 'free_plan_limits', 'type' => 'boolean', 'is_public' => true],
            ['key' => 'free_helper_matching', 'value' => false, 'group' => 'free_plan_limits', 'type' => 'boolean', 'is_public' => true],
            ['key' => 'free_guided_programs', 'value' => false, 'group' => 'free_plan_limits', 'type' => 'boolean', 'is_public' => true],
            ['key' => 'premium_weekly_price', 'value' => ['amount' => 3, 'currency' => 'USD'], 'group' => 'monetization', 'type' => 'json', 'is_public' => true],
            ['key' => 'premium_monthly_price', 'value' => ['amount' => 10, 'currency' => 'USD'], 'group' => 'monetization', 'type' => 'json', 'is_public' => true],
            ['key' => 'premium_yearly_price', 'value' => ['amount' => 30, 'currency' => 'USD'], 'group' => 'monetization', 'type' => 'json', 'is_public' => true],
            ['key' => 'premium_currency', 'value' => 'USD', 'group' => 'monetization', 'type' => 'string', 'is_public' => true],
            ['key' => 'recommended_plan', 'value' => 'premium_yearly', 'group' => 'monetization', 'type' => 'string', 'is_public' => true],
            ['key' => 'yearly_best_value_enabled', 'value' => true, 'group' => 'monetization', 'type' => 'boolean', 'is_public' => true],
            ['key' => 'max_voice_note_seconds', 'value' => 180, 'group' => 'chat', 'type' => 'integer', 'is_public' => true],
            ['key' => 'typing_indicator_enabled', 'value' => true, 'group' => 'chat', 'type' => 'boolean', 'is_public' => true],
            ['key' => 'read_receipts_enabled', 'value' => true, 'group' => 'chat', 'type' => 'boolean', 'is_public' => true],
            ['key' => 'chat_reactions_enabled', 'value' => true, 'group' => 'chat', 'type' => 'boolean', 'is_public' => true],
            ['key' => 'push_notifications_enabled', 'value' => true, 'group' => 'notifications', 'type' => 'boolean', 'is_public' => true],
            ['key' => 'quiet_time_premium_enabled', 'value' => true, 'group' => 'quiet_time', 'type' => 'boolean', 'is_public' => true],
            ['key' => 'default_goal_duration_days', 'value' => 30, 'group' => 'recovery', 'type' => 'integer', 'is_public' => true],
        ];

        foreach ($defaults as $row) {
            $exists = DB::table('app_settings')->where('key', $row['key'])->exists();
            if ($exists) {
                continue;
            }

            DB::table('app_settings')->insert([
                'id' => (string) Str::uuid(),
                'key' => $row['key'],
                'value' => json_encode($row['value'], JSON_THROW_ON_ERROR),
                'group' => $row['group'],
                'type' => $row['type'],
                'description' => ucfirst(str_replace('_', ' ', $row['key'])),
                'is_public' => $row['is_public'],
                'updated_by' => null,
                'created_at' => \now(),
                'updated_at' => \now(),
            ]);
        }
    }
}

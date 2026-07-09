<?php

namespace App\Services;

class AnalyticsService
{
    public function __construct(private readonly SupabaseAdminService $supabase)
    {
    }

    public function getDashboardMetrics(): array
    {
        return [
            'revenue' => $this->supabase->viewRows('admin_revenue_summary', limit: 1)[0] ?? [],
            'mrr' => $this->supabase->viewRows('admin_mrr_summary', limit: 1)[0] ?? [],
            'paywall_conversion' => $this->getPaywallConversion(),
            'user_growth_total' => $this->supabase->countTable('profiles'),
            'active_groups' => $this->supabase->countTable('groups', ['status' => 'eq.active']),
            'pending_reports' => $this->supabase->countTable('reports', ['status' => 'eq.pending']),
            'pending_helper_approvals' => $this->supabase->countTable('helpers', ['verification_status' => 'eq.pending']),
            'active_subscriptions' => $this->supabase->countTable('subscriptions', ['status' => 'eq.active']),
            'failed_payments' => $this->supabase->countTable('payments', ['status' => 'eq.failed']),
            'open_support_requests' => $this->supabase->countTable('support_requests', ['status' => 'eq.open']),
        ];
    }

    public function getUserGrowth(): array
    {
        return $this->supabase->viewRows('user_growth_summary');
    }

    public function getRevenueSummary(): array
    {
        return [
            'daily' => $this->supabase->viewRows('admin_daily_revenue', limit: 90),
            'summary' => $this->supabase->viewRows('admin_revenue_summary', limit: 1)[0] ?? [],
        ];
    }

    public function getSubscriptionBreakdown(): array
    {
        return $this->supabase->viewRows('admin_subscription_breakdown');
    }

    public function getGroupActivity(): array
    {
        return $this->supabase->viewRows('group_activity_summary');
    }

    public function getCommunityActivity(): array
    {
        return $this->supabase->viewRows('community_activity_summary');
    }

    public function getPrayerActivity(): array
    {
        return $this->supabase->viewRows('prayer_activity_summary');
    }

    public function getCoachRevenue(): array
    {
        return $this->supabase->viewRows('admin_coach_commission_summary');
    }

    public function getChurchRevenue(): array
    {
        return $this->supabase->viewRows('church_revenue_summary');
    }

    public function getPaywallConversion(): array
    {
        return $this->supabase->viewRows('admin_paywall_conversion');
    }

    public function getQuietTimeUsage(): array
    {
        return $this->supabase->viewRows('quiet_time_usage_summary');
    }
}

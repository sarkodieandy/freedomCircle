<?php

namespace App\Http\Controllers\Admin;

use App\Services\AnalyticsService;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function __construct(private readonly AnalyticsService $analytics)
    {
    }

    public function index(Request $request): View
    {
        $admin = $request->attributes->get('admin_user');

        return view('admin.dashboard', [
            'admin' => $admin,
            'metrics' => $this->analytics->getDashboardMetrics(),
            'userGrowth' => $this->analytics->getUserGrowth(),
            'revenueSummary' => $this->analytics->getRevenueSummary(),
            'subscriptionBreakdown' => $this->analytics->getSubscriptionBreakdown(),
            'groupActivity' => $this->analytics->getGroupActivity(),
            'communityActivity' => $this->analytics->getCommunityActivity(),
            'prayerActivity' => $this->analytics->getPrayerActivity(),
            'coachRevenue' => $this->analytics->getCoachRevenue(),
            'churchRevenue' => $this->analytics->getChurchRevenue(),
            'paywallConversion' => $this->analytics->getPaywallConversion(),
            'quietTimeUsage' => $this->analytics->getQuietTimeUsage(),
        ]);
    }
}

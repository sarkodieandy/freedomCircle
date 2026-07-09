@extends('layouts.admin', ['title' => 'Dashboard'])

@section('content')
<div class="page-head">
    <div>
        <h2>Operations Dashboard</h2>
        <p>Real-time SaaS operations for FreedomCircle across users, monetization, moderation, and content.</p>
    </div>
    <span class="badge premium">Premium Analytics</span>
</div>

<div class="cards-grid">
    <div class="card"><div class="metric-label">Total Users</div><div class="metric-value">{{ $metrics['user_growth_total'] ?? 0 }}</div></div>
    <div class="card"><div class="metric-label">Active Groups</div><div class="metric-value">{{ $metrics['active_groups'] ?? 0 }}</div></div>
    <div class="card"><div class="metric-label">Pending Reports</div><div class="metric-value">{{ $metrics['pending_reports'] ?? 0 }}</div></div>
    <div class="card"><div class="metric-label">Pending Helper Approvals</div><div class="metric-value">{{ $metrics['pending_helper_approvals'] ?? 0 }}</div></div>
    <div class="card"><div class="metric-label">Active Subscriptions</div><div class="metric-value">{{ $metrics['active_subscriptions'] ?? 0 }}</div></div>
    <div class="card"><div class="metric-label">Failed Payments</div><div class="metric-value">{{ $metrics['failed_payments'] ?? 0 }}</div></div>
    <div class="card"><div class="metric-label">Open Support Requests</div><div class="metric-value">{{ $metrics['open_support_requests'] ?? 0 }}</div></div>
    <div class="card"><div class="metric-label">MRR</div><div class="metric-value">{{ $metrics['mrr']['mrr_total'] ?? 0 }}</div></div>
</div>

<div class="card" style="margin-top:14px">
    <h3 style="margin-top:0">Chart Data (Ready For Chart.js Integration)</h3>
    <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th>Dataset</th>
                    <th>Records</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                <tr><td>User Growth</td><td>{{ count($userGrowth) }}</td><td><span class="badge success">Loaded</span></td></tr>
                <tr><td>Revenue Trend</td><td>{{ count($revenueSummary['daily'] ?? []) }}</td><td><span class="badge success">Loaded</span></td></tr>
                <tr><td>Subscription Breakdown</td><td>{{ count($subscriptionBreakdown) }}</td><td><span class="badge success">Loaded</span></td></tr>
                <tr><td>Group Activity</td><td>{{ count($groupActivity) }}</td><td><span class="badge success">Loaded</span></td></tr>
                <tr><td>Community Activity</td><td>{{ count($communityActivity) }}</td><td><span class="badge success">Loaded</span></td></tr>
                <tr><td>Prayer Activity</td><td>{{ count($prayerActivity) }}</td><td><span class="badge success">Loaded</span></td></tr>
                <tr><td>Coach Revenue</td><td>{{ count($coachRevenue) }}</td><td><span class="badge success">Loaded</span></td></tr>
                <tr><td>Church Revenue</td><td>{{ count($churchRevenue) }}</td><td><span class="badge success">Loaded</span></td></tr>
                <tr><td>Paywall Conversion</td><td>{{ count($paywallConversion) }}</td><td><span class="badge success">Loaded</span></td></tr>
                <tr><td>Quiet Time Usage</td><td>{{ count($quietTimeUsage) }}</td><td><span class="badge success">Loaded</span></td></tr>
            </tbody>
        </table>
    </div>
</div>
@endsection

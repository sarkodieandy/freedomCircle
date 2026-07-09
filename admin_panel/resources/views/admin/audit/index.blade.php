@extends('layouts.admin', ['title' => 'Audit Logs'])

@section('content')
<div class="page-head">
    <div>
        <h2>Audit Logs</h2>
        <p>Track sensitive admin actions: role changes, suspensions, moderation actions, settings updates, payout changes.</p>
    </div>
</div>

<form class="toolbar inline" method="get">
    <input name="action" placeholder="Action" value="{{ request('action') }}">
    <input name="admin_user_id" placeholder="Admin ID" value="{{ request('admin_user_id') }}">
    <input name="target_type" placeholder="Target Type" value="{{ request('target_type') }}">
    <button class="btn-primary">Filter</button>
</form>

<div class="card">
    <div class="table-wrap">
        <table>
            <thead>
            <tr>
                <th>When</th>
                <th>Admin</th>
                <th>Action</th>
                <th>Target</th>
                <th>Metadata</th>
            </tr>
            </thead>
            <tbody>
            @forelse($logs as $log)
                <tr>
                    <td>{{ $log->created_at }}</td>
                    <td>{{ $log->admin_user_id }}</td>
                    <td>{{ $log->action }}</td>
                    <td>{{ $log->target_type }} / {{ $log->target_id }}</td>
                    <td><pre style="white-space:pre-wrap">{{ $log->metadata }}</pre></td>
                </tr>
            @empty
                <tr><td colspan="5">No audit logs found.</td></tr>
            @endforelse
            </tbody>
        </table>
    </div>
</div>

{{ $logs->links() }}
@endsection

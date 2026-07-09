@extends('layouts.admin', ['title' => $module['label']])

@section('content')
<div class="page-head">
    <div>
        <h2>{{ $module['label'] }}</h2>
        <p>Operational control for {{ strtolower($module['label']) }}.</p>
    </div>
    <a href="{{ route('admin.module.index', ['module' => $moduleKey]) }}" class="btn-outline">Refresh</a>
</div>

<form method="get" class="toolbar inline">
    <input type="search" name="search" placeholder="Search..." value="{{ request('search', '') }}">
    <select name="status">
        <option value="">All statuses</option>
        <option value="active" @selected(request('status')==='active')>Active</option>
        <option value="pending" @selected(request('status')==='pending')>Pending</option>
        <option value="hidden" @selected(request('status')==='hidden')>Hidden</option>
        <option value="archived" @selected(request('status')==='archived')>Archived</option>
    </select>
    <button class="btn-primary" type="submit">Apply Filters</button>
</form>

<div class="card">
    <div class="table-wrap">
        <table>
            <thead>
            <tr>
                <th>ID</th>
                <th>Summary</th>
                <th>Status</th>
                <th>Updated</th>
                <th>Actions</th>
            </tr>
            </thead>
            <tbody>
            @forelse($records as $row)
                @php
                    $id = (string)($row['id'] ?? 'n/a');
                    $summary = $row['name'] ?? $row['title'] ?? $row['email'] ?? $row['slug'] ?? $id;
                    $status = strtolower((string)($row['status'] ?? 'active'));
                @endphp
                <tr>
                    <td>{{ $id }}</td>
                    <td>{{ $summary }}</td>
                    <td>
                        <span class="badge {{ in_array($status, ['active', 'approved']) ? 'success' : ($status === 'failed' ? 'error' : 'warning') }}">
                            {{ $row['status'] ?? 'active' }}
                        </span>
                    </td>
                    <td>{{ $row['updated_at'] ?? $row['created_at'] ?? '-' }}</td>
                    <td>
                        <a class="btn-outline" href="{{ route('admin.module.show', ['module' => $moduleKey, 'id' => $id]) }}">View</a>
                        <a class="btn-outline" href="{{ route('admin.module.edit', ['module' => $moduleKey, 'id' => $id]) }}">Edit</a>
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="5">No records found for this module.</td>
                </tr>
            @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection

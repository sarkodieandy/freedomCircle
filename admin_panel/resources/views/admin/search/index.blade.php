@extends('layouts.admin', ['title' => 'Search'])

@section('content')
<div class="page-head">
    <div>
        <h2>Global Admin Search</h2>
        <p>Search users, groups, organizations, helpers, posts, payments, subscriptions, reports, and programs.</p>
    </div>
</div>

@if($query === '')
    <div class="card">Enter a term in the top search box.</div>
@else
    @foreach($results as $section => $items)
        <div class="card" style="margin-bottom:12px">
            <h3 style="margin-top:0">{{ ucwords(str_replace('_', ' ', $section)) }} ({{ count($items) }})</h3>
            <div class="table-wrap">
                <table>
                    <thead>
                    <tr>
                        <th>ID</th>
                        <th>Primary</th>
                        <th>Status</th>
                    </tr>
                    </thead>
                    <tbody>
                    @forelse($items as $item)
                        <tr>
                            <td>{{ $item['id'] ?? '-' }}</td>
                            <td>{{ $item['name'] ?? $item['title'] ?? $item['email'] ?? $item['slug'] ?? '-' }}</td>
                            <td>{{ $item['status'] ?? '-' }}</td>
                        </tr>
                    @empty
                        <tr><td colspan="3">No matches</td></tr>
                    @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    @endforeach
@endif
@endsection

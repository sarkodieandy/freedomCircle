@extends('layouts.admin', ['title' => 'Quiet Time Videos'])

@section('content')
<div class="page-head">
    <div>
        <h2>Quiet Time Videos</h2>
        <p>Upload and manage meditation, prayer, and reflection video sessions.</p>
    </div>
    <a href="{{ route('admin.qt-videos.create') }}" class="btn-primary">+ New Video Session</a>
</div>

<form method="get" class="toolbar inline">
    <input type="search" name="search" placeholder="Search title or description..." value="{{ request('search', '') }}">
    <select name="status">
        <option value="">All statuses</option>
        <option value="draft"      @selected(request('status') === 'draft')>Draft</option>
        <option value="published"  @selected(request('status') === 'published')>Published</option>
        <option value="hidden"     @selected(request('status') === 'hidden')>Hidden</option>
        <option value="archived"   @selected(request('status') === 'archived')>Archived</option>
    </select>
    <button class="btn-primary" type="submit">Filter</button>
    @if(request()->hasAny(['search','status']))
        <a href="{{ route('admin.qt-videos.index') }}" class="btn-outline">Clear</a>
    @endif
</form>

<div class="card">
    <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th>Title</th>
                    <th>Category</th>
                    <th>Status</th>
                    <th>Video</th>
                    <th>Premium</th>
                    <th>Duration</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
            @forelse($sessions as $row)
                @php
                    $status      = (string) ($row['status'] ?? 'draft');
                    $hasVideo    = ! empty($row['video_storage_path']);
                    $categoryName = $row['quiet_time_categories']['name'] ?? '—';
                    $badgeClass  = match($status) {
                        'published' => 'success',
                        'draft'     => 'warning',
                        default     => 'error',
                    };
                @endphp
                <tr>
                    <td><strong>{{ $row['title'] }}</strong></td>
                    <td>{{ $categoryName }}</td>
                    <td>
                        <span class="badge {{ $badgeClass }}">{{ ucfirst($status) }}</span>
                    </td>
                    <td>
                        @if($hasVideo)
                            <span class="badge success">✓ Uploaded</span>
                        @else
                            <span class="badge warning">No video</span>
                        @endif
                    </td>
                    <td>{{ ($row['is_premium'] ?? false) ? '⭐ Premium' : 'Free' }}</td>
                    <td>{{ $row['duration_minutes'] ?? '—' }} min</td>
                    <td style="white-space:nowrap">
                        <a class="btn-outline" href="{{ route('admin.qt-videos.edit', $row['id']) }}">Edit</a>
                        @if($status !== 'published')
                            <form method="post" action="{{ route('admin.qt-videos.publish', $row['id']) }}" style="display:inline">
                                @csrf
                                <button class="btn-primary" type="submit">Publish</button>
                            </form>
                        @endif
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="7">
                        No video sessions found.
                        <a href="{{ route('admin.qt-videos.create') }}">Create your first one →</a>
                    </td>
                </tr>
            @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection

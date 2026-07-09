@extends('layouts.admin', ['title' => $module['label'].' Detail'])

@section('content')
<div class="page-head">
    <div>
        <h2>{{ $module['label'] }} Detail</h2>
        <p>Detailed operational and moderation view.</p>
    </div>
    <a href="{{ route('admin.module.edit', ['module' => $moduleKey, 'id' => $record['id']]) }}" class="btn-primary">Edit Record</a>
</div>

<div class="card">
    <div class="status-row">
        <span><strong>ID:</strong> {{ $record['id'] ?? '-' }}</span>
        <span><strong>Status:</strong> {{ $record['status'] ?? 'active' }}</span>
        <span><strong>Updated:</strong> {{ $record['updated_at'] ?? '-' }}</span>
    </div>
</div>

<div class="card" style="margin-top:12px">
    <h3 style="margin-top:0">Raw Metadata (Safe Operational View)</h3>
    <pre style="white-space:pre-wrap">{{ json_encode($record, JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES) }}</pre>
</div>

@if($moduleKey === 'quiet-time-videos')
    <form class="card" style="margin-top:12px" method="post" enctype="multipart/form-data" action="{{ route('admin.quiet-time-videos.upload', ['sessionId' => $record['id']]) }}">
        @csrf
        <h3 style="margin-top:0">Upload Quiet Time Video</h3>
        <p>Upload MP4/MOV/WebM and attach it to this session. The app will fetch a signed playback URL at runtime.</p>

        <label style="display:block;margin-top:10px">Video File</label>
        <input type="file" name="video" accept="video/mp4,video/quicktime,video/x-m4v,video/webm" required>

        <label style="display:block;margin-top:10px">Publish State</label>
        <select name="status">
            <option value="draft">Draft</option>
            <option value="published">Published</option>
            <option value="hidden">Hidden</option>
            <option value="archived">Archived</option>
        </select>

        <button class="btn-primary" style="margin-top:12px" type="submit">Upload Video</button>
    </form>
@endif

<form method="post" action="{{ route('admin.module.destroy', ['module' => $moduleKey, 'id' => $record['id']]) }}" style="margin-top:12px">
    @csrf
    @method('delete')
    <button class="btn-outline" data-confirm="Archive this record?" type="submit">Archive</button>
</form>
@endsection

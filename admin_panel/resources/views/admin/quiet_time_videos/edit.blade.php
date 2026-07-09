@extends('layouts.admin', ['title' => 'Edit: '.($session['title'] ?? 'Session')])

@section('content')
@php
    $status   = (string) ($session['status'] ?? 'draft');
    $hasVideo = ! empty($session['video_storage_path']);
@endphp

<div class="page-head">
    <div>
        <h2>{{ $session['title'] }}</h2>
        <p>
            <span class="badge {{ $status === 'published' ? 'success' : ($status === 'draft' ? 'warning' : 'error') }}">
                {{ ucfirst($status) }}
            </span>
            &nbsp;
            <span class="badge {{ $hasVideo ? 'success' : 'warning' }}">
                {{ $hasVideo ? '✓ Video uploaded' : 'No video yet' }}
            </span>
        </p>
    </div>
    <div style="display:flex;gap:8px;align-items:center">
        <a href="{{ route('admin.qt-videos.index') }}" class="btn-outline">← All Videos</a>
        @if($status !== 'published')
            <form method="post" action="{{ route('admin.qt-videos.publish', $session['id']) }}">
                @csrf
                <button class="btn-primary" type="submit">🚀 Publish — go live</button>
            </form>
        @endif
    </div>
</div>

{{-- ── Session metadata ──────────────────────────────────────────────── --}}
<form class="card inline" method="post" action="{{ route('admin.qt-videos.update', $session['id']) }}" style="margin-bottom:16px">
    @csrf
    @method('put')
    <h3 style="margin:0 0 14px">Session Details</h3>

    <label>Title *</label>
    <input name="title" value="{{ old('title', $session['title']) }}" required>

    <label style="margin-top:12px">Category *</label>
    <select name="category_id" required>
        @foreach($categories as $cat)
            <option value="{{ $cat['id'] }}" @selected(($session['category_id'] ?? '') === $cat['id'])>
                {{ $cat['name'] }}
            </option>
        @endforeach
    </select>

    <label style="margin-top:12px">Description</label>
    <textarea name="description" rows="3">{{ old('description', $session['description'] ?? '') }}</textarea>

    <div style="display:flex;gap:12px;margin-top:12px">
        <div style="flex:1">
            <label>Duration (minutes) *</label>
            <input name="duration_minutes" type="number" min="1" max="180"
                value="{{ old('duration_minutes', $session['duration_minutes'] ?? 5) }}" required>
        </div>
        <div style="flex:1">
            <label>Difficulty</label>
            <select name="difficulty_level">
                <option value="">— None —</option>
                <option value="beginner"     @selected(($session['difficulty_level'] ?? '') === 'beginner')>Beginner</option>
                <option value="intermediate" @selected(($session['difficulty_level'] ?? '') === 'intermediate')>Intermediate</option>
                <option value="advanced"     @selected(($session['difficulty_level'] ?? '') === 'advanced')>Advanced</option>
            </select>
        </div>
    </div>

    <label style="margin-top:12px">Scripture Reference</label>
    <input name="scripture_reference"
        value="{{ old('scripture_reference', $session['scripture_reference'] ?? '') }}"
        placeholder="e.g. Psalm 46:10">

    <label style="margin-top:12px">Reflection Prompt</label>
    <textarea name="reflection_prompt" rows="2">{{ old('reflection_prompt', $session['reflection_prompt'] ?? '') }}</textarea>

    <label style="margin-top:12px">
        <input type="checkbox" name="is_premium" value="1" @checked((bool)($session['is_premium'] ?? false))>
        &nbsp;Premium session
    </label>

    <label style="margin-top:12px">Status *</label>
    <select name="status" required>
        <option value="draft"      @selected($status === 'draft')>Draft — not visible in app</option>
        <option value="published"  @selected($status === 'published')>Published — live in app</option>
        <option value="hidden"     @selected($status === 'hidden')>Hidden</option>
        <option value="archived"   @selected($status === 'archived')>Archived</option>
    </select>

    <div style="margin-top:16px">
        <button class="btn-primary" type="submit">Save Changes</button>
    </div>
</form>

{{-- ── Video upload / replace ────────────────────────────────────────── --}}
<form class="card inline" method="post" action="{{ route('admin.qt-videos.upload', $session['id']) }}"
      enctype="multipart/form-data" style="margin-bottom:16px">
    @csrf
    <h3 style="margin:0 0 10px">{{ $hasVideo ? '🔄 Replace Video' : '⬆ Upload Video' }}</h3>

    @if($hasVideo)
        <p style="color:#667085;margin:0 0 12px;font-size:13px">
            Current path: <code>{{ $session['video_storage_path'] }}</code>
        </p>
    @else
        <p style="color:#B86B4B;margin:0 0 12px">
            No video uploaded yet. Upload a video for this session to appear in the app feed.
        </p>
    @endif

    <input type="file" name="video" accept="video/mp4,video/quicktime,video/x-m4v,video/webm" required>
    <small>MP4, MOV, or WebM. Maximum 500 MB.</small>

    <label style="margin-top:12px">After upload, set status to:</label>
    <select name="status">
        <option value="draft">Draft — stay hidden</option>
        <option value="published" selected>Published — go live immediately</option>
    </select>

    <div style="margin-top:14px">
        <button class="btn-primary" type="submit">
            {{ $hasVideo ? 'Replace Video' : 'Upload Video' }}
        </button>
    </div>
</form>

{{-- ── Video chapters ────────────────────────────────────────────────── --}}
<div class="card" style="margin-bottom:16px">
    <h3 style="margin:0 0 12px">Video Chapters
        <small style="font-weight:400;color:#8A948C">({{ count($chapters) }} chapters — optional in-video bookmarks)</small>
    </h3>

    @if(count($chapters) > 0)
        <div class="table-wrap">
            <table>
                <thead>
                    <tr><th>#</th><th>Title</th><th>Start</th><th>End</th><th>Scripture</th></tr>
                </thead>
                <tbody>
                    @foreach($chapters as $i => $ch)
                        <tr>
                            <td>{{ $i + 1 }}</td>
                            <td>{{ $ch['title'] }}</td>
                            <td>{{ gmdate('i:s', $ch['start_seconds'] ?? 0) }}</td>
                            <td>{{ isset($ch['end_seconds']) ? gmdate('i:s', $ch['end_seconds']) : '—' }}</td>
                            <td>{{ $ch['scripture_reference'] ?? '—' }}</td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    @else
        <p style="color:#8A948C;margin:0">No chapters yet. Chapters are optional — add them to create bookmarks inside the video.</p>
    @endif
</div>

{{-- ── Session metadata preview ─────────────────────────────────────── --}}
<div class="card" style="margin-bottom:16px">
    <h3 style="margin:0 0 8px">How This Session Looks in the App</h3>
    <p style="margin:0 0 6px"><strong>Title:</strong> {{ $session['title'] }}</p>
    <p style="margin:0 0 6px"><strong>Description:</strong> {{ $session['description'] ?? '—' }}</p>
    <p style="margin:0 0 6px"><strong>Scripture:</strong> {{ $session['scripture_reference'] ?? '—' }}</p>
    <p style="margin:0 0 6px"><strong>Reflection prompt:</strong> {{ $session['reflection_prompt'] ?? '—' }}</p>
    <p style="margin:0 0 6px"><strong>Duration:</strong> {{ $session['duration_minutes'] ?? '—' }} min</p>
    <p style="margin:0"><strong>Signed video URL path:</strong>
        <code>{{ $session['video_storage_path'] ?? 'Not yet uploaded' }}</code>
    </p>
</div>

{{-- ── Danger zone ───────────────────────────────────────────────────── --}}
<form method="post" action="{{ route('admin.qt-videos.destroy', $session['id']) }}" style="margin-top:4px">
    @csrf
    @method('delete')
    <button class="btn-outline" data-confirm="Archive this session? It will be removed from the app." type="submit">
        Archive Session
    </button>
</form>
@endsection

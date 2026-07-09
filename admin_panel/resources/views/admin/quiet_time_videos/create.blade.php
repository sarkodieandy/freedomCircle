@extends('layouts.admin', ['title' => 'New Quiet Time Video Session'])

@section('content')
<div class="page-head">
    <div><h2>New Quiet Time Video Session</h2><p>Create a video session that will appear in the Flutter app feed.</p></div>
    <a href="{{ route('admin.qt-videos.index') }}" class="btn-outline">← Back</a>
</div>

<form class="card inline" method="post" action="{{ route('admin.qt-videos.store') }}" enctype="multipart/form-data">
    @csrf

    <label>Title *</label>
    <input name="title" value="{{ old('title') }}" required placeholder="e.g. Morning Strength Prayer">

    <label style="margin-top:12px">Category *</label>
    <select name="category_id" required>
        <option value="">— Select category —</option>
        @foreach($categories as $cat)
            <option value="{{ $cat['id'] }}" @selected(old('category_id') === $cat['id'])>
                {{ $cat['name'] }}
            </option>
        @endforeach
    </select>

    <label style="margin-top:12px">Description</label>
    <textarea name="description" rows="3" placeholder="Short description shown under the video in the app.">{{ old('description') }}</textarea>

    <div style="display:flex;gap:12px;margin-top:12px">
        <div style="flex:1">
            <label>Duration (minutes) *</label>
            <input name="duration_minutes" type="number" min="1" max="180" value="{{ old('duration_minutes', 5) }}" required>
        </div>
        <div style="flex:1">
            <label>Difficulty</label>
            <select name="difficulty_level">
                <option value="">— None —</option>
                <option value="beginner"     @selected(old('difficulty_level') === 'beginner')>Beginner</option>
                <option value="intermediate" @selected(old('difficulty_level') === 'intermediate')>Intermediate</option>
                <option value="advanced"     @selected(old('difficulty_level') === 'advanced')>Advanced</option>
            </select>
        </div>
    </div>

    <label style="margin-top:12px">Scripture Reference</label>
    <input name="scripture_reference" value="{{ old('scripture_reference') }}" placeholder="e.g. Psalm 46:10">

    <label style="margin-top:12px">Reflection Prompt</label>
    <textarea name="reflection_prompt" rows="2" placeholder="What did God remind you of today?">{{ old('reflection_prompt') }}</textarea>

    <label style="margin-top:12px">
        <input type="checkbox" name="is_premium" value="1" @checked((bool) old('is_premium', false))>
        &nbsp;Premium session — requires active subscription to watch
    </label>

    <label style="margin-top:12px">Status after creation *</label>
    <select name="status" required>
        <option value="draft"      @selected(old('status', 'draft') === 'draft')>Draft — not visible in app</option>
        <option value="published"  @selected(old('status') === 'published')>Published — live in app immediately</option>
    </select>

    <hr style="margin:20px 0;border-color:#E7E0D5">

    <h3 style="margin:0 0 6px">Upload Video <small style="font-weight:400;color:#8A948C">(optional — you can upload later from the Edit page)</small></h3>
    <input type="file" name="video" accept="video/mp4,video/quicktime,video/x-m4v,video/webm">
    <small>MP4, MOV, or WebM. Maximum 500 MB. Stored privately in Supabase Storage.</small>

    <div style="margin-top:18px;display:flex;gap:10px">
        <button class="btn-primary" type="submit">Create Session</button>
        <a href="{{ route('admin.qt-videos.index') }}" class="btn-outline">Cancel</a>
    </div>
</form>
@endsection

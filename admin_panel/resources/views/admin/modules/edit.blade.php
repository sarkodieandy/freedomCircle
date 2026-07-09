@extends('layouts.admin', ['title' => 'Edit '.$module['label']])

@section('content')
<div class="page-head">
    <div>
        <h2>Edit {{ $module['label'] }}</h2>
        <p>Update operational record safely with audit logging.</p>
    </div>
</div>

<form class="card inline" method="post" action="{{ route('admin.module.update', ['module' => $moduleKey, 'id' => $record['id']]) }}">
    @csrf
    @method('put')

    @foreach($record as $key => $value)
        @if(in_array($key, ['id', 'created_at', 'updated_at'], true))
            @continue
        @endif

        <label style="display:block;margin-top:10px">{{ str_replace('_', ' ', ucfirst((string)$key)) }}</label>
        @if(is_array($value))
            <textarea name="{{ $key }}" rows="4">{{ json_encode($value, JSON_UNESCAPED_SLASHES) }}</textarea>
        @else
            <input name="{{ $key }}" value="{{ $value }}">
        @endif
    @endforeach

    <div style="margin-top:12px">
        <button class="btn-primary" type="submit">Save Changes</button>
    </div>
</form>
@endsection

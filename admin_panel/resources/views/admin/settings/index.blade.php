@extends('layouts.admin', ['title' => 'App Settings'])

@section('content')
<div class="page-head">
    <div>
        <h2>App Settings</h2>
        <p>Grouped setting management with audit logs and public/private safety split.</p>
    </div>
</div>

@foreach($groups as $group => $rows)
    <form class="card inline" method="post" action="{{ route('admin.app-settings.update-group', ['group' => $group]) }}" style="margin-bottom:12px">
        @csrf
        @method('put')
        <h3 style="margin-top:0;text-transform:capitalize">{{ str_replace('_', ' ', $group) }}</h3>

        @foreach($rows as $setting)
            @php
                $key = (string)($setting['key'] ?? '');
                $value = $setting['value'] ?? null;
                $type = (string)($setting['type'] ?? 'string');
            @endphp
            <label style="display:block;margin-top:10px">{{ $key }}</label>

            @if($type === 'boolean' || is_bool($value))
                <select name="settings[{{ $key }}]">
                    <option value="1" @selected((bool)$value === true)>Enabled</option>
                    <option value="0" @selected((bool)$value === false)>Disabled</option>
                </select>
            @elseif(is_array($value))
                <textarea rows="4" name="settings[{{ $key }}]">{{ json_encode($value, JSON_UNESCAPED_SLASHES) }}</textarea>
            @else
                <input name="settings[{{ $key }}]" value="{{ $value }}">
            @endif

            <div style="margin-top:6px">
                <button class="btn-outline" formaction="{{ route('admin.app-settings.reset', ['key' => $key]) }}" formmethod="post" formnovalidate>Reset To Default</button>
            </div>
        @endforeach

        <div style="margin-top:12px">
            <button class="btn-primary" type="submit">Save {{ ucfirst(str_replace('_', ' ', $group)) }} Settings</button>
        </div>
    </form>
@endforeach
@endsection

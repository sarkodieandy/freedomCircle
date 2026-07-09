<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ $title ?? 'FreedomCircle Admin' }}</title>
    <link rel="stylesheet" href="{{ asset('resources/css/admin.css') }}">
</head>
<body>
<div class="admin-shell">
    <aside class="sidebar">
        <div class="brand">
            <h1>{{ config('admin.brand.name') }}</h1>
            <p>{{ config('admin.brand.tagline') }}</p>
        </div>

        <div class="nav-section">
            <div class="nav-title">Operations</div>
            @foreach(config('admin.modules') as $moduleKey => $module)
                @php
                    $route = match($moduleKey) {
                        'dashboard' => route('admin.dashboard'),
                        'app-settings' => route('admin.app-settings.index'),
                        'search' => route('admin.search'),
                        'audit-logs' => route('admin.audit-logs.index'),
                        default => route('admin.module.index', ['module' => $moduleKey]),
                    };

                    $active = match($moduleKey) {
                        'dashboard' => request()->routeIs('admin.dashboard'),
                        'app-settings' => request()->routeIs('admin.app-settings.*'),
                        'search' => request()->routeIs('admin.search'),
                        'audit-logs' => request()->routeIs('admin.audit-logs.index'),
                        default => request()->is('admin/'.$moduleKey.'*'),
                    };
                @endphp
                <a class="nav-link {{ $active ? 'active' : '' }}"
                   href="{{ $route }}">
                    <span>{{ $module['label'] }}</span>
                </a>
            @endforeach
        </div>
    </aside>

    <div class="main">
        <header class="topbar">
            <form action="{{ route('admin.search') }}" method="get" class="search-box">
                <input name="q" type="search" placeholder="Search users, groups, payments, subscriptions..." value="{{ request('q', '') }}">
            </form>
            <div class="topbar-actions">
                <span class="badge">{{ request()->session()->get('admin_role', 'admin') }}</span>
                <form method="post" action="{{ route('admin.logout') }}">
                    @csrf
                    <button type="submit" class="btn-outline">Logout</button>
                </form>
            </div>
        </header>

        <main class="content">
            @if(session('status'))
                <div class="notice">{{ session('status') }}</div>
            @endif

            @if($errors->any())
                <div class="notice" style="border-left-color:#B42318;">
                    <strong>Validation Error</strong>
                    <ul>
                        @foreach($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif

            @yield('content')
        </main>
    </div>
</div>
<script src="{{ asset('resources/js/admin.js') }}"></script>
</body>
</html>

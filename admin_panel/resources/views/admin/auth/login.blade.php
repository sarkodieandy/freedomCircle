<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Admin Login</title>
    <link rel="stylesheet" href="{{ asset('resources/css/admin.css') }}">
</head>
<body style="display:grid;place-items:center;min-height:100vh;background:#FAF8F2;">
<form method="post" action="{{ route('admin.login.submit') }}" class="card" style="width:min(420px,92vw)">
    @csrf
    <h2 style="margin-top:0">FreedomCircle Admin</h2>
    <p style="margin-top:4px;color:#667085">Secure operations login</p>

    <div style="display:grid;gap:10px">
        <label>Email</label>
        <input name="email" type="email" required value="{{ old('email') }}">

        <label>Password</label>
        <input name="password" type="password" required>

        <button type="submit" class="btn-primary">Login</button>
    </div>
</form>
</body>
</html>

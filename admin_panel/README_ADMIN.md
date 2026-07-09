# FreedomCircle Admin Panel (Laravel)

This folder contains FreedomCircle's custom admin domain code (controllers, services, routes, views, migrations) and should be mounted into a full Laravel application scaffold.

## 1) Bootstrap Laravel Scaffold

If this folder does not include `artisan`, `vendor/`, `bootstrap/`, and `config/app.php`, create a fresh Laravel app and then copy these project files into it.

Example:

```bash
composer create-project laravel/laravel freedomcircle-admin
cd freedomcircle-admin
# copy app/, config/, database/, resources/, routes/, and .env.example from this folder
```

## 2) Environment Variables

Use values in `.env.example` and set production secrets server-side only.

Critical variables:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `PAYSTACK_SECRET_KEY`
- `PAYSTACK_WEBHOOK_SECRET`
- `REVENUECAT_WEBHOOK_SECRET`
- `FIRST_SUPER_ADMIN_EMAIL`
- `FIRST_SUPER_ADMIN_PASSWORD`

## 3) Register Middleware Aliases

Laravel 11 (`bootstrap/app.php`):

```php
->withMiddleware(function ($middleware) {
    $middleware->alias([
        'admin.auth' => \App\Http\Middleware\EnsureAdminAuthenticated::class,
        'admin.role' => \App\Http\Middleware\EnsureAdminRole::class,
    ]);
})
```

Laravel 10 (`app/Http/Kernel.php`): add to `$routeMiddleware`:

```php
'admin.auth' => \App\Http\Middleware\EnsureAdminAuthenticated::class,
'admin.role' => \App\Http\Middleware\EnsureAdminRole::class,
```

## 4) Run DB Setup

```bash
php artisan migrate
php artisan db:seed
```

This creates and seeds:

- `admin_users`
- `audit_logs`
- `webhook_events`
- `app_settings`

A super admin account is seeded from environment variables.

## 5) Serve and Verify

```bash
php artisan serve
```

Then test:

- `GET /admin/login`
- Login as seeded admin
- `GET /admin`
- `GET /admin/app-settings`
- `GET /admin/audit-logs`
- `POST /api/webhooks/paystack`
- `POST /api/webhooks/revenuecat`
- `GET /api/public-settings`

## 6) Production Checklist

- Enforce HTTPS and trusted proxies.
- Set strict CORS + rate limits for webhook routes.
- Add queue workers for heavy webhook/event processing.
- Add feature tests for admin auth, RBAC, settings updates, and webhook idempotency.
- Configure centralized logging and alerts (failed webhooks, repeated auth failures, payout errors).

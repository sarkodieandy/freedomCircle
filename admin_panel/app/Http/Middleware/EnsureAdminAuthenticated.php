<?php

namespace App\Http\Middleware;

use App\Models\AdminUser;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdminAuthenticated
{
    public function handle(Request $request, Closure $next): Response
    {
        $adminId = $request->session()->get('admin_user_id');
        if (! is_string($adminId)) {
            return \redirect()->route('admin.login');
        }

        $admin = AdminUser::query()->find($adminId);
        if (! $admin || ! $admin->is_active) {
            $request->session()->forget(['admin_user_id', 'admin_role']);

            return \redirect()->route('admin.login')
                ->withErrors(['email' => 'Your admin session is no longer valid.']);
        }

        $request->attributes->set('admin_user', $admin);

        return $next($request);
    }
}

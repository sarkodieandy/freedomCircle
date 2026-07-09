<?php

namespace App\Http\Middleware;

use App\Models\AdminUser;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdminRole
{
    public function handle(Request $request, Closure $next, string $permission): Response
    {
        $admin = $request->attributes->get('admin_user');
        if (! $admin instanceof AdminUser) {
            return \redirect()->route('admin.login');
        }

        if (! $admin->hasPermission($permission)) {
            \abort(403, 'You do not have permission to access this area.');
        }

        return $next($request);
    }
}

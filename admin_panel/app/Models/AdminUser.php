<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * @property string $role
 * @property bool $is_active
 * @property array<int, string>|null $permissions
 */
class AdminUser extends Model
{
    protected $table = 'admin_users';

    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'is_active',
        'permissions',
        'last_seen_at',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'permissions' => 'array',
        'last_seen_at' => 'datetime',
    ];

    public function hasPermission(string $permission): bool
    {
        if ($this->role === 'super_admin') {
            return true;
        }

        $rolePermissions = \config('admin.roles.' . $this->role . '.permissions', []);
        if (in_array('*', $rolePermissions, true) || in_array($permission, $rolePermissions, true)) {
            return true;
        }

        return in_array($permission, $this->permissions ?? [], true);
    }
}

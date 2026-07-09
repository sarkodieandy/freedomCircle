<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        $email = (string) \env('FIRST_SUPER_ADMIN_EMAIL', 'admin@freedomcircle.app');
        $password = (string) \env('FIRST_SUPER_ADMIN_PASSWORD', 'ChangeThisPassword123!');

        $existing = DB::table('admin_users')->where('email', $email)->exists();
        if ($existing) {
            return;
        }

        DB::table('admin_users')->insert([
            'id' => (string) Str::uuid(),
            'name' => 'FreedomCircle Super Admin',
            'email' => $email,
            'password' => Hash::make($password),
            'role' => 'super_admin',
            'is_active' => true,
            'permissions' => json_encode(['*'], JSON_THROW_ON_ERROR),
            'created_at' => \now(),
            'updated_at' => \now(),
        ]);
    }
}

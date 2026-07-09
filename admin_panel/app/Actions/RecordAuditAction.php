<?php

namespace App\Actions;

use App\Models\AdminUser;
use Illuminate\Support\Facades\DB;

class RecordAuditAction
{
    public function execute(
        AdminUser $admin,
        string $action,
        string $targetType,
        ?string $targetId = null,
        array $metadata = []
    ): void {
        DB::table('audit_logs')->insert([
            'admin_user_id' => $admin->id,
            'action' => $action,
            'target_type' => $targetType,
            'target_id' => $targetId,
            'metadata' => json_encode($metadata, JSON_THROW_ON_ERROR),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}

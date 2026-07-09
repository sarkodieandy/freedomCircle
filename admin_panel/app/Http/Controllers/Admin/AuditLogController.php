<?php

namespace App\Http\Controllers\Admin;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class AuditLogController extends Controller
{
    public function index(Request $request): View
    {
        $query = DB::table('audit_logs')
            ->orderByDesc('created_at');

        if ($request->filled('action')) {
            $query->where('action', (string) $request->query('action'));
        }

        if ($request->filled('admin_user_id')) {
            $query->where('admin_user_id', (string) $request->query('admin_user_id'));
        }

        if ($request->filled('target_type')) {
            $query->where('target_type', (string) $request->query('target_type'));
        }

        $logs = $query->paginate(50)->withQueryString();

        return view('admin.audit.index', [
            'logs' => $logs,
        ]);
    }
}

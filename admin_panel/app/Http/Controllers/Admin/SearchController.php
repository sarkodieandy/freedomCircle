<?php

namespace App\Http\Controllers\Admin;

use App\Services\SupabaseAdminService;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\View\View;

class SearchController extends Controller
{
    public function __construct(private readonly SupabaseAdminService $supabase)
    {
    }

    public function index(Request $request): View
    {
        $query = trim((string) $request->query('q', ''));
        $results = [];

        if ($query !== '') {
            $results = $this->supabase->globalSearch($query);
        }

        return view('admin.search.index', [
            'query' => $query,
            'results' => $results,
        ]);
    }
}

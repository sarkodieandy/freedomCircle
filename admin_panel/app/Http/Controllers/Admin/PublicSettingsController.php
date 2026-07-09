<?php

namespace App\Http\Controllers\Admin;

use App\Services\AppSettingsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Routing\Controller;

class PublicSettingsController extends Controller
{
    public function __construct(private readonly AppSettingsService $settings)
    {
    }

    public function __invoke(): JsonResponse
    {
        return response()->json([
            'settings' => $this->settings->publicSettings(),
        ]);
    }
}

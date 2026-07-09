<?php

namespace App\Http\Controllers\Webhooks;

use App\Services\RevenueCatWebhookService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Throwable;

class RevenueCatWebhookController extends Controller
{
    public function __construct(private readonly RevenueCatWebhookService $service)
    {
    }

    public function __invoke(Request $request): JsonResponse
    {
        $headerSecret = $request->header('X-RevenueCat-Signature')
            ?? $request->header('Authorization');

        if (! $this->service->verifySecret(is_string($headerSecret) ? $headerSecret : null)) {
            return response()->json(['message' => 'Invalid webhook secret.'], 401);
        }

        try {
            $this->service->process($request->json()->all());
        } catch (Throwable $exception) {
            report($exception);

            return response()->json(['message' => 'Webhook processing failed.'], 500);
        }

        return response()->json(['message' => 'ok']);
    }
}

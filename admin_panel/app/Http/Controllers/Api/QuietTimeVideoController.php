<?php

namespace App\Http\Controllers\Api;

use App\Services\QuietTimeVideoService;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Validation\ValidationException;
use Throwable;

class QuietTimeVideoController extends Controller
{
    public function __construct(private readonly QuietTimeVideoService $service)
    {
    }

    public function signedVideoUrl(Request $request, string $sessionId): JsonResponse
    {
        $token = (string) ($request->bearerToken() ?? '');
        if ($token === '') {
            return response()->json([
                'message' => 'Authentication token is required.',
            ], 401);
        }

        try {
            $payload = $this->service->issueSignedVideoUrl($sessionId, $token);

            return response()->json($payload);
        } catch (AuthenticationException $exception) {
            return response()->json([
                'message' => $exception->getMessage(),
            ], 401);
        } catch (ValidationException $exception) {
            return response()->json([
                'message' => 'Unable to issue signed video URL.',
                'errors' => $exception->errors(),
            ], 422);
        } catch (Throwable $exception) {
            report($exception);

            return response()->json([
                'message' => 'Failed to generate signed video URL.',
            ], 500);
        }
    }
}
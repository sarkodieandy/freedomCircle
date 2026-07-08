<?php

namespace App\Http\Controllers\Auth;

use App\Services\AfricasTalkingOtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

class OtpController
{
    public function __construct(private readonly AfricasTalkingOtpService $otpService)
    {
    }

    public function send(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'phone' => ['required', 'string', 'min:10', 'max:20'],
            'purpose' => ['nullable', 'string', 'max:80'],
            'user_id' => ['nullable', 'uuid'],
        ]);

        try {
            $result = $this->otpService->sendOtp(
                phone: (string) $payload['phone'],
                purpose: (string) ($payload['purpose'] ?? 'auth_login'),
                userId: $payload['user_id'] ?? null,
            );

            return response()->json([
                'message' => 'OTP sent successfully.',
                'expires_in_seconds' => $result['expires_in_seconds'],
                'retry_in_seconds' => $result['retry_in_seconds'],
            ]);
        } catch (Throwable $exception) {
            return response()->json([
                'message' => $exception->getMessage(),
            ], 422);
        }
    }

    public function verify(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'phone' => ['required', 'string', 'min:10', 'max:20'],
            'code' => ['required', 'string', 'size:6'],
            'purpose' => ['nullable', 'string', 'max:80'],
            'user_id' => ['nullable', 'uuid'],
        ]);

        try {
            $result = $this->otpService->verifyOtp(
                phone: (string) $payload['phone'],
                code: (string) $payload['code'],
                purpose: (string) ($payload['purpose'] ?? 'auth_login'),
                userId: $payload['user_id'] ?? null,
            );

            return response()->json([
                'verified' => $result['verified'],
                'message' => $result['message'],
            ]);
        } catch (Throwable $exception) {
            return response()->json([
                'verified' => false,
                'message' => $exception->getMessage(),
            ], 422);
        }
    }
}

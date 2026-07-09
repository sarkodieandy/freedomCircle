<?php

use App\Http\Controllers\Auth\OtpController;
use App\Http\Controllers\Api\QuietTimeVideoController;
use App\Http\Controllers\Admin\PublicSettingsController;
use App\Http\Controllers\Webhooks\PaystackWebhookController;
use App\Http\Controllers\Webhooks\RevenueCatWebhookController;
use Illuminate\Support\Facades\Route;

Route::post('/webhooks/paystack', PaystackWebhookController::class)
    ->middleware('throttle:120,1')
    ->name('webhooks.paystack');

Route::post('/webhooks/revenuecat', RevenueCatWebhookController::class)
    ->middleware('throttle:120,1')
    ->name('webhooks.revenuecat');

Route::get('/public-settings', PublicSettingsController::class)
    ->name('public.settings');

Route::prefix('auth/otp')->group(function (): void {
    Route::post('/send', [OtpController::class, 'send'])
        ->name('auth.otp.send');
    Route::post('/verify', [OtpController::class, 'verify'])
        ->name('auth.otp.verify');
});

Route::get('/quiet-time/sessions/{sessionId}/signed-video-url', [QuietTimeVideoController::class, 'signedVideoUrl'])
    ->name('quiet_time.signed_video_url');

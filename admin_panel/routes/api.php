<?php

use App\Http\Controllers\Auth\OtpController;
use App\Http\Controllers\Webhooks\PaystackWebhookController;
use Illuminate\Support\Facades\Route;

Route::post('/webhooks/paystack', PaystackWebhookController::class)
    ->name('webhooks.paystack');

Route::prefix('auth/otp')->group(function (): void {
    Route::post('/send', [OtpController::class, 'send'])
        ->name('auth.otp.send');
    Route::post('/verify', [OtpController::class, 'verify'])
        ->name('auth.otp.verify');
});

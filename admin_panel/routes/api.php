<?php

use App\Http\Controllers\Webhooks\PaystackWebhookController;
use Illuminate\Support\Facades\Route;

Route::post('/webhooks/paystack', PaystackWebhookController::class)
    ->name('webhooks.paystack');

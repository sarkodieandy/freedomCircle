<?php

namespace App\Http\Controllers\Webhooks;

use App\Services\PaymentService;
use App\Services\SupabaseAdminService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class PaystackWebhookController
{
    public function __construct(
        private readonly SupabaseAdminService $supabase,
        private readonly PaymentService $paymentService,
    )
    {
    }

    public function __invoke(Request $request): JsonResponse
    {
        $payload = $request->getContent();

        if (! $this->hasValidSignature($payload, (string) $request->header('x-paystack-signature'))) {
            Log::warning('Rejected Paystack webhook with invalid signature.');

            return response()->json(['message' => 'Invalid signature'], 401);
        }

        $event = $request->json()->all();
        $eventName = (string) ($event['event'] ?? '');
        $eventId = (string) ($event['data']['id'] ?? $event['data']['reference'] ?? '');

        if ($eventId !== '' && $this->isDuplicate($eventId, $eventName)) {
            return response()->json(['message' => 'Duplicate webhook ignored']);
        }

        try {
            match ($eventName) {
                'charge.success' => $this->handleChargeSuccess($event),
                'subscription.create',
                'subscription.enable',
                'subscription.disable' => $this->handleSubscriptionEvent($event),
                default => Log::info('Ignored Paystack webhook event.', ['event' => $eventName]),
            };

            if ($eventId !== '') {
                $this->storeWebhookEvent($eventId, $eventName, $event);
            }
        } catch (Throwable $exception) {
            Log::error('Paystack webhook processing failed.', [
                'event' => $eventName,
                'message' => $exception->getMessage(),
            ]);

            return response()->json(['message' => 'Webhook processing failed'], 500);
        }

        return response()->json(['message' => 'Webhook accepted']);
    }

    private function handleChargeSuccess(array $event): void
    {
        $data = $event['data'] ?? [];
        $reference = (string) ($data['reference'] ?? '');

        if ($reference === '') {
            Log::warning('Paystack charge.success event missing reference.');

            return;
        }

        $this->paymentService->applyPaystackWebhookCharge($event);
    }

    private function handleSubscriptionEvent(array $event): void
    {
        $data = $event['data'] ?? [];
        $metadata = is_array($data['metadata'] ?? null) ? $data['metadata'] : [];
        $subscriptionId = $metadata['subscription_id'] ?? null;

        if (! is_string($subscriptionId) || $subscriptionId === '') {
            Log::info('Paystack subscription event has no Supabase subscription id.', [
                'event' => $event['event'] ?? null,
                'subscription_code' => $data['subscription_code'] ?? null,
            ]);

            return;
        }

        $this->supabase->updateSubscription($subscriptionId, [
            'status' => $this->mapSubscriptionStatus((string) ($data['status'] ?? '')),
            'provider' => 'paystack',
            'provider_subscription_id' => $data['subscription_code'] ?? null,
            'current_period_end' => $data['next_payment_date'] ?? null,
            'cancelled_at' => ($event['event'] ?? null) === 'subscription.disable' ? now()->toISOString() : null,
            'metadata' => [
                'paystack_event' => $event['event'] ?? null,
                'paystack_subscription_code' => $data['subscription_code'] ?? null,
                'paystack_email_token' => $data['email_token'] ?? null,
            ],
        ]);

        if (($event['event'] ?? null) !== 'subscription.disable') {
            $this->supabase->grantEntitlements($subscriptionId);
        }
    }

    private function hasValidSignature(string $payload, string $signature): bool
    {
        $secret = $this->paystackSecretKey();

        if ($secret === '' || $signature === '') {
            return false;
        }

        $expected = hash_hmac('sha512', $payload, $secret);

        return hash_equals($expected, $signature);
    }

    private function isDuplicate(string $eventId, string $eventType): bool
    {
        return DB::table('webhook_events')
            ->where('provider', 'paystack')
            ->where('provider_event_id', $eventId)
            ->where('event_type', $eventType)
            ->exists();
    }

    private function storeWebhookEvent(string $eventId, string $eventType, array $payload): void
    {
        DB::table('webhook_events')->insert([
            'provider' => 'paystack',
            'provider_event_id' => $eventId,
            'event_type' => $eventType,
            'payload' => json_encode($payload, JSON_THROW_ON_ERROR),
            'processed_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function mapSubscriptionStatus(string $paystackStatus): string
    {
        return match ($paystackStatus) {
            'active', 'non-renewing' => 'active',
            'attention' => 'past_due',
            'cancelled' => 'cancelled',
            'complete' => 'expired',
            default => 'past_due',
        };
    }

    private function paystackSecretKey(): string
    {
        return (string) (config('services.paystack.secret_key') ?? env('PAYSTACK_SECRET_KEY', ''));
    }
}

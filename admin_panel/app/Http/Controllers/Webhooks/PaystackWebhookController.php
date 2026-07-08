<?php

namespace App\Http\Controllers\Webhooks;

use App\Services\SupabaseAdminService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

class PaystackWebhookController
{
    public function __construct(private readonly SupabaseAdminService $supabase)
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

        try {
            match ($eventName) {
                'charge.success' => $this->handleChargeSuccess($event),
                'subscription.create',
                'subscription.enable',
                'subscription.disable' => $this->handleSubscriptionEvent($event),
                default => Log::info('Ignored Paystack webhook event.', ['event' => $eventName]),
            };
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

        $verification = $this->verifyPaystackTransaction($reference);
        $verifiedData = $verification['data'] ?? [];
        $status = (string) ($verifiedData['status'] ?? $data['status'] ?? '');

        if ($status !== 'success') {
            $this->supabase->markPaymentFailedByReference($reference, $status, [
                'paystack_event' => 'charge.success',
                'paystack_reference' => $reference,
            ]);

            return;
        }

        $providerFee = isset($verifiedData['fees'])
            ? round(((float) $verifiedData['fees']) / 100, 2)
            : null;

        $this->supabase->markPaymentSuccessfulByReference($reference, 'success', $providerFee, [
            'paystack_event' => 'charge.success',
            'paystack_reference' => $reference,
            'paystack_channel' => $verifiedData['channel'] ?? null,
            'paystack_paid_at' => $verifiedData['paid_at'] ?? null,
            'paystack_customer_email' => $verifiedData['customer']['email'] ?? null,
        ]);
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

    private function verifyPaystackTransaction(string $reference): array
    {
        return Http::withToken($this->paystackSecretKey())
            ->acceptJson()
            ->get('https://api.paystack.co/transaction/verify/' . rawurlencode($reference))
            ->throw()
            ->json();
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

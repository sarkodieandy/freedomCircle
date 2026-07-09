<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use RuntimeException;

class PaymentService
{
    public function __construct(private readonly SupabaseAdminService $supabase)
    {
    }

    public function verifyPaystackPayment(string $reference): array
    {
        $secret = (string) config('services.paystack.secret_key');
        if ($secret === '') {
            throw new RuntimeException('PAYSTACK_SECRET_KEY is not configured.');
        }

        return Http::withToken($secret)
            ->acceptJson()
            ->get('https://api.paystack.co/transaction/verify/' . rawurlencode($reference))
            ->throw()
            ->json();
    }

    public function applyPaystackWebhookCharge(array $event): void
    {
        $data = $event['data'] ?? [];
        $reference = (string) ($data['reference'] ?? '');
        if ($reference === '') {
            throw new RuntimeException('Paystack payload missing reference.');
        }

        $verification = $this->verifyPaystackPayment($reference);
        $verifiedData = $verification['data'] ?? [];
        $status = (string) ($verifiedData['status'] ?? 'failed');
        $providerFee = isset($verifiedData['fees'])
            ? round(((float) $verifiedData['fees']) / 100, 2)
            : null;

        if ($status === 'success') {
            $this->supabase->markPaymentSuccessfulByReference($reference, $status, $providerFee, [
                'paystack_event' => 'charge.success',
                'channel' => $verifiedData['channel'] ?? null,
                'paid_at' => $verifiedData['paid_at'] ?? null,
            ]);

            return;
        }

        $this->supabase->markPaymentFailedByReference($reference, $status, [
            'paystack_event' => 'charge.success',
        ]);
    }

    public function listPayments(array $filters = []): array
    {
        return $this->supabase->payments($filters);
    }
}

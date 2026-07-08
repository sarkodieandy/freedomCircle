<?php

namespace App\Services;

use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use RuntimeException;

class AfricasTalkingOtpService
{
    private const OTP_LENGTH = 6;
    private const OTP_TTL_MINUTES = 10;
    private const OTP_MAX_ATTEMPTS = 5;
    private const OTP_RESEND_COOLDOWN_SECONDS = 45;

    public function sendOtp(string $phone, string $purpose = 'auth_login', ?string $userId = null): array
    {
        $phoneE164 = $this->normalizePhone($phone);
        $purpose = trim($purpose) !== '' ? trim($purpose) : 'auth_login';

        $lastOtp = $this->latestOtp($phoneE164, $purpose);
        if ($lastOtp !== null) {
            $createdAt = strtotime((string) ($lastOtp['created_at'] ?? ''));
            if ($createdAt !== false) {
                $elapsed = time() - $createdAt;
                if ($elapsed < self::OTP_RESEND_COOLDOWN_SECONDS) {
                    throw new RuntimeException('Please wait before requesting another OTP.');
                }
            }
        }

        $otpCode = $this->generateOtp();
        $appName = $this->appName();
        $message = "Your {$appName} OTP is {$otpCode}. It expires in 10 minutes.";
        $this->sendSms($phoneE164, $message);

        $expiresAt = now()->addMinutes(self::OTP_TTL_MINUTES);
        $this->rest()
            ->post($this->endpoint('otp_verifications'), [
                'phone_e164' => $phoneE164,
                'purpose' => $purpose,
                'provider' => 'africastalking',
                'code_hash' => $this->hashOtp($phoneE164, $otpCode),
                'attempts_remaining' => self::OTP_MAX_ATTEMPTS,
                'status' => 'pending',
                'expires_at' => $expiresAt->toISOString(),
                'metadata' => [
                    'user_id' => $userId,
                    'channel' => 'sms',
                ],
            ])
            ->throw();

        return [
            'expires_in_seconds' => self::OTP_TTL_MINUTES * 60,
            'retry_in_seconds' => self::OTP_RESEND_COOLDOWN_SECONDS,
        ];
    }

    public function verifyOtp(string $phone, string $code, string $purpose = 'auth_login', ?string $userId = null): array
    {
        $phoneE164 = $this->normalizePhone($phone);
        $purpose = trim($purpose) !== '' ? trim($purpose) : 'auth_login';

        $otp = $this->latestOtp($phoneE164, $purpose);
        if ($otp === null) {
            throw new RuntimeException('No OTP request found.');
        }

        $otpId = (string) ($otp['id'] ?? '');
        if ($otpId === '') {
            throw new RuntimeException('OTP record is invalid.');
        }

        if (($otp['status'] ?? '') !== 'pending') {
            throw new RuntimeException('OTP is no longer valid.');
        }

        $expiresAt = strtotime((string) ($otp['expires_at'] ?? ''));
        if ($expiresAt !== false && $expiresAt < time()) {
            $this->updateOtp($otpId, ['status' => 'expired']);
            throw new RuntimeException('OTP has expired.');
        }

        $attemptsRemaining = (int) ($otp['attempts_remaining'] ?? 0);
        if ($attemptsRemaining <= 0) {
            $this->updateOtp($otpId, ['status' => 'locked']);
            throw new RuntimeException('Too many attempts. Request a new OTP.');
        }

        $expected = (string) ($otp['code_hash'] ?? '');
        $provided = $this->hashOtp($phoneE164, $code);

        if (! hash_equals($expected, $provided)) {
            $nextAttempts = max(0, $attemptsRemaining - 1);
            $nextStatus = $nextAttempts === 0 ? 'locked' : 'pending';
            $this->updateOtp($otpId, [
                'attempts_remaining' => $nextAttempts,
                'status' => $nextStatus,
            ]);

            throw new RuntimeException('Invalid OTP code.');
        }

        $this->updateOtp($otpId, [
            'status' => 'verified',
            'verified_at' => now()->toISOString(),
            'metadata' => [
                'user_id' => $userId,
                'verified_with' => 'sms',
            ],
        ]);

        return [
            'verified' => true,
            'message' => 'OTP verified successfully.',
        ];
    }

    private function latestOtp(string $phoneE164, string $purpose): ?array
    {
        $rows = $this->rest()
            ->get($this->endpoint('otp_verifications'), [
                'phone_e164' => "eq.{$phoneE164}",
                'purpose' => "eq.{$purpose}",
                'order' => 'created_at.desc',
                'limit' => 1,
            ])
            ->throw()
            ->json();

        return $rows[0] ?? null;
    }

    private function updateOtp(string $otpId, array $payload): void
    {
        $this->rest()
            ->patch($this->endpoint('otp_verifications', ['id' => "eq.{$otpId}"]), $payload)
            ->throw();
    }

    private function sendSms(string $phoneE164, string $message): void
    {
        $response = Http::asForm()
            ->withHeaders([
                'apiKey' => $this->africasTalkingApiKey(),
                'Accept' => 'application/json',
            ])
            ->post('https://api.africastalking.com/version1/messaging', [
                'username' => $this->africasTalkingUsername(),
                'to' => $phoneE164,
                'message' => $message,
                'from' => $this->africasTalkingSenderId(),
            ])
            ->throw()
            ->json();

        $recipients = $response['SMSMessageData']['Recipients'] ?? [];
        if (! is_array($recipients) || $recipients === []) {
            throw new RuntimeException('Failed to send OTP SMS.');
        }
    }

    private function generateOtp(): string
    {
        return str_pad((string) random_int(0, 999999), self::OTP_LENGTH, '0', STR_PAD_LEFT);
    }

    private function hashOtp(string $phoneE164, string $otpCode): string
    {
        $secret = (string) (env('OTP_HASH_SECRET') ?: env('APP_KEY'));
        if ($secret === '') {
            $secret = Str::random(32);
        }

        return hash_hmac('sha256', "{$phoneE164}:{$otpCode}", $secret);
    }

    private function normalizePhone(string $phone): string
    {
        $clean = preg_replace('/\s+/', '', trim($phone)) ?? '';
        if ($clean === '') {
            throw new RuntimeException('Phone number is required.');
        }

        if (! str_starts_with($clean, '+')) {
            if (str_starts_with($clean, '0')) {
                $clean = '+233' . substr($clean, 1);
            } else {
                $clean = '+' . ltrim($clean, '+');
            }
        }

        if (! preg_match('/^\+[1-9][0-9]{7,14}$/', $clean)) {
            throw new RuntimeException('Phone number must be in valid international format.');
        }

        return $clean;
    }

    private function rest(): PendingRequest
    {
        $key = $this->serviceRoleKey();

        return Http::withHeaders([
            'apikey' => $key,
            'Authorization' => "Bearer {$key}",
            'Content-Type' => 'application/json',
            'Prefer' => 'return=representation',
        ]);
    }

    private function endpoint(string $table, array $query = []): string
    {
        $url = "{$this->baseUrl()}/rest/v1/{$table}";

        if ($query === []) {
            return $url;
        }

        return $url . '?' . http_build_query($query);
    }

    private function baseUrl(): string
    {
        return rtrim((string) (config('services.supabase.url') ?? env('SUPABASE_URL')), '/');
    }

    private function serviceRoleKey(): string
    {
        return (string) (config('services.supabase.service_role_key')
            ?? env('SUPABASE_SERVICE_ROLE_KEY'));
    }

    private function africasTalkingUsername(): string
    {
        $username = (string) (config('services.africastalking.username')
            ?? env('AFRICASTALKING_USERNAME', 'sandbox'));

        if ($username === '') {
            throw new RuntimeException('Africa\'s Talking username is not configured.');
        }

        return $username;
    }

    private function africasTalkingApiKey(): string
    {
        $key = (string) (config('services.africastalking.api_key')
            ?? env('AFRICASTALKING_API_KEY', ''));

        if ($key === '') {
            throw new RuntimeException('Africa\'s Talking API key is not configured.');
        }

        return $key;
    }

    private function africasTalkingSenderId(): ?string
    {
        $senderId = (string) (config('services.africastalking.sender_id')
            ?? env('AFRICASTALKING_SENDER_ID', ''));

        return $senderId !== '' ? $senderId : null;
    }

    private function appName(): string
    {
        $value = (string) (config('app.name') ?: env('AFRICASTALKING_APP_NAME', 'FreedomCircle'));
        $trimmed = trim($value);

        return $trimmed !== '' ? $trimmed : 'FreedomCircle';
    }
}

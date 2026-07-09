<?php

namespace App\Services;

use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Http;

class SupabaseAdminService
{
    public function __construct(
        private readonly ?string $url = null,
        private readonly ?string $serviceRoleKey = null,
    ) {
    }

    public function openReports(): array
    {
        return $this->rest()
            ->get($this->endpoint('reports'), [
                'status' => 'eq.open',
                'order' => 'created_at.desc',
            ])
            ->throw()
            ->json();
    }

    public function approveHelper(string $helperId, ?string $note = null): array
    {
        return $this->rest()
            ->patch($this->endpoint('helpers', ['id' => "eq.$helperId"]), [
                'verification_status' => 'active',
                'verification_note' => $note,
            ])
            ->throw()
            ->json();
    }

    public function hidePost(string $postId, string $adminNote): array
    {
        return $this->rest()
            ->patch($this->endpoint('community_posts', ['id' => "eq.$postId"]), [
                'status' => 'hidden',
            ])
            ->throw()
            ->json();
    }

    public function plans(?string $type = null): array
    {
        $query = ['order' => 'sort_order.asc'];
        if ($type !== null) {
            $query['plan_type'] = "eq.$type";
        }

        return $this->rest()
            ->get($this->endpoint('plans'), $query)
            ->throw()
            ->json();
    }

    public function quietTimeCategories(): array
    {
        return $this->rest()
            ->get($this->endpoint('quiet_time_categories'), [
                'order' => 'sort_order.asc',
            ])
            ->throw()
            ->json();
    }

    public function createQuietTimeCategory(array $values): array
    {
        return $this->insert('quiet_time_categories', $values);
    }

    public function updateQuietTimeCategory(string $categoryId, array $values): array
    {
        return $this->patchById('quiet_time_categories', $categoryId, $values);
    }

    public function quietTimeSessions(?string $categoryId = null): array
    {
        $query = [
            'order' => 'sort_order.asc',
            'select' => '*,quiet_time_categories(name,slug)',
        ];
        if ($categoryId !== null) {
            $query['category_id'] = "eq.$categoryId";
        }

        return $this->rest()
            ->get($this->endpoint('quiet_time_sessions'), $query)
            ->throw()
            ->json();
    }

    public function createQuietTimeSession(array $values): array
    {
        return $this->insert('quiet_time_sessions', $values);
    }

    public function updateQuietTimeSession(string $sessionId, array $values): array
    {
        return $this->patchById('quiet_time_sessions', $sessionId, $values);
    }

    public function quietTimeVideoSessions(array $filters = []): array
    {
        return $this->rest()
            ->get($this->endpoint('quiet_time_sessions'), array_merge([
                'session_type' => 'eq.video',
                'order' => 'sort_order.asc',
                'select' => '*,quiet_time_categories(name,slug)',
            ], $filters))
            ->throw()
            ->json();
    }

    public function quietTimeVideoChapters(string $sessionId): array
    {
        return $this->rest()
            ->get($this->endpoint('quiet_time_video_chapters'), [
                'session_id' => "eq.$sessionId",
                'order' => 'sort_order.asc',
            ])
            ->throw()
            ->json();
    }

    public function createQuietTimeVideoChapter(array $values): array
    {
        return $this->insert('quiet_time_video_chapters', $values);
    }

    public function updateQuietTimeVideoChapter(string $chapterId, array $values): array
    {
        return $this->patchById('quiet_time_video_chapters', $chapterId, $values);
    }

    public function quietTimeSteps(string $sessionId): array
    {
        return $this->rest()
            ->get($this->endpoint('quiet_time_steps'), [
                'session_id' => "eq.$sessionId",
                'order' => 'sort_order.asc',
            ])
            ->throw()
            ->json();
    }

    public function createQuietTimeStep(array $values): array
    {
        return $this->insert('quiet_time_steps', $values);
    }

    public function updateQuietTimeStep(string $stepId, array $values): array
    {
        return $this->patchById('quiet_time_steps', $stepId, $values);
    }

    public function planFeatures(string $planId): array
    {
        return $this->rest()
            ->get($this->endpoint('plan_features'), [
                'plan_id' => "eq.$planId",
                'order' => 'feature_name.asc',
            ])
            ->throw()
            ->json();
    }

    public function createPlan(array $values): array
    {
        return $this->insert('plans', $values);
    }

    public function updatePlan(string $planId, array $values): array
    {
        return $this->patchById('plans', $planId, $values);
    }

    public function createPlanFeature(array $values): array
    {
        return $this->insert('plan_features', $values);
    }

    public function updatePlanFeature(string $featureId, array $values): array
    {
        return $this->patchById('plan_features', $featureId, $values);
    }

    public function grantManualEntitlement(
        ?string $userId,
        ?string $organizationId,
        string $featureKey,
        ?string $planId = null,
        ?string $expiresAt = null,
        array $value = []
    ): array {
        return $this->insert('entitlements', [
            'user_id' => $userId,
            'organization_id' => $organizationId,
            'plan_id' => $planId,
            'entitlement_key' => $featureKey,
            'entitlement_value' => $value,
            'expires_at' => $expiresAt,
            'source' => 'admin_grant',
        ]);
    }

    public function subscriptions(array $filters = []): array
    {
        return $this->rest()
            ->get($this->endpoint('subscriptions'), array_merge([
                'order' => 'created_at.desc',
            ], $filters))
            ->throw()
            ->json();
    }

    public function createSubscription(array $values): array
    {
        return $this->insert('subscriptions', $values);
    }

    public function updateSubscription(string $subscriptionId, array $values): array
    {
        return $this->patchById('subscriptions', $subscriptionId, $values);
    }

    public function grantEntitlements(string $subscriptionId): int
    {
        return (int) $this->rpc('grant_entitlements', [
            'subscription_uuid' => $subscriptionId,
        ]);
    }

    public function verifyEntitlement(string $userId, string $featureKey): bool
    {
        return (bool) $this->rpc('verify_entitlement', [
            'user_uuid' => $userId,
            'feature' => $featureKey,
        ]);
    }

    public function payments(array $filters = []): array
    {
        return $this->rest()
            ->get($this->endpoint('payments'), array_merge([
                'order' => 'created_at.desc',
            ], $filters))
            ->throw()
            ->json();
    }

    public function paymentByReference(string $providerReference): ?array
    {
        $rows = $this->rest()
            ->get($this->endpoint('payments'), [
                'provider_reference' => "eq.$providerReference",
                'limit' => 1,
            ])
            ->throw()
            ->json();

        return $rows[0] ?? null;
    }

    public function updatePaymentStatus(string $paymentId, string $status, array $metadata = []): array
    {
        return $this->patchById('payments', $paymentId, [
            'status' => $status,
            'metadata' => $metadata,
        ]);
    }

    public function markPaymentSuccessfulByReference(
        string $providerReference,
        string $providerStatus,
        ?float $providerFee,
        array $metadata = []
    ): array {
        $existingMetadata = $this->existingPaymentMetadata($providerReference);
        $payload = [
            'status' => 'successful',
            'provider_status' => $providerStatus,
            'verified_at' => now()->toISOString(),
            'metadata' => array_merge($existingMetadata, $metadata, [
                'verified_by' => 'laravel_paystack_webhook',
            ]),
        ];

        if ($providerFee !== null) {
            $payload['provider_fee'] = $providerFee;
        }

        return $this->patchByProviderReference($providerReference, $payload);
    }

    public function markPaymentFailedByReference(
        string $providerReference,
        string $providerStatus,
        array $metadata = []
    ): array {
        $existingMetadata = $this->existingPaymentMetadata($providerReference);

        return $this->patchByProviderReference($providerReference, [
            'status' => 'failed',
            'provider_status' => $providerStatus,
            'metadata' => array_merge($existingMetadata, $metadata, [
                'verified_by' => 'laravel_paystack_webhook',
            ]),
        ]);
    }

    public function approvePaidProgram(string $programId): array
    {
        return $this->patchById('paid_programs', $programId, [
            'status' => 'active',
        ]);
    }

    public function setCoachCommission(
        string $helperId,
        float $commissionValue,
        string $commissionType = 'percentage'
    ): array {
        return $this->insert('coach_commissions', [
            'helper_id' => $helperId,
            'commission_type' => $commissionType,
            'commission_value' => $commissionValue,
            'is_active' => true,
        ]);
    }

    public function createPayoutBatch(string $helperId, string $periodStart, string $periodEnd): string
    {
        return (string) $this->rpc('create_payout_batch', [
            'helper_uuid' => $helperId,
            'start_date' => $periodStart,
            'end_date' => $periodEnd,
        ]);
    }

    public function markEarningAvailable(string $earningId): void
    {
        $this->rpc('mark_earning_available', [
            'earning_uuid' => $earningId,
        ]);
    }

    public function revenueSummary(): array
    {
        $revenue = $this->rest()
            ->get($this->endpoint('admin_revenue_summary'), ['limit' => 1])
            ->throw()
            ->json();
        $mrr = $this->rest()
            ->get($this->endpoint('admin_mrr_summary'), ['limit' => 1])
            ->throw()
            ->json();

        return [
            'revenue' => $revenue[0] ?? [],
            'mrr' => $mrr[0] ?? [],
        ];
    }

    public function paywallConversion(): array
    {
        return $this->rest()
            ->get($this->endpoint('admin_paywall_conversion'), [
                'order' => 'views.desc',
            ])
            ->throw()
            ->json();
    }

    public function coachEarnings(array $filters = []): array
    {
        return $this->rest()
            ->get($this->endpoint('coach_earnings'), array_merge([
                'order' => 'created_at.desc',
            ], $filters))
            ->throw()
            ->json();
    }

    public function coachPayouts(array $filters = []): array
    {
        return $this->rest()
            ->get($this->endpoint('coach_payouts'), array_merge([
                'order' => 'created_at.desc',
            ], $filters))
            ->throw()
            ->json();
    }

    public function listRows(string $table, array $filters = []): array
    {
        return $this->rest()
            ->get($this->endpoint($table), $filters)
            ->throw()
            ->json();
    }

    public function firstBy(string $table, array $filters): ?array
    {
        $rows = $this->listRows($table, array_merge($filters, ['limit' => 1]));

        return $rows[0] ?? null;
    }

    public function viewRows(string $view, int $limit = 250): array
    {
        return $this->listRows($view, ['limit' => $limit]);
    }

    public function countTable(string $table, array $filters = []): int
    {
        $response = $this->rest()
            ->withHeaders(['Prefer' => 'count=exact'])
            ->get($this->endpoint($table), array_merge($filters, [
                'select' => 'id',
                'limit' => 1,
            ]));

        $response->throw();
        $range = (string) $response->header('content-range');
        if (! str_contains($range, '/')) {
            return 0;
        }

        return (int) substr($range, strrpos($range, '/') + 1);
    }

    public function globalSearch(string $term): array
    {
        $needle = '%' . trim($term) . '%';

        $targets = [
            'users' => ['table' => 'profiles', 'query' => ['or' => "full_name.ilike.$needle,username.ilike.$needle,email.ilike.$needle", 'limit' => 15]],
            'groups' => ['table' => 'groups', 'query' => ['or' => "name.ilike.$needle,description.ilike.$needle", 'limit' => 15]],
            'organizations' => ['table' => 'organizations', 'query' => ['or' => "name.ilike.$needle,slug.ilike.$needle", 'limit' => 15]],
            'helpers' => ['table' => 'helpers', 'query' => ['or' => "display_name.ilike.$needle,bio.ilike.$needle", 'limit' => 15]],
            'posts' => ['table' => 'community_posts', 'query' => ['or' => "title.ilike.$needle,body.ilike.$needle", 'limit' => 15]],
            'prayer_requests' => ['table' => 'prayer_requests', 'query' => ['or' => "title.ilike.$needle,body.ilike.$needle", 'limit' => 15]],
            'payments' => ['table' => 'payments', 'query' => ['or' => "provider_reference.ilike.$needle,status.ilike.$needle", 'limit' => 15]],
            'subscriptions' => ['table' => 'subscriptions', 'query' => ['or' => "provider_subscription_id.ilike.$needle,status.ilike.$needle", 'limit' => 15]],
            'reports' => ['table' => 'reports', 'query' => ['or' => "reason.ilike.$needle,target_type.ilike.$needle", 'limit' => 15]],
            'programs' => ['table' => 'paid_programs', 'query' => ['or' => "title.ilike.$needle,slug.ilike.$needle", 'limit' => 15]],
        ];

        $result = [];
        foreach ($targets as $key => $target) {
            $result[$key] = $this->listRows($target['table'], $target['query']);
        }

        return $result;
    }

    public function insert(string $table, array $values): array
    {
        return $this->rest()
            ->post($this->endpoint($table), $values)
            ->throw()
            ->json();
    }

    public function patchById(string $table, string $id, array $values): array
    {
        return $this->rest()
            ->patch($this->endpoint($table, ['id' => "eq.$id"]), $values)
            ->throw()
            ->json();
    }

    public function updateByFilters(string $table, array $filters, array $values): array
    {
        return $this->rest()
            ->patch($this->endpoint($table, $filters), $values)
            ->throw()
            ->json();
    }

    public function upsertByFilters(string $table, array $filters, array $values): array
    {
        $existing = $this->firstBy($table, $filters);
        if (is_array($existing) && isset($existing['id'])) {
            return $this->patchById($table, (string) $existing['id'], $values);
        }

        return $this->insert($table, $values);
    }

    private function patchByProviderReference(string $reference, array $values): array
    {
        return $this->rest()
            ->patch($this->endpoint('payments', [
                'provider_reference' => "eq.$reference",
            ]), $values)
            ->throw()
            ->json();
    }

    private function existingPaymentMetadata(string $providerReference): array
    {
        $payment = $this->paymentByReference($providerReference);
        $metadata = $payment['metadata'] ?? [];

        return is_array($metadata) ? $metadata : [];
    }

    private function rpc(string $function, array $values): mixed
    {
        return $this->rest()
            ->post($this->rpcEndpoint($function), $values)
            ->throw()
            ->json();
    }

    private function rest(): PendingRequest
    {
        $key = $this->serviceRoleKey
            ?? config('services.supabase.service_role_key')
            ?? env('SUPABASE_SERVICE_ROLE_KEY');

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

    private function rpcEndpoint(string $function): string
    {
        return "{$this->baseUrl()}/rest/v1/rpc/{$function}";
    }

    private function baseUrl(): string
    {
        return rtrim($this->url ?? config('services.supabase.url') ?? env('SUPABASE_URL'), '/');
    }
}

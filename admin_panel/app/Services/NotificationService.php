<?php

namespace App\Services;

use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Http;

class NotificationService
{
    public function createNotification(
        string $userId,
        string $type,
        string $title,
        ?string $body = null,
        array $data = [],
        string $priority = 'normal'
    ): ?string {
        return $this->rpc('create_notification', [
            'target_user_id' => $userId,
            'notification_type' => $type,
            'notification_title' => $title,
            'notification_body' => $body,
            'notification_data' => $data,
            'notification_priority' => $priority,
        ]);
    }

    public function createBulkNotifications(
        array $userIds,
        string $type,
        string $title,
        ?string $body = null,
        array $data = [],
        string $priority = 'normal'
    ): array {
        $created = [];

        foreach (array_unique($userIds) as $userId) {
            $created[] = $this->createNotification(
                $userId,
                $type,
                $title,
                $body,
                $data,
                $priority
            );
        }

        return array_values(array_filter($created));
    }

    public function sendSystemAnnouncement(
        string $title,
        string $body,
        array $data = [],
        string $priority = 'normal'
    ): array {
        $users = $this->rest()
            ->get($this->endpoint('profiles'), [
                'select' => 'user_id',
                'status' => 'eq.active',
            ])
            ->throw()
            ->json();

        return $this->createBulkNotifications(
            array_column($users, 'user_id'),
            'system',
            $title,
            $body,
            array_merge($data, ['route' => $data['route'] ?? 'notifications']),
            $priority
        );
    }

    public function sendChurchAnnouncement(
        string $organizationId,
        string $title,
        string $body,
        array $data = []
    ): array {
        $members = $this->rest()
            ->get($this->endpoint('organization_members'), [
                'select' => 'user_id',
                'organization_id' => "eq.$organizationId",
                'status' => 'eq.approved',
            ])
            ->throw()
            ->json();

        return $this->createBulkNotifications(
            array_column($members, 'user_id'),
            'church_announcement',
            $title,
            $body,
            array_merge($data, [
                'organization_id' => $organizationId,
                'route' => $data['route'] ?? 'church_announcement',
            ]),
            'normal'
        );
    }

    public function retryFailedPush(string $deliveryLogId): array
    {
        $rows = $this->rest()
            ->get($this->endpoint('notification_delivery_logs'), [
                'id' => "eq.$deliveryLogId",
                'status' => 'eq.failed',
                'select' => 'notification_id',
                'limit' => 1,
            ])
            ->throw()
            ->json();

        $notificationId = $rows[0]['notification_id'] ?? null;
        if (! is_string($notificationId)) {
            return ['retried' => false, 'reason' => 'Failed delivery log not found.'];
        }

        return $this->invokeFunction('process-notification', [
            'notification_id' => $notificationId,
        ]);
    }

    public function getDeliveryLogs(array $filters = []): array
    {
        return $this->rest()
            ->get($this->endpoint('notification_delivery_logs'), array_merge([
                'order' => 'created_at.desc',
            ], $filters))
            ->throw()
            ->json();
    }

    public function notificationAnalytics(): array
    {
        return [
            'delivery' => $this->view('notification_delivery_summary'),
            'engagement' => $this->view('notification_engagement_summary'),
            'failed_push' => $this->view('failed_push_notifications'),
        ];
    }

    private function view(string $view): array
    {
        return $this->rest()
            ->get($this->endpoint($view))
            ->throw()
            ->json();
    }

    private function rpc(string $function, array $values): mixed
    {
        return $this->rest()
            ->post($this->rpcEndpoint($function), $values)
            ->throw()
            ->json();
    }

    private function invokeFunction(string $function, array $values): array
    {
        return Http::withToken($this->serviceRoleKey())
            ->acceptJson()
            ->post("{$this->baseUrl()}/functions/v1/{$function}", $values)
            ->throw()
            ->json();
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

    private function rpcEndpoint(string $function): string
    {
        return "{$this->baseUrl()}/rest/v1/rpc/{$function}";
    }

    private function baseUrl(): string
    {
        return rtrim(config('services.supabase.url') ?? env('SUPABASE_URL'), '/');
    }

    private function serviceRoleKey(): string
    {
        return config('services.supabase.service_role_key')
            ?? env('SUPABASE_SERVICE_ROLE_KEY');
    }
}

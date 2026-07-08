<?php

namespace App\Services;

use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Http;

class ChatModerationService
{
    public function conversations(array $filters = []): array
    {
        return $this->rest()
            ->get($this->endpoint('chat_conversations'), array_merge([
                'select' => '*',
                'order' => 'updated_at.desc',
            ], $filters))
            ->throw()
            ->json();
    }

    public function conversation(string $conversationId): ?array
    {
        $rows = $this->rest()
            ->get($this->endpoint('chat_conversations'), [
                'id' => "eq.$conversationId",
                'select' => '*',
                'limit' => 1,
            ])
            ->throw()
            ->json();

        return $rows[0] ?? null;
    }

    public function messages(string $conversationId, int $limit = 100): array
    {
        return $this->rest()
            ->get($this->endpoint('chat_messages'), [
                'conversation_id' => "eq.$conversationId",
                'order' => 'created_at.desc',
                'limit' => min(max($limit, 1), 500),
            ])
            ->throw()
            ->json();
    }

    public function participants(string $conversationId): array
    {
        return $this->rest()
            ->get($this->endpoint('chat_participants'), [
                'conversation_id' => "eq.$conversationId",
                'order' => 'joined_at.asc',
            ])
            ->throw()
            ->json();
    }

    public function hideMessage(string $messageId, string $adminId, ?string $reason = null): array
    {
        $message = $this->patchById('chat_messages', $messageId, [
            'status' => 'hidden',
            'metadata' => [
                'moderation_action' => 'hidden',
                'moderated_by' => $adminId,
                'moderation_reason' => $reason,
                'moderated_at' => now()->toISOString(),
            ],
        ]);

        $this->createModerationReport($adminId, 'chat_message', $messageId, $reason ?? 'Hidden by moderator');

        return $message;
    }

    public function restoreMessage(string $messageId, string $adminId): array
    {
        return $this->patchById('chat_messages', $messageId, [
            'status' => 'active',
            'metadata' => [
                'moderation_action' => 'restored',
                'moderated_by' => $adminId,
                'moderated_at' => now()->toISOString(),
            ],
        ]);
    }

    public function softDeleteRecording(string $recordingId, string $adminId, ?string $reason = null): array
    {
        $recording = $this->patchById('chat_recordings', $recordingId, [
            'status' => 'deleted',
            'transcript' => null,
        ]);

        $this->createModerationReport($adminId, 'chat_recording', $recordingId, $reason ?? 'Recording removed by moderator');

        return $recording;
    }

    public function flagConversation(string $conversationId, string $adminId, ?string $reason = null): array
    {
        $conversation = $this->patchById('chat_conversations', $conversationId, [
            'status' => 'pending_review',
        ]);

        $this->createModerationReport($adminId, 'chat_conversation', $conversationId, $reason ?? 'Conversation flagged for review');

        return $conversation;
    }

    public function closeConversation(string $conversationId): array
    {
        return $this->patchById('chat_conversations', $conversationId, [
            'status' => 'closed',
        ]);
    }

    public function addParticipant(
        string $conversationId,
        string $userId,
        string $role = 'member'
    ): array {
        return $this->insert('chat_participants', [
            'conversation_id' => $conversationId,
            'user_id' => $userId,
            'role' => $role,
            'status' => 'active',
        ]);
    }

    public function updateParticipantStatus(
        string $conversationId,
        string $userId,
        string $status
    ): array {
        return $this->rest()
            ->patch($this->endpoint('chat_participants', [
                'conversation_id' => "eq.$conversationId",
                'user_id' => "eq.$userId",
            ]), [
                'status' => $status,
            ])
            ->throw()
            ->json();
    }

    public function createSupportConversation(string $supportRequestId): string
    {
        return (string) $this->rpc('get_or_create_support_chat', [
            'support_request_uuid' => $supportRequestId,
        ]);
    }

    public function conversationRecordings(string $conversationId): array
    {
        return $this->rest()
            ->get($this->endpoint('chat_recordings'), [
                'conversation_id' => "eq.$conversationId",
                'order' => 'created_at.desc',
            ])
            ->throw()
            ->json();
    }

    public function cleanupDeletedFiles(bool $dryRun = false, int $limit = 100): array
    {
        return $this->invokeFunction('cleanup-deleted-chat-files', [
            'dryRun' => $dryRun,
            'limit' => $limit,
        ]);
    }

    public function moderationDashboard(): array
    {
        return [
            'flagged_conversations' => $this->conversations([
                'status' => 'eq.pending_review',
            ]),
            'hidden_messages' => $this->rest()
                ->get($this->endpoint('chat_messages'), [
                    'status' => 'eq.hidden',
                    'order' => 'updated_at.desc',
                    'limit' => 100,
                ])
                ->throw()
                ->json(),
            'hidden_recordings' => $this->rest()
                ->get($this->endpoint('chat_recordings'), [
                    'status' => 'in.(hidden,deleted)',
                    'order' => 'updated_at.desc',
                    'limit' => 100,
                ])
                ->throw()
                ->json(),
        ];
    }

    private function createModerationReport(
        string $adminId,
        string $targetType,
        string $targetId,
        string $reason
    ): void {
        $this->insert('reports', [
            'reporter_id' => $adminId,
            'target_type' => $targetType,
            'target_id' => $targetId,
            'reason' => $reason,
            'status' => 'resolved',
            'reviewed_by' => $adminId,
            'reviewed_at' => now()->toISOString(),
        ]);
    }

    private function insert(string $table, array $values): array
    {
        return $this->rest()
            ->post($this->endpoint($table), $values)
            ->throw()
            ->json();
    }

    private function patchById(string $table, string $id, array $values): array
    {
        return $this->rest()
            ->patch($this->endpoint($table, ['id' => "eq.$id"]), $values)
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

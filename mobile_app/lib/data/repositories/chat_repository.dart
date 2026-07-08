import '../models/group_message.dart';
import 'supabase_repository.dart';

class ChatRepository extends SupabaseRepository {
  const ChatRepository({super.supabaseClient});

  Future<List<GroupMessage>> messages(String groupId) {
    return guard(() async {
      final rows = await client
          .from('group_messages')
          .select()
          .eq('group_id', groupId)
          .order('created_at');
      return mapRows(rows, GroupMessage.fromMap);
    });
  }

  Stream<List<GroupMessage>> messagesStream(String groupId) {
    return client
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at')
        .map((rows) => mapRows(rows, GroupMessage.fromMap));
  }

  Future<GroupMessage> sendMessage({
    required String groupId,
    required String senderId,
    required String message,
    bool isAnonymous = false,
  }) {
    return guard(() async {
      final row = await client
          .from('group_messages')
          .insert({
            'group_id': groupId,
            'sender_id': senderId,
            'message': message,
            'is_anonymous': isAnonymous,
          })
          .select()
          .single();
      return GroupMessage.fromMap(mapRow(row));
    });
  }
}

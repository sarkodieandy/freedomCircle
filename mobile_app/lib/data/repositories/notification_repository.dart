import '../models/notification_item.dart';
import 'supabase_repository.dart';

class NotificationRepository extends SupabaseRepository {
  const NotificationRepository({super.supabaseClient});

  Future<List<NotificationItem>> notifications(String userId) {
    return guard(() async {
      final rows = await client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return mapRows(rows, NotificationItem.fromMap);
    });
  }

  Stream<List<NotificationItem>> notificationsStream(String userId) {
    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => mapRows(rows, NotificationItem.fromMap));
  }

  Future<void> markRead(String notificationId) {
    return guard(() async {
      await client
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);
    });
  }
}

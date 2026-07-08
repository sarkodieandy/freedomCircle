import '../models/notification_item.dart';
import '../models/notification_preferences.dart';
import '../supabase/supabase_service.dart';
import 'supabase_repository.dart';

class NotificationRepository extends SupabaseRepository {
  const NotificationRepository({super.supabaseClient});

  String? get _currentUserId => SupabaseService.currentUser?.id;

  Future<List<NotificationItem>> getNotifications() {
    if (!SupabaseService.isInitialized || _currentUserId == null) {
      return Future.value(const []);
    }

    return guard(() async {
      final rows = await client
          .from('notifications')
          .select()
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false);
      return mapRows(rows, NotificationItem.fromMap);
    });
  }

  Future<int> getUnreadCount() {
    if (!SupabaseService.isInitialized || _currentUserId == null) {
      return Future.value(0);
    }

    return guard(() async {
      final value = await client.rpc('get_unread_notification_count');
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    });
  }

  Stream<List<NotificationItem>> listenToNotifications() {
    if (!SupabaseService.isInitialized || _currentUserId == null) {
      return Stream.value(const []);
    }

    final userId = _currentUserId!;
    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => mapRows(rows, NotificationItem.fromMap));
  }

  Stream<int> listenToUnreadCount() {
    return listenToNotifications().map(
      (items) => items.where((item) => item.isUnread).length,
    );
  }

  Future<void> markAsRead(String notificationId) {
    if (!SupabaseService.isInitialized || _currentUserId == null) {
      return Future.value();
    }

    return guard(() async {
      await client.rpc(
        'mark_notification_read',
        params: {'notification_uuid': notificationId},
      );
    });
  }

  Future<void> markAllAsRead() {
    if (!SupabaseService.isInitialized || _currentUserId == null) {
      return Future.value();
    }

    return guard(() async {
      await client.rpc('mark_all_notifications_read');
    });
  }

  Future<void> deleteNotification(String notificationId) {
    if (!SupabaseService.isInitialized || _currentUserId == null) {
      return Future.value();
    }

    return guard(() async {
      await client.from('notifications').delete().eq('id', notificationId);
    });
  }

  Future<NotificationPreferences> getPreferences() {
    final userId = _currentUserId;
    if (!SupabaseService.isInitialized || userId == null) {
      return Future.value(NotificationPreferences.defaults(userId ?? ''));
    }

    return guard(() async {
      final row = await client
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) {
        final defaults = NotificationPreferences.defaults(userId);
        await updatePreferences(defaults);
        return defaults;
      }
      return NotificationPreferences.fromMap(mapRow(row));
    });
  }

  Future<void> updatePreferences(NotificationPreferences preferences) {
    if (!SupabaseService.isInitialized || _currentUserId == null) {
      return Future.value();
    }

    return guard(() async {
      await client
          .from('notification_preferences')
          .upsert(preferences.toMap(), onConflict: 'user_id');
    });
  }

  Future<void> registerPushToken(
    String token,
    String platform,
    String deviceId,
  ) {
    final userId = _currentUserId;
    if (!SupabaseService.isInitialized || userId == null || token.isEmpty) {
      return Future.value();
    }

    return guard(() async {
      await client.from('user_push_tokens').upsert({
        'user_id': userId,
        'device_id': deviceId,
        'platform': platform,
        'push_token': token,
        'provider': platform == 'ios' ? 'apns' : 'fcm',
        'is_active': true,
        'last_seen_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,device_id');
    });
  }

  Future<void> deactivatePushToken(String deviceId) {
    final userId = _currentUserId;
    if (!SupabaseService.isInitialized || userId == null) {
      return Future.value();
    }

    return guard(() async {
      await client
          .from('user_push_tokens')
          .update({
            'is_active': false,
            'last_seen_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('device_id', deviceId);
    });
  }

  Future<List<NotificationItem>> notifications(String userId) {
    return getNotifications();
  }

  Stream<List<NotificationItem>> notificationsStream(String userId) {
    return listenToNotifications();
  }
}

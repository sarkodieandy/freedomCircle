import 'model_helpers.dart';

class NotificationPreferences {
  const NotificationPreferences({
    required this.userId,
    this.id = '',
    this.groupMessages = true,
    this.prayerRequests = true,
    this.communityReplies = true,
    this.helperMessages = true,
    this.bookingUpdates = true,
    this.recoveryReminders = true,
    this.quietTimeReminders = true,
    this.fastingReminders = true,
    this.subscriptionAlerts = true,
    this.churchAnnouncements = true,
    this.pushEnabled = true,
    this.emailEnabled = false,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  final String id;
  final String userId;
  final bool groupMessages;
  final bool prayerRequests;
  final bool communityReplies;
  final bool helperMessages;
  final bool bookingUpdates;
  final bool recoveryReminders;
  final bool quietTimeReminders;
  final bool fastingReminders;
  final bool subscriptionAlerts;
  final bool churchAnnouncements;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool quietHoursEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;

  NotificationPreferences copyWith({
    bool? groupMessages,
    bool? prayerRequests,
    bool? communityReplies,
    bool? helperMessages,
    bool? bookingUpdates,
    bool? recoveryReminders,
    bool? quietTimeReminders,
    bool? fastingReminders,
    bool? subscriptionAlerts,
    bool? churchAnnouncements,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationPreferences(
      id: id,
      userId: userId,
      groupMessages: groupMessages ?? this.groupMessages,
      prayerRequests: prayerRequests ?? this.prayerRequests,
      communityReplies: communityReplies ?? this.communityReplies,
      helperMessages: helperMessages ?? this.helperMessages,
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      recoveryReminders: recoveryReminders ?? this.recoveryReminders,
      quietTimeReminders: quietTimeReminders ?? this.quietTimeReminders,
      fastingReminders: fastingReminders ?? this.fastingReminders,
      subscriptionAlerts: subscriptionAlerts ?? this.subscriptionAlerts,
      churchAnnouncements: churchAnnouncements ?? this.churchAnnouncements,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }

  JsonMap toMap() {
    return {
      'user_id': userId,
      'group_messages': groupMessages,
      'prayer_requests': prayerRequests,
      'community_replies': communityReplies,
      'helper_messages': helperMessages,
      'booking_updates': bookingUpdates,
      'recovery_reminders': recoveryReminders,
      'quiet_time_reminders': quietTimeReminders,
      'fasting_reminders': fastingReminders,
      'subscription_alerts': subscriptionAlerts,
      'church_announcements': churchAnnouncements,
      'push_enabled': pushEnabled,
      'email_enabled': emailEnabled,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
    };
  }

  factory NotificationPreferences.defaults(String userId) {
    return NotificationPreferences(userId: userId);
  }

  factory NotificationPreferences.fromMap(JsonMap map) {
    return NotificationPreferences(
      id: readString(map, 'id'),
      userId: readString(map, 'user_id'),
      groupMessages: readBool(map, 'group_messages', fallback: true),
      prayerRequests: readBool(map, 'prayer_requests', fallback: true),
      communityReplies: readBool(map, 'community_replies', fallback: true),
      helperMessages: readBool(map, 'helper_messages', fallback: true),
      bookingUpdates: readBool(map, 'booking_updates', fallback: true),
      recoveryReminders: readBool(map, 'recovery_reminders', fallback: true),
      quietTimeReminders: readBool(map, 'quiet_time_reminders', fallback: true),
      fastingReminders: readBool(map, 'fasting_reminders', fallback: true),
      subscriptionAlerts: readBool(map, 'subscription_alerts', fallback: true),
      churchAnnouncements: readBool(
        map,
        'church_announcements',
        fallback: true,
      ),
      pushEnabled: readBool(map, 'push_enabled', fallback: true),
      emailEnabled: readBool(map, 'email_enabled'),
      quietHoursEnabled: readBool(map, 'quiet_hours_enabled'),
      quietHoursStart: readNullableString(map, 'quiet_hours_start'),
      quietHoursEnd: readNullableString(map, 'quiet_hours_end'),
    );
  }
}

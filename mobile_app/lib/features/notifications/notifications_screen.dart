import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/notification_item.dart';
import '../../data/repositories/notification_repository.dart';
import '../chat/chat_list_screen.dart';
import '../chat/chat_screen.dart';
import '../community/community_wall_screen.dart';
import '../groups/groups_screen.dart';
import '../helpers/coach_directory_screen.dart';
import '../monetization/paid_program_detail_screen.dart';
import '../monetization/subscription_management_screen.dart';
import '../prayer/prayer_wall_screen.dart';
import '../quiet_time/quiet_time_home_screen.dart';
import '../recovery/recovery_tracker_screen.dart';
import '../safety/safety_screen.dart';
import 'notification_detail_screen.dart';
import 'notification_preferences_screen.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_empty_state.dart';
import 'widgets/notification_filter_chip.dart';

enum _NotificationFilter { all, unread, prayers, groups, helper, billing }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _repository = const NotificationRepository();
  _NotificationFilter _filter = _NotificationFilter.all;

  Future<void> _refresh() async {
    await _repository.getNotifications();
    if (mounted) setState(() {});
  }

  Future<void> _markAllRead() async {
    await _repository.markAllAsRead();
  }

  Future<void> _openNotification(NotificationItem item) async {
    if (item.isUnread) {
      await _repository.markAsRead(item.id);
    }
    if (!mounted) return;

    final route = item.stringData('route');
    final conversationId = item.stringData('conversation_id');
    if (conversationId != null) {
      pushScreen(
        context,
        ChatScreen(
          conversationId: conversationId,
          title: item.stringData('title') ?? 'Chat',
          groupId: item.stringData('group_id'),
        ),
      );
      return;
    }
    if (item.stringData('message_id') != null &&
        item.stringData('group_id') != null) {
      pushScreen(context, const ChatListScreen());
      return;
    }
    if (route == 'group_chat') {
      pushScreen(context, const ChatListScreen());
      return;
    }
    if (route == 'group_detail' || item.stringData('group_id') != null) {
      pushScreen(context, const GroupsScreen());
      return;
    }
    if (route == 'prayer_detail' ||
        route == 'group_prayer' ||
        item.stringData('prayer_request_id') != null) {
      pushScreen(context, const PrayerWallScreen());
      return;
    }
    if (route == 'community_post' || item.stringData('post_id') != null) {
      pushScreen(context, const CommunityWallScreen());
      return;
    }
    if (route == 'booking_detail' ||
        route == 'support_request' ||
        item.stringData('helper_id') != null) {
      pushScreen(context, const CoachDirectoryScreen());
      return;
    }
    if (route == 'subscription' || route == 'payments') {
      pushScreen(context, const SubscriptionManagementScreen());
      return;
    }
    if (item.stringData('program_id') != null) {
      pushScreen(context, const PaidProgramDetailScreen());
      return;
    }
    if (route == 'safety' || item.stringData('report_id') != null) {
      pushScreen(context, const SafetyScreen());
      return;
    }
    if (route == 'recovery_tracker') {
      pushScreen(context, const RecoveryTrackerScreen());
      return;
    }
    if (route == 'quiet_time') {
      pushScreen(context, const QuietTimeHomeScreen());
      return;
    }

    pushScreen(context, NotificationDetailScreen(notification: item));
  }

  List<NotificationItem> _applyFilter(List<NotificationItem> items) {
    return switch (_filter) {
      _NotificationFilter.all => items,
      _NotificationFilter.unread =>
        items.where((item) => item.isUnread).toList(),
      _NotificationFilter.prayers =>
        items.where((item) => item.type.contains('prayer')).toList(),
      _NotificationFilter.groups =>
        items.where((item) => item.type.contains('group')).toList(),
      _NotificationFilter.helper =>
        items
            .where(
              (item) =>
                  item.type.contains('helper') || item.type.contains('booking'),
            )
            .toList(),
      _NotificationFilter.billing =>
        items
            .where(
              (item) =>
                  item.type.contains('payment') ||
                  item.type.contains('subscription'),
            )
            .toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Notifications',
      subtitle: 'Prayer, group activity, helper updates, and account alerts.',
      withBack: true,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () =>
                pushScreen(context, const NotificationPreferencesScreen()),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Preferences'),
          ),
        ),
        StreamBuilder<int>(
          stream: _repository.listenToUnreadCount(),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Row(
              children: [
                Expanded(
                  child: Text(
                    count == 0
                        ? 'You are caught up.'
                        : '$count unread update${count == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: count == 0 ? null : _markAllRead,
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text('Mark all read'),
                ),
              ],
            );
          },
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('All', _NotificationFilter.all),
              _filterChip('Unread', _NotificationFilter.unread),
              _filterChip('Prayer', _NotificationFilter.prayers),
              _filterChip('Groups', _NotificationFilter.groups),
              _filterChip('Helpers', _NotificationFilter.helper),
              _filterChip('Billing', _NotificationFilter.billing),
            ],
          ),
        ),
        StreamBuilder<List<NotificationItem>>(
          stream: _repository.listenToNotifications(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorRetryCard(
                title: 'Could not load notifications',
                body: snapshot.error.toString(),
                onRetry: () => setState(() {}),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _NotificationLoadingList();
            }

            final notifications = _applyFilter(snapshot.data ?? const []);
            if (notifications.isEmpty) {
              return NotificationEmptyState(onRefresh: _refresh);
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                children: _buildGroupedNotifications(notifications),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _filterChip(String label, _NotificationFilter filter) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: NotificationFilterChip(
        label: label,
        selected: _filter == filter,
        onSelected: (_) => setState(() => _filter = filter),
      ),
    );
  }

  List<Widget> _buildGroupedNotifications(List<NotificationItem> items) {
    final groups = <String, List<NotificationItem>>{
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    for (final item in items) {
      groups[_sectionFor(item.createdAt)]!.add(item);
    }

    return [
      for (final entry in groups.entries)
        if (entry.value.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 10),
            child: SectionHeader(title: entry.key),
          ),
          for (final item in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NotificationCard(
                notification: item,
                onTap: () => _openNotification(item),
                onMarkRead: () => _repository.markAsRead(item.id),
                onDelete: () => _repository.deleteNotification(item.id),
              ),
            ),
        ],
    ];
  }

  String _sectionFor(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target == today) return 'Today';
    if (target == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return 'Earlier';
  }
}

class _NotificationLoadingList extends StatelessWidget {
  const _NotificationLoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          height: 88,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}

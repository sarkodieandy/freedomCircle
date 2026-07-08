import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/animations/fade_slide_in.dart';
import '../../data/models/accountability_group.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/remote_image.dart';
import '../chat/chat_screen.dart';
import '../checkin/daily_check_in_sheet.dart';
import '../prayer/prayer_request_card.dart';

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key, required this.group});

  final AccountabilityGroup group;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.navy,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(group.name),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    RemoteImage(
                      imageUrl: group.imageUrl,
                      borderRadius: BorderRadius.zero,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.navy.withValues(alpha: .34),
                      ),
                    ),
                  ],
                ),
              ),
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Chat'),
                  Tab(text: 'Prayer'),
                  Tab(text: 'Check-ins'),
                  Tab(text: 'Leaders'),
                  Tab(text: 'Resources'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _GroupChatTab(group: group),
              const _GroupPrayerTab(),
              _GroupCheckInTab(group: group),
              const _GroupLeaderboardTab(),
              const _GroupResourcesTab(),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: PrimaryButton(
              label: group.type == 'Public' ? 'Join circle' : 'Request access',
              icon: Icons.person_add_alt_1_rounded,
              onPressed: () => showComingSoon(context, 'Group access'),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupChatTab extends StatelessWidget {
  const _GroupChatTab({required this.group});

  final AccountabilityGroup group;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusBadge(
                    label: group.type,
                    color: group.isPremium ? AppColors.gold : AppColors.green,
                    icon: group.isPremium
                        ? Icons.workspace_premium_rounded
                        : Icons.lock_rounded,
                  ),
                  const Spacer(),
                  for (final avatar in const ['A', 'D', 'E'])
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.softGreen,
                        child: Text(
                          avatar,
                          style: const TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                group.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.rule_rounded, color: AppColors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Rules: be honest, protect privacy, avoid harmful advice, and report unsafe content.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          color: AppColors.softGreen,
          child: Row(
            children: [
              const Icon(Icons.push_pin_rounded, color: AppColors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Weekly prompt: What trigger do you want to prepare for before Friday?',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          color: AppColors.navy,
          child: Row(
            children: [
              const Icon(Icons.graphic_eq_rounded, color: AppColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Voice prayer room • Coming soon',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: 'Open full chat',
          icon: Icons.open_in_full_rounded,
          onPressed: () => pushScreen(context, const ChatScreen()),
        ),
        const SizedBox(height: 12),
        const _ChatBubble(
          author: 'Moderator',
          message:
              'Welcome, everyone. Keep posts respectful, specific, and prayerful.',
          isMe: false,
          isModerator: true,
        ),
        const _ChatBubble(
          author: 'Anonymous',
          message:
              'Checking in early today. I am avoiding late scrolling and choosing worship before bed.',
          isMe: false,
          isAnonymous: true,
        ),
        const _ChatBubble(
          author: 'You',
          message:
              'I am in. I will add a private log if the evening gets difficult.',
          isMe: true,
        ),
        const SizedBox(height: 10),
        Text(
          'Daniel is typing...',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: 'Write with kindness...',
            suffixIcon: IconButton(
              onPressed: () => showComingSoon(context, 'Send group message'),
              icon: const Icon(Icons.send_rounded),
            ),
            prefixIcon: IconButton(
              onPressed: () => showComingSoon(context, 'Quick prayer request'),
              icon: const Icon(Icons.volunteer_activism_rounded),
              tooltip: 'Prayer request',
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.author,
    required this.message,
    required this.isMe,
    this.isModerator = false,
    this.isAnonymous = false,
  });

  final String author;
  final String message;
  final bool isMe;
  final bool isModerator;
  final bool isAnonymous;

  @override
  Widget build(BuildContext context) {
    final color = isMe ? AppColors.green : AppColors.card;
    final textColor = isMe ? Colors.white : AppColors.navy;

    return FadeSlideIn(
      offset: Offset(isMe ? 16 : -16, 10),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 310),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 6),
              bottomRight: Radius.circular(isMe ? 6 : 20),
            ),
            boxShadow: isMe
                ? []
                : [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: .05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    author,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: textColor),
                  ),
                  if (isModerator)
                    const StatusBadge(
                      label: 'Moderator',
                      color: AppColors.gold,
                      icon: Icons.verified_rounded,
                    ),
                  if (isAnonymous)
                    const StatusBadge(
                      label: 'Anonymous',
                      color: AppColors.navy,
                      icon: Icons.visibility_off_rounded,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isMe ? Colors.white.withValues(alpha: .88) : null,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => showComingSoon(context, 'Message reporting'),
                  icon: Icon(
                    Icons.flag_outlined,
                    size: 18,
                    color: isMe
                        ? Colors.white.withValues(alpha: .74)
                        : AppColors.mutedText,
                  ),
                  tooltip: 'Report message',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupPrayerTab extends StatelessWidget {
  const _GroupPrayerTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: const [
        PrayerRequestCard(
          title: 'Strength for exams',
          body:
              'Pray that I can study consistently without panic or late-night distractions.',
          prayed: 28,
          isAnonymous: true,
        ),
        PrayerRequestCard(
          title: 'Family peace',
          body: 'Asking for wisdom and patience in a difficult conversation.',
          prayed: 19,
          isAnonymous: false,
          answered: true,
        ),
      ],
    );
  }
}

class _GroupCheckInTab extends StatelessWidget {
  const _GroupCheckInTab({required this.group});

  final AccountabilityGroup group;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly check-in progress',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              ProgressRing(
                progress: group.checkInRate,
                size: 120,
                color: AppColors.green,
                label: '${(group.checkInRate * 100).round()}%',
              ),
              const SizedBox(height: 14),
              Text(
                '${group.online} members are active right now. Presence and chat can use Supabase Realtime later.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Submit check-in',
          icon: Icons.check_circle_rounded,
          onPressed: () => showDailyCheckInSheet(context),
        ),
      ],
    );
  }
}

class _GroupLeaderboardTab extends StatelessWidget {
  const _GroupLeaderboardTab();

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Anonymous', '21 days', AppColors.gold),
      ('Kofi A.', '14 days', AppColors.green),
      ('You', '12 days', AppColors.support),
    ];

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: rows[i].$3.withValues(alpha: .16),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: rows[i].$3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      rows[i].$1,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    rows[i].$2,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _GroupResourcesTab extends StatelessWidget {
  const _GroupResourcesTab();

  @override
  Widget build(BuildContext context) {
    final resources = [
      ('Group rules', Icons.rule_rounded),
      ('21-day prayer plan', Icons.calendar_month_rounded),
      ('Scripture memory cards', Icons.style_rounded),
      ('Pastor note', Icons.campaign_rounded),
    ];

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        for (final resource in resources)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Row(
                children: [
                  Icon(resource.$2, color: AppColors.green),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      resource.$1,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

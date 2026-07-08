import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/screen_shell.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Group chat',
      subtitle: 'Safe messages, prayer requests, and moderator tools.',
      withBack: true,
      children: [
        AppCard(
          color: AppColors.softGreen,
          child: Row(
            children: const [
              Icon(Icons.push_pin_rounded, color: AppColors.green),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Weekly prompt: prepare one healthy response before Friday.',
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Voice prayer room preview • Coming soon',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
              StatusBadge(
                label: 'MVP',
                color: AppColors.gold,
                icon: Icons.auto_awesome_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Row(
            children: [
              for (final item in const ['A', 'D', 'E', 'K'])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.softGreen,
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '18 online • Daniel is typing...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _ChatPreviewBubble(
          author: 'Moderator',
          message: 'Keep messages honest, respectful, and privacy-safe.',
          badge: 'Moderator',
        ),
        const _ChatPreviewBubble(
          author: 'Anonymous',
          message:
              'I need prayer tonight. I am choosing to check in instead of hide.',
          badge: 'Anonymous',
        ),
        const _ChatPreviewBubble(
          author: 'Helper Daniel',
          message:
              'Proud of the honesty here. Write one next right step, not a full life plan.',
          badge: 'Helper',
        ),
        const SizedBox(height: 12),
        TextField(
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Write with kindness...',
            prefixIcon: IconButton(
              onPressed: () => showComingSoon(context, 'Chat attachment'),
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Attachment',
            ),
            suffixIcon: IconButton(
              onPressed: () => showComingSoon(context, 'Send chat message'),
              icon: const Icon(Icons.send_rounded),
              tooltip: 'Send',
            ),
          ),
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          label: 'Quick prayer request',
          icon: Icons.volunteer_activism_rounded,
          onPressed: () => showComingSoon(context, 'Quick prayer request'),
        ),
      ],
    );
  }
}

class _ChatPreviewBubble extends StatelessWidget {
  const _ChatPreviewBubble({
    required this.author,
    required this.message,
    required this.badge,
  });

  final String author;
  final String message;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(author, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                StatusBadge(
                  label: badge,
                  color: switch (badge) {
                    'Moderator' => AppColors.gold,
                    'Helper' => AppColors.green,
                    _ => AppColors.navy,
                  },
                  icon: switch (badge) {
                    'Moderator' => Icons.verified_rounded,
                    'Helper' => Icons.health_and_safety_rounded,
                    _ => Icons.visibility_off_rounded,
                  },
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => showComingSoon(context, 'Message reporting'),
                  icon: const Icon(Icons.flag_outlined),
                  tooltip: 'Report message',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

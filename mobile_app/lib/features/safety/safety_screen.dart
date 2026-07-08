import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/screen_shell.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Reports and safety',
      subtitle: 'Calm tools for reporting, blocking, and getting support.',
      withBack: true,
      children: [
        const SafetyNotice(
          icon: Icons.health_and_safety_rounded,
          text:
              'FreedomCircle provides support and accountability, not emergency care. For urgent safety concerns, contact local emergency services, a qualified professional, pastor, or trusted guardian.',
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report an issue',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'What are you reporting?',
                  prefixIcon: Icon(Icons.flag_rounded),
                ),
              ),
              const SizedBox(height: 12),
              const TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Add context',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Submit report',
                icon: Icons.flag_rounded,
                onPressed: () => showComingSoon(context, 'Safety report'),
                color: AppColors.support,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SafetyAction(
          icon: Icons.person_remove_rounded,
          title: 'Block user',
          body: 'Stop messages and hide future posts from a user.',
        ),
        const _SafetyAction(
          icon: Icons.support_agent_rounded,
          title: 'Contact support',
          body: 'Send a private note to the moderation team.',
        ),
        const _SafetyAction(
          icon: Icons.menu_book_rounded,
          title: 'Safety resources',
          body: 'Find local support, pastoral care, and trusted help options.',
        ),
      ],
    );
  }
}

class _SafetyAction extends StatelessWidget {
  const _SafetyAction({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.softGreen,
              child: Icon(icon, color: AppColors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(body, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

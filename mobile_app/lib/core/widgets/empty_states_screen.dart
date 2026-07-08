import 'package:flutter/material.dart';

import 'common_widgets.dart';
import 'screen_shell.dart';

class EmptyStatesScreen extends StatelessWidget {
  const EmptyStatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenShell(
      title: 'Empty states',
      subtitle: 'Calm screens for fresh accounts and errors.',
      withBack: true,
      children: [
        LoadingStateCard(),
        SizedBox(height: 14),
        ErrorRetryCard(
          title: 'Could not load group updates',
          body: 'Check your connection and try again.',
          onRetry: _noop,
        ),
        SizedBox(height: 14),
        OfflineNotice(),
        SizedBox(height: 14),
        EmptyStateCard(
          icon: Icons.groups_rounded,
          title: 'No groups joined yet',
          body: 'Find a circle that matches your season and privacy level.',
          action: 'Discover groups',
        ),
        EmptyStateCard(
          icon: Icons.track_changes_rounded,
          title: 'No recovery logs yet',
          body: 'Your first honest check-in will start the pattern.',
          action: 'Add check-in',
        ),
        EmptyStateCard(
          icon: Icons.volunteer_activism_rounded,
          title: 'No prayer requests yet',
          body: 'Ask quietly, anonymously, or inside a trusted group.',
          action: 'Request prayer',
        ),
        EmptyStateCard(
          icon: Icons.verified_user_rounded,
          title: 'No helper selected yet',
          body: 'Browse verified helpers when you want guided support.',
          action: 'Find helper',
        ),
        EmptyStateCard(
          icon: Icons.wifi_off_rounded,
          title: 'Connection paused',
          body: 'Your private drafts are safe. Try again when you are online.',
          action: 'Retry',
        ),
      ],
    );
  }
}

void _noop() {}

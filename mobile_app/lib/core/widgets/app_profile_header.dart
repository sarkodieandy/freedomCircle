import 'package:flutter/material.dart';

import '../../app/constants.dart';
import 'app_avatar.dart';
import 'app_badge.dart';
import 'app_card.dart';

class AppProfileHeader extends StatelessWidget {
  const AppProfileHeader({
    super.key,
    required this.name,
    required this.username,
    this.avatarUrl,
    this.isPremium = false,
    this.onSettings,
  });

  final String name;
  final String username;
  final String? avatarUrl;
  final bool isPremium;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.darkSurface,
      child: Row(
        children: [
          AppAvatar(imageUrl: avatarUrl, initials: 'FC', radius: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                Text(
                  username,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: .74),
                  ),
                ),
              ],
            ),
          ),
          if (isPremium)
            const StatusBadge(
              label: 'Premium',
              color: AppColors.gold,
              icon: Icons.workspace_premium_rounded,
            ),
          if (onSettings != null)
            IconButton(
              onPressed: onSettings,
              icon: const Icon(Icons.settings_rounded, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

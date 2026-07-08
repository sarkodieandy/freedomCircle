import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/screen_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Settings',
      subtitle: 'Account, privacy, notifications, and support preferences.',
      withBack: true,
      children: [
        const _SettingsSection(
          title: 'Account',
          items: [
            _SettingItem(
              Icons.person_rounded,
              'Account settings',
              'Name, username, church, country',
            ),
            _SettingItem(
              Icons.security_rounded,
              'Security',
              'Password, sessions, recovery email',
            ),
            _SettingItem(
              Icons.language_rounded,
              'Language',
              'English selected',
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _SettingsSection(
          title: 'Privacy',
          items: [
            _SettingItem(
              Icons.visibility_off_rounded,
              'Anonymous mode',
              'Use anonymous sharing by default',
            ),
            _SettingItem(
              Icons.lock_rounded,
              'Private tracking',
              'Recovery logs stay private unless shared',
            ),
            _SettingItem(
              Icons.block_rounded,
              'Blocked users',
              'Manage blocked accounts',
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _SettingsSection(
          title: 'Experience',
          items: [
            _SettingItem(
              Icons.notifications_rounded,
              'Notifications',
              'Prayer, groups, helpers, milestones',
            ),
            _SettingItem(
              Icons.palette_rounded,
              'Appearance',
              'Warm default theme',
            ),
            _SettingItem(
              Icons.help_rounded,
              'Help and support',
              'Safety, account, and billing support',
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monetization',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              SettingsTile(
                icon: Icons.workspace_premium_rounded,
                title: 'Subscription',
                subtitle: 'Current plan, restore purchases, billing history',
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.subscriptionManagement,
                ),
              ),
              SettingsTile(
                icon: Icons.church_rounded,
                title: 'Church plans',
                subtitle: 'Starter, Growth, Pro organization pricing',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.churchPlans),
              ),
              SettingsTile(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Coach earnings',
                subtitle: 'Gross, platform fee, net balance, payouts',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.coachEarnings),
              ),
              SettingsTile(
                icon: Icons.menu_book_rounded,
                title: 'Paid programs',
                subtitle: 'Guided challenges and premium-included plans',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.paidProgram),
              ),
              SettingsTile(
                icon: Icons.analytics_rounded,
                title: 'Revenue dashboard',
                subtitle: 'Admin preview for revenue and conversion',
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.revenueDashboard),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          color: AppColors.support.withValues(alpha: .08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showComingSoon(context, 'Logout'),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          showComingSoon(context, 'Delete account'),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.support,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});

  final String title;
  final List<_SettingItem> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          for (final item in items)
            SettingsTile(
              icon: item.icon,
              title: item.title,
              subtitle: item.subtitle,
              onTap: () => showComingSoon(context, item.title),
            ),
        ],
      ),
    );
  }
}

class _SettingItem {
  const _SettingItem(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}

import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../utils/app_logger.dart';
import 'app_card.dart';

class AppIconContainer extends StatelessWidget {
  const AppIconContainer({
    super.key,
    required this.icon,
    this.color = AppColors.green,
    this.size = 44,
    this.iconSize = 22,
    this.imageUrl,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: imageUrl == null ? color.withValues(alpha: .12) : AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.line),
      ),
      child: imageUrl == null
          ? Icon(icon, color: color, size: iconSize)
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(icon, color: color),
              ),
            ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.subtitle,
    this.leadingIcon,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final String? subtitle;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leadingIcon != null) ...[
          AppIconContainer(icon: leadingIcon!, size: 38, iconSize: 18),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.sectionTitle),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle!, style: AppTextStyles.body),
              ],
            ],
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class SafetyNotice extends StatelessWidget {
  const SafetyNotice({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.supportBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.support.withValues(alpha: .24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconContainer(
            icon: icon,
            color: AppColors.support,
            size: 36,
            iconSize: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectableOption extends StatelessWidget {
  const SelectableOption({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.iconUrl,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: selected ? AppColors.softGreen : AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: selected ? accent : AppColors.line,
          width: selected ? 1.2 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: onTap,
          leading: AppIconContainer(
            icon: icon,
            color: accent,
            imageUrl: iconUrl,
          ),
          title: Text(label, style: AppTextStyles.cardTitle),
          trailing: Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: selected ? accent : AppColors.line,
          ),
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.support : AppColors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            AppIconContainer(icon: icon, color: color, size: 46),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle),
                  Text(subtitle, style: AppTextStyles.body),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;

  @override
  Widget build(BuildContext context) {
    AppLogger.warning(
      'Empty state is shown',
      tag: 'UI',
      data: {'title': title, 'action': action},
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Column(
          children: [
            AppIconContainer(
              icon: icon,
              size: 68,
              iconSize: 30,
              color: AppColors.green,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => showComingSoon(context, action),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}

void showComingSoon(BuildContext context, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$label is ready for backend wiring.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class LoadingStateCard extends StatelessWidget {
  const LoadingStateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Loading gently', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: .35, end: 1),
                duration: Duration(milliseconds: 700 + i * 140),
                curve: Curves.easeInOut,
                builder: (context, value, child) =>
                    Opacity(opacity: value, child: child),
                child: Container(
                  height: i == 0 ? 18 : 13,
                  width: i == 0 ? 180 : 260 - (i * 44),
                  decoration: BoxDecoration(
                    color: AppColors.inkSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ErrorRetryCard extends StatelessWidget {
  const ErrorRetryCard({
    super.key,
    required this.title,
    required this.body,
    required this.onRetry,
  });

  final String title;
  final String body;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    AppLogger.error(
      'A screen failed to load',
      tag: 'UI',
      data: {'title': title, 'body': body},
    );
    return AppCard(
      color: AppColors.supportBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIconContainer(
            icon: Icons.error_outline_rounded,
            color: AppColors.support,
            size: 36,
            iconSize: 18,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OfflineNotice extends StatelessWidget {
  const OfflineNotice({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.warning('Network error happens', tag: 'UI');
    return AppCard(
      color: AppColors.navy,
      child: Row(
        children: [
          const AppIconContainer(
            icon: Icons.wifi_off_rounded,
            color: AppColors.gold,
            size: 36,
            iconSize: 18,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'You are offline. Private drafts stay on this device until connection returns.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: .78),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void pushScreen(BuildContext context, Widget screen) {
  AppLogger.navigation(
    'Button navigation tapped',
    data: {'screen': screen.runtimeType.toString()},
  );
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

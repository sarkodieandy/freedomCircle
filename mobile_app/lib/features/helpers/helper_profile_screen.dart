import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/images.dart';
import '../../data/models/helper_profile.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/remote_image.dart';
import '../../core/widgets/screen_shell.dart';
import 'booking_screen.dart';

class HelperProfileScreen extends StatelessWidget {
  const HelperProfileScreen({super.key, required this.helper});

  final HelperProfile helper;

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: helper.name,
      subtitle: helper.organization,
      withBack: true,
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 210,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: RemoteImage(
                        imageUrl: AppImages.mentor,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      bottom: 18,
                      child: CircleAvatar(
                        radius: 44,
                        backgroundImage: NetworkImage(helper.photoUrl),
                      ),
                    ),
                    const Positioned(
                      right: 18,
                      bottom: 18,
                      child: StatusBadge(
                        label: 'Verified',
                        color: AppColors.green,
                        icon: Icons.verified_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      helper.bio,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final area in helper.focusAreas)
                          SmallTag(label: area),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _InfoTile(
                          icon: Icons.payments_rounded,
                          label: helper.price,
                        ),
                        const SizedBox(width: 10),
                        _InfoTile(
                          icon: Icons.schedule_rounded,
                          label: helper.availability,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SafetyNotice(
          icon: Icons.health_and_safety_rounded,
          text:
              'Helpers provide support and accountability, not emergency care. For urgent harm risks, contact local emergency services, a qualified professional, pastor, or trusted guardian.',
        ),
        const SizedBox(height: 16),
        SectionHeader(title: 'Availability'),
        const SizedBox(height: 10),
        const _CalendarStrip(),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reviews', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(
                '“Gentle, practical, and helped me make a plan I could actually follow.”',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '4.9 average from 38 sessions',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Request support',
                icon: Icons.front_hand_rounded,
                onPressed: () => showComingSoon(context, 'Support request'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: 'Book session',
                icon: Icons.calendar_month_rounded,
                onPressed: () =>
                    pushScreen(context, BookingScreen(helper: helper)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          label: 'Join helper group',
          icon: Icons.groups_rounded,
          onPressed: () => showComingSoon(context, 'Helper-led group'),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.softGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.green, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarStrip extends StatelessWidget {
  const _CalendarStrip();

  @override
  Widget build(BuildContext context) {
    final days = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = index == 2;
          return Container(
            width: 76,
            decoration: BoxDecoration(
              color: selected ? AppColors.green : AppColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? AppColors.green : AppColors.line,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  days[index],
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${index + 12}',
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

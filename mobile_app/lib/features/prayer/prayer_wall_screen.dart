import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/screen_shell.dart';
import 'prayer_request_card.dart';

class PrayerWallScreen extends StatefulWidget {
  const PrayerWallScreen({super.key, this.asRootTab = false});

  final bool asRootTab;

  @override
  State<PrayerWallScreen> createState() => _PrayerWallScreenState();
}

class _PrayerWallScreenState extends State<PrayerWallScreen> {
  bool submitted = false;
  bool anonymous = true;

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Prayer wall',
      subtitle: 'Private requests, group prayer, and answered prayers.',
      withBack: !widget.asRootTab,
      children: [
        AppCard(
          color: AppColors.navy,
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.light_mode_rounded,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Prayer turns isolation into shared strength.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: submitted ? _successCard(context) : _requestForm(context),
          ),
        ),
        const SizedBox(height: 18),
        Text('Prayer requests', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        const PrayerRequestCard(
          title: 'Quiet mind tonight',
          body: 'Pray for calm, honesty, and a better evening routine.',
          prayed: 53,
          isAnonymous: true,
        ),
        const PrayerRequestCard(
          title: 'Answered: interview',
          body:
              'Thank you for praying. I got clarity and peace in the meeting.',
          prayed: 76,
          isAnonymous: false,
          answered: true,
        ),
        const SizedBox(height: 4),
        Text(
          'Group prayer requests',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        const PrayerRequestCard(
          title: 'Group fasting Friday',
          body:
              'Our circle is praying for discipline and healing in families this week.',
          prayed: 34,
          isAnonymous: false,
        ),
      ],
    );
  }

  Widget _requestForm(BuildContext context) {
    return Column(
      key: const ValueKey('request-form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create prayer request',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Title',
            prefixIcon: Icon(Icons.edit_rounded),
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Prayer request',
            prefixIcon: Icon(Icons.volunteer_activism_rounded),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: anonymous,
          onChanged: (value) => setState(() => anonymous = value),
          title: const Text('Post anonymously'),
        ),
        FilledButton.icon(
          onPressed: () => setState(() => submitted = true),
          icon: const Icon(Icons.send_rounded),
          label: const Text('Send to prayer wall'),
        ),
      ],
    );
  }

  Widget _successCard(BuildContext context) {
    return Column(
      key: const ValueKey('request-success'),
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: .72, end: 1),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutBack,
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: AppColors.green,
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Prayer request submitted',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          anonymous
              ? 'It will appear as anonymous after moderation.'
              : 'It will appear on the prayer wall after moderation.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: () => setState(() => submitted = false),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add another request'),
        ),
      ],
    );
  }
}

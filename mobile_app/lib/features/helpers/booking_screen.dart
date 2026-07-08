import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/helper_profile.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.helper});

  final HelperProfile helper;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int session = 0;
  int date = 1;
  int time = 1;
  bool success = false;

  final sessions = const ['Intro support', '1-on-1 session', 'Weekly call'];
  final dates = const ['Today', 'Tomorrow', 'Friday', 'Sunday'];
  final times = const ['5:00 PM', '6:30 PM', '8:00 PM'];

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: success ? 'Booking confirmed' : 'Book support',
      subtitle: success
          ? 'Your request is ready. You will receive a helper confirmation.'
          : widget.helper.name,
      withBack: true,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 360),
          child: success ? _successState(context) : _bookingForm(context),
        ),
      ],
    );
  }

  Widget _bookingForm(BuildContext context) {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(widget.helper.photoUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.helper.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      widget.helper.availability,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const StatusBadge(
                label: 'Verified',
                color: AppColors.green,
                icon: Icons.verified_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ChoiceSection(
          title: 'Session type',
          options: sessions,
          selected: session,
          onSelected: (value) => setState(() => session = value),
        ),
        const SizedBox(height: 16),
        _ChoiceSection(
          title: 'Date',
          options: dates,
          selected: date,
          onSelected: (value) => setState(() => date = value),
        ),
        const SizedBox(height: 16),
        _ChoiceSection(
          title: 'Time',
          options: times,
          selected: time,
          onSelected: (value) => setState(() => time = value),
        ),
        const SizedBox(height: 16),
        const TextField(
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Private note for helper',
            prefixIcon: Icon(Icons.lock_rounded),
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          color: AppColors.softGreen,
          child: Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: AppColors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Price summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                widget.helper.price,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Request and continue to payment',
          icon: Icons.lock_rounded,
          onPressed: () => setState(() => success = true),
        ),
      ],
    );
  }

  Widget _successState(BuildContext context) {
    return AppCard(
      key: const ValueKey('success'),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: .72, end: 1),
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutBack,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 58,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Support request sent',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.helper.name} will review your request for ${dates[date]} at ${times[time]}.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Done',
            icon: Icons.check_rounded,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _ChoiceSection extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < options.length; i++)
                ChoiceChip(
                  label: Text(options[i]),
                  selected: selected == i,
                  onSelected: (_) => onSelected(i),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

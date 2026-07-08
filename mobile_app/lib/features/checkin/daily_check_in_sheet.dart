import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/widgets/app_buttons.dart';

void showDailyCheckInSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => const DailyCheckInSheet(),
  );
}

class DailyCheckInSheet extends StatefulWidget {
  const DailyCheckInSheet({super.key});

  @override
  State<DailyCheckInSheet> createState() => _DailyCheckInSheetState();
}

class _DailyCheckInSheetState extends State<DailyCheckInSheet> {
  int mood = 2;
  double intensity = 35;
  bool prayer = true;
  bool bible = false;
  bool fasting = false;
  bool share = false;
  bool submitted = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 14,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        child: submitted
            ? _CheckInSuccess(onDone: () => Navigator.pop(context))
            : ListView(
                shrinkWrap: true,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'How are you today?',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      final icons = [
                        Icons.sentiment_very_dissatisfied_rounded,
                        Icons.sentiment_dissatisfied_rounded,
                        Icons.sentiment_neutral_rounded,
                        Icons.sentiment_satisfied_alt_rounded,
                        Icons.sentiment_very_satisfied_rounded,
                      ];
                      final selected = mood == index;
                      return IconButton.filledTonal(
                        onPressed: () => setState(() => mood = index),
                        style: IconButton.styleFrom(
                          backgroundColor: selected
                              ? AppColors.green
                              : AppColors.softGreen,
                          foregroundColor: selected
                              ? Colors.white
                              : AppColors.green,
                        ),
                        icon: Icon(icons[index]),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Temptation or struggle intensity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: intensity,
                    max: 100,
                    divisions: 20,
                    label: intensity.round().toString(),
                    activeColor: AppColors.support,
                    onChanged: (value) => setState(() => intensity = value),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: prayer,
                    onChanged: (value) =>
                        setState(() => prayer = value ?? prayer),
                    title: const Text('Prayer completed'),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: bible,
                    onChanged: (value) =>
                        setState(() => bible = value ?? bible),
                    title: const Text('Bible study completed'),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: fasting,
                    onChanged: (value) =>
                        setState(() => fasting = value ?? fasting),
                    title: const Text('Fasting completed'),
                  ),
                  const SizedBox(height: 8),
                  const TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Private note',
                      prefixIcon: Icon(Icons.lock_rounded),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: share,
                    onChanged: (value) => setState(() => share = value),
                    title: const Text('Share with group'),
                  ),
                  PrimaryButton(
                    label: 'Submit check-in',
                    icon: Icons.check_circle_rounded,
                    onPressed: () => setState(() => submitted = true),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CheckInSuccess extends StatelessWidget {
  const _CheckInSuccess({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('success'),
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: .6, end: 1),
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
          const SizedBox(height: 22),
          Text(
            'Check-in saved',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Your streak ring was updated. Keep walking in grace.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Done',
            icon: Icons.check_rounded,
            onPressed: onDone,
          ),
        ],
      ),
    );
  }
}

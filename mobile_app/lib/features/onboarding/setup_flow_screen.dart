import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/services/app_state.dart';
import '../../data/mock/mock_data.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/common_widgets.dart';

class SetupFlowScreen extends StatefulWidget {
  const SetupFlowScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<SetupFlowScreen> createState() => _SetupFlowScreenState();
}

class _SetupFlowScreenState extends State<SetupFlowScreen> {
  int step = 0;
  int focus = 4;
  int privacy = 1;
  int goal = 1;
  int reminder = 2;

  final privacyOptions = const [
    'Private only',
    'Anonymous community',
    'Accountability group',
    'Helper support',
  ];
  final goals = const ['7 days', '21 days', '30 days', 'Custom'];
  final reminders = const ['6:30 AM', '12:30 PM', '8:00 PM', 'No reminder'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      _focusPage(context),
      _choicePage(
        context,
        title: 'How would you like support?',
        subtitle: 'You can change privacy settings anytime.',
        options: privacyOptions,
        selected: privacy,
        onSelected: (value) => setState(() => privacy = value),
      ),
      _choicePage(
        context,
        title: 'Choose your first goal',
        subtitle: 'Start small. Momentum matters.',
        options: goals,
        selected: goal,
        onSelected: (value) => setState(() => goal = value),
      ),
      _choicePage(
        context,
        title: 'Set a gentle reminder',
        subtitle: 'A quiet nudge for check-ins and prayer.',
        options: reminders,
        selected: reminder,
        onSelected: (value) => setState(() => reminder = value),
      ),
      _readyPage(context),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal setup'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (step + 1) / pages.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
                color: AppColors.green,
                backgroundColor: AppColors.softGreen,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  child: KeyedSubtree(key: ValueKey(step), child: pages[step]),
                ),
              ),
              Row(
                children: [
                  if (step > 0) ...[
                    Expanded(
                      child: SecondaryButton(
                        label: 'Back',
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => setState(() => step--),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: PrimaryButton(
                      label: step == pages.length - 1
                          ? 'Enter app'
                          : 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        if (step == pages.length - 1) {
                          AppStateScope.of(context).saveSetup(
                            focus: MockDataService.focusOptions[focus].title,
                            privacy: privacyOptions[privacy],
                            goal: goals[goal],
                            reminder: reminders[reminder],
                          );
                          widget.onComplete();
                        } else {
                          setState(() => step++);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _focusPage(BuildContext context) {
    return ListView(
      children: [
        Text(
          'What do you want help with?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          'Pick one focus for the first plan. You can add more later.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 22),
        for (var i = 0; i < MockDataService.focusOptions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SelectableOption(
              label: MockDataService.focusOptions[i].title,
              icon: MockDataService.focusOptions[i].icon,
              iconUrl: MockDataService.focusOptions[i].iconUrl,
              selected: focus == i,
              accent: MockDataService.focusOptions[i].color,
              onTap: () => setState(() => focus = i),
            ),
          ),
      ],
    );
  }

  Widget _choicePage(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<String> options,
    required int selected,
    required ValueChanged<int> onSelected,
  }) {
    return ListView(
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 22),
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SelectableOption(
              label: options[i],
              icon: [
                Icons.lock_rounded,
                Icons.visibility_off_rounded,
                Icons.groups_rounded,
                Icons.verified_user_rounded,
              ][i],
              selected: selected == i,
              accent: i == selected ? AppColors.green : AppColors.gold,
              onTap: () => onSelected(i),
            ),
          ),
      ],
    );
  }

  Widget _readyPage(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 16),
        const Center(child: FreedomLogo(size: 96)),
        const SizedBox(height: 24),
        Text(
          'Your circle is ready.',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '${MockDataService.focusOptions[focus].title} • ${privacyOptions[privacy]} • ${goals[goal]}',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.green),
              const SizedBox(height: 12),
              Text(
                'Grace-first recovery',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'If you struggle, the app will help you reflect, pray, reset, and continue without shame.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

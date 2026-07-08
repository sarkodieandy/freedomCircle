import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/services/monetization_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/screen_shell.dart';
import '../monetization/feature_locked_modal.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  int filter = 0;
  final filters = const ['All', 'Recovery', 'Prayer', 'Answered', 'Prompts'];

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Private journal',
      subtitle: 'Recovery notes, prayer reflections, and answered prayers.',
      withBack: true,
      children: [
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: 'Search private entries',
            hintStyle: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => ChoiceChip(
              label: Text(filters[index]),
              selected: filter == index,
              onSelected: (_) => setState(() => filter = index),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _PromptCard(),
        const SizedBox(height: 16),
        const _NewEntryCard(),
        const SizedBox(height: 16),
        const _JournalEntryCard(
          title: 'Evening reset',
          type: 'Recovery note',
          text:
              'I noticed the strongest temptation came when I was tired. Tomorrow I will move the phone away after 9 PM.',
        ),
        const _JournalEntryCard(
          title: 'Answered prayer',
          type: 'Prayer note',
          text:
              'I asked for courage to be honest in group check-in. I shared and felt lighter.',
        ),
        const EmptyStateCard(
          icon: Icons.lock_rounded,
          title: 'No filtered entries yet',
          body:
              'When you add more private reflections, this filter will help you find them quickly.',
          action: 'Add entry',
        ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.softGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.green),
              const SizedBox(width: 8),
              Text(
                'Today’s reflection prompt',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'What helped me choose strength today?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _NewEntryCard extends StatelessWidget {
  const _NewEntryCard();

  Future<void> _save(BuildContext context) async {
    final allowed = await MonetizationService.instance.canCreateJournalEntry();
    if (!context.mounted) return;
    if (allowed) {
      showComingSoon(context, 'Journal saving');
      return;
    }
    await FeatureLockedModal.show(
      context,
      featureKey: 'unlimited_journal',
      featureName: 'Keep unlimited private journals',
      reason:
          'Free accounts include a limited journal. Premium keeps unlimited locked reflections.',
      benefits: const [
        'Unlimited private entries',
        'Locked recovery and prayer reflections',
        'Better search and progress context',
      ],
      screen: 'journal',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'New private entry',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              const StatusBadge(
                label: 'Locked',
                color: AppColors.navy,
                icon: Icons.lock_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Entry title',
              prefixIcon: Icon(Icons.title_rounded),
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Write privately...',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Save private entry',
            icon: Icons.lock_rounded,
            onPressed: () => _save(context),
          ),
        ],
      ),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({
    required this.title,
    required this.type,
    required this.text,
  });

  final String title;
  final String type;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Icon(
                  Icons.lock_rounded,
                  size: 18,
                  color: AppColors.mutedText,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(type, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

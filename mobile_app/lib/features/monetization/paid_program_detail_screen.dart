import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/images.dart';
import '../../core/services/monetization_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/remote_image.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/monetization_models.dart';
import 'feature_locked_modal.dart';

class PaidProgramDetailScreen extends StatelessWidget {
  const PaidProgramDetailScreen({super.key, this.program});

  final PaidProgram? program;

  @override
  Widget build(BuildContext context) {
    final selectedProgram = program ?? MonetizationService.mockPrograms[1];

    return ScreenShell(
      title: 'Program',
      subtitle: 'Guided recovery, devotion, and discipline plans.',
      withBack: true,
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 188,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RemoteImage(
                        imageUrl:
                            selectedProgram.coverImageUrl ?? AppImages.praying,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: StatusBadge(
                        label: selectedProgram.isPremiumIncluded
                            ? 'Included in Premium'
                            : selectedProgram.priceLabel,
                        color: selectedProgram.isPremiumIncluded
                            ? AppColors.gold
                            : AppColors.green,
                        icon: selectedProgram.isPremiumIncluded
                            ? Icons.workspace_premium_rounded
                            : Icons.payments_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedProgram.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedProgram.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SmallTag(label: selectedProgram.programType),
                        SmallTag(label: selectedProgram.priceLabel),
                        if (selectedProgram.isPremiumIncluded)
                          const SmallTag(label: 'Premium included'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modules and lessons',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (selectedProgram.modules.isEmpty) ...[
                const _ProgramLessonPreview(
                  title: 'Start with clarity',
                  duration: '8 min',
                ),
                const _ProgramLessonPreview(
                  title: 'Daily reflection rhythm',
                  duration: '10 min',
                ),
                const _ProgramLessonPreview(
                  title: 'Accountability action',
                  duration: '7 min',
                ),
              ] else
                for (final module in selectedProgram.modules)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        for (final lesson in module.lessons)
                          _ProgramLessonPreview(
                            title: lesson.title,
                            duration: '${lesson.durationMinutes} min',
                          ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        PrimaryButton(
          label: selectedProgram.price == 0 ? 'Start program' : 'Buy / Start',
          icon: Icons.play_circle_outline_rounded,
          color: selectedProgram.price == 0 ? AppColors.green : AppColors.gold,
          foregroundColor: selectedProgram.price == 0
              ? Colors.white
              : AppColors.navy,
          onPressed: () async {
            final allowed = await MonetizationService.instance.canAccessProgram(
              selectedProgram.id,
            );
            if (!context.mounted) return;
            if (allowed || selectedProgram.price == 0) {
              showComingSoon(context, 'Program player');
            } else {
              FeatureLockedModal.show(
                context,
                featureKey: 'paid_program_access',
                featureName: selectedProgram.title,
                reason:
                    'This guided program requires a one-time purchase or Premium access when included.',
                benefits: const [
                  'Structured lessons and reflection prompts',
                  'Progress through modules at your pace',
                  'Premium-included plans unlock automatically',
                ],
                screen: 'paid_program_detail',
              );
            }
          },
        ),
      ],
    );
  }
}

class _ProgramLessonPreview extends StatelessWidget {
  const _ProgramLessonPreview({required this.title, required this.duration});

  final String title;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded, color: AppColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(duration, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/services/monetization_service.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/helper_profile.dart';
import '../../data/providers/repository_provider.dart';
import '../../data/repositories/freedom_repository.dart';
import '../monetization/feature_locked_modal.dart';
import 'helper_profile_screen.dart';

class CoachDirectoryScreen extends StatefulWidget {
  const CoachDirectoryScreen({super.key});

  @override
  State<CoachDirectoryScreen> createState() => _CoachDirectoryScreenState();
}

class _CoachDirectoryScreenState extends State<CoachDirectoryScreen> {
  final FreedomRepository _repository = RepositoryProvider.freedomRepository();
  late final Future<List<HelperProfile>> _helpersFuture;

  int filter = 0;
  final filters = const [
    'All',
    'Focus area',
    'Gender',
    'Language',
    'Available',
    'Free/Paid',
    'Online',
  ];

  @override
  void initState() {
    super.initState();
    _helpersFuture = _repository.helpers();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HelperProfile>>(
      future: _helpersFuture,
      builder: (context, snapshot) {
        final helpers = snapshot.data ?? const <HelperProfile>[];
        return ScreenShell(
          title: 'Verified helpers',
          subtitle: 'Pastors, mentors, counselors, and recovery coaches.',
          withBack: true,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search helpers by focus, language, church',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: () =>
                      showComingSoon(context, 'Advanced helper filters'),
                  icon: const Icon(Icons.tune_rounded),
                ),
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
            AppCard(
              color: AppColors.softGreen,
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Every helper profile is designed for support and accountability, not emergency care.',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              onTap: () async {
                final allowed = await MonetizationService.instance.hasFeature(
                  'helper_matching',
                );
                if (!context.mounted) return;
                if (!allowed) {
                  await FeatureLockedModal.show(
                    context,
                    featureKey: 'helper_matching',
                    featureName: 'Smart helper matching',
                    reason:
                        'Premium helps match you with helpers by focus area, language, and availability.',
                    benefits: const [
                      'Better support recommendations',
                      'Match by recovery focus and language',
                      'Priority helper discovery',
                    ],
                    screen: 'helper_directory',
                  );
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Smart helper matching',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const StatusBadge(
                    label: 'Premium',
                    color: AppColors.gold,
                    icon: Icons.workspace_premium_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (snapshot.hasError)
              AppCard(
                child: Text(
                  'Could not load helpers from backend yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            for (final helper in helpers)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _HelperCard(
                  helper: helper,
                  onTap: () =>
                      pushScreen(context, HelperProfileScreen(helper: helper)),
                ),
              ),
            if (helpers.isEmpty)
              const EmptyStateCard(
                icon: Icons.verified_user_outlined,
                title: 'No verified helpers yet',
                body: 'Helpers will appear here once profiles are approved.',
                action: 'Refresh',
              ),
          ],
        );
      },
    );
  }
}

class _HelperCard extends StatelessWidget {
  const _HelperCard({required this.helper, required this.onTap});

  final HelperProfile helper;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundImage: NetworkImage(helper.photoUrl),
                backgroundColor: AppColors.softGreen,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            helper.name,
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.green,
                          size: 18,
                        ),
                      ],
                    ),
                    Text(
                      helper.organization,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.gold,
                          size: 18,
                        ),
                        Text(
                          ' ${helper.rating}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            helper.availability,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final area in helper.focusAreas) SmallTag(label: area),
              for (final language in helper.languages.take(2))
                SmallTag(label: language),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              StatusBadge(
                label: helper.isFreeAvailable ? 'Free option' : helper.price,
                color: helper.isFreeAvailable
                    ? AppColors.green
                    : AppColors.gold,
                icon: Icons.payments_rounded,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text('Book'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

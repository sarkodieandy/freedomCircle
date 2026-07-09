import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/constants.dart';
import '../../core/services/monetization_service.dart';
import '../../data/providers/repository_provider.dart';
import '../../data/repositories/freedom_repository.dart';
import '../../data/models/accountability_group.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/app_filter_chip.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/remote_image.dart';
import '../monetization/feature_locked_modal.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final FreedomRepository _repository = RepositoryProvider.freedomRepository();
  late final Future<List<AccountabilityGroup>> _groupsFuture;

  int selectedFilter = 0;
  final filters = const [
    'All',
    'Men',
    'Women',
    'Youth',
    'Students',
    'Prayer',
    'Fasting',
    'Recovery',
    'Bible study',
  ];

  @override
  void initState() {
    super.initState();
    _groupsFuture = _repository.groups();
  }

  AccountabilityGroup? _groupAt(List<AccountabilityGroup> groups, int index) {
    if (groups.isEmpty || index < 0 || index >= groups.length) return null;
    return groups[index];
  }

  Future<void> _openGroup(AccountabilityGroup group) async {
    if (group.isPremium) {
      final allowed = await MonetizationService.instance.canAccessPremiumGroup(
        group.name,
      );
      if (!mounted) return;
      if (!allowed) {
        await FeatureLockedModal.show(
          context,
          featureKey: 'premium_groups',
          featureName: 'Join premium accountability circles',
          reason:
              'Premium groups include guided check-ins, devotion prompts, and deeper accountability.',
          benefits: const [
            'Guided weekly check-ins',
            'Premium recovery and devotion circles',
            'More structured support',
          ],
          screen: 'groups',
        );
        return;
      }
    }

    if (!mounted) return;
    pushScreen(context, GroupDetailScreen(group: group));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.pushNamed(context, AppRoutes.groupsCreate),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create group'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<AccountabilityGroup>>(
          future: _groupsFuture,
          builder: (context, snapshot) {
            final groups = snapshot.data ?? const <AccountabilityGroup>[];
            final joinedGroup = _groupAt(groups, 0);
            final featured = groups.take(2).toList();
            final privateGroup = _groupAt(groups, 0);
            final churchGroup = _groupAt(groups, 3) ?? _groupAt(groups, 1);
            final premiumGroup = _groupAt(groups, 2);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 104),
              children: [
                Text(
                  'Accountability circles',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Private groups, church circles, and helper-led support.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                AppSearchBar(
                  hintText: 'Search groups, churches, challenges',
                  onFilterTap: () => showComingSoon(context, 'Group filters'),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return AppFilterChip(
                        label: filters[index],
                        selected: selectedFilter == index,
                        onSelected: (_) =>
                            setState(() => selectedFilter = index),
                      );
                    },
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
                      'Could not load groups from backend yet. Try refreshing.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                if (groups.isEmpty &&
                    !snapshot.hasError &&
                    snapshot.connectionState != ConnectionState.waiting)
                  const EmptyStateCard(
                    icon: Icons.groups_outlined,
                    title: 'No groups available yet',
                    body: 'Create or join a group to see it here.',
                    action: 'Refresh',
                  ),
                if (joinedGroup != null) ...[
                  SectionHeader(title: 'Joined groups', action: 'Manage'),
                  const SizedBox(height: 10),
                  GroupCard(
                    group: joinedGroup,
                    compact: true,
                    onTap: () => _openGroup(joinedGroup),
                  ),
                  const SizedBox(height: 18),
                ],
                if (featured.isNotEmpty) ...[
                  SectionHeader(title: 'Featured groups'),
                  const SizedBox(height: 10),
                  for (final group in featured)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GroupCard(
                        group: group,
                        onTap: () => _openGroup(group),
                      ),
                    ),
                ],
                if (privateGroup != null) ...[
                  const SizedBox(height: 4),
                  _SectionBand(
                    title: 'Private groups',
                    body:
                        'Approval-based circles for sensitive accountability.',
                    group: privateGroup,
                    onView: () => _openGroup(privateGroup),
                  ),
                ],
                if (churchGroup != null) ...[
                  const SizedBox(height: 14),
                  _SectionBand(
                    title: 'Church-only groups',
                    body:
                        'Communities created for churches and youth ministries.',
                    group: churchGroup,
                    onView: () => _openGroup(churchGroup),
                  ),
                ],
                if (premiumGroup != null) ...[
                  const SizedBox(height: 14),
                  _SectionBand(
                    title: 'Premium groups',
                    body:
                        'Guided challenges with deeper devotion and support plans.',
                    group: premiumGroup,
                    onView: () => _openGroup(premiumGroup),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionBand extends StatelessWidget {
  const _SectionBand({
    required this.title,
    required this.body,
    required this.group,
    required this.onView,
  });

  final String title;
  final String body;
  final AccountabilityGroup group;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(body, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              StatusBadge(
                label: group.type,
                color: group.isPremium ? AppColors.gold : AppColors.green,
                icon: group.isPremium
                    ? Icons.workspace_premium_rounded
                    : Icons.lock_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 86,
                  height: 78,
                  child: RemoteImage(
                    imageUrl: group.imageUrl,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group.members} members • ${group.online} online',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FilledButton(onPressed: onView, child: const Text('View')),
            ],
          ),
        ],
      ),
    );
  }
}

class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
    this.compact = false,
  });

  final AccountabilityGroup group;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: compact ? 118 : 150,
            child: Stack(
              children: [
                Positioned.fill(
                  child: RemoteImage(
                    imageUrl: group.imageUrl,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  child: StatusBadge(
                    label: group.type,
                    color: group.isPremium ? AppColors.gold : AppColors.green,
                    icon: group.isPremium
                        ? Icons.workspace_premium_rounded
                        : Icons.lock_rounded,
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: StatusBadge(
                    label: '${group.online} online',
                    color: AppColors.green,
                    icon: Icons.circle,
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
                Text(group.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  group.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      size: 18,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${group.members} members',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${(group.checkInRate * 100).round()}% check-in',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: group.checkInRate,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.green,
                  backgroundColor: AppColors.softGreen,
                ),
                if (!compact) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in group.tags) SmallTag(label: tag),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

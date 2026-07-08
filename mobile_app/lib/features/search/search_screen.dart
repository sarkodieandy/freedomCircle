import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/accountability_group.dart';
import '../../data/models/helper_profile.dart';
import '../../data/providers/repository_provider.dart';
import '../../data/repositories/freedom_repository.dart';
import '../groups/group_detail_screen.dart';
import '../helpers/helper_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FreedomRepository _repository = RepositoryProvider.freedomRepository();
  late final Future<List<AccountabilityGroup>> _groupsFuture;
  late final Future<List<HelperProfile>> _helpersFuture;

  @override
  void initState() {
    super.initState();
    _groupsFuture = _repository.groups();
    _helpersFuture = _repository.helpers();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AccountabilityGroup>>(
      future: _groupsFuture,
      builder: (context, groupSnapshot) {
        return FutureBuilder<List<HelperProfile>>(
          future: _helpersFuture,
          builder: (context, helperSnapshot) {
            final group = groupSnapshot.data?.isNotEmpty == true
                ? groupSnapshot.data!.first
                : null;
            final helper = helperSnapshot.data?.isNotEmpty == true
                ? helperSnapshot.data!.first
                : null;

            return ScreenShell(
              title: 'Search',
              subtitle:
                  'Find groups, posts, helpers, prayer requests, and resources.',
              withBack: true,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search FreedomCircle',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          showComingSoon(context, 'Search filters'),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    SmallTag(label: 'Groups'),
                    SmallTag(label: 'Posts'),
                    SmallTag(label: 'Helpers'),
                    SmallTag(label: 'Prayer'),
                    SmallTag(label: 'Resources'),
                  ],
                ),
                const SizedBox(height: 18),
                if (groupSnapshot.connectionState == ConnectionState.waiting ||
                    helperSnapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (group != null)
                  AppCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(group: group),
                      ),
                    ),
                    child: _ResultRow(
                      icon: Icons.groups_rounded,
                      title: group.name,
                      subtitle: '${group.members} members • ${group.type}',
                      badge: 'Group',
                    ),
                  ),
                if (group != null) const SizedBox(height: 12),
                if (helper != null)
                  AppCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HelperProfileScreen(helper: helper),
                      ),
                    ),
                    child: _ResultRow(
                      icon: Icons.verified_user_rounded,
                      title: helper.name,
                      subtitle:
                          '${helper.rating} rating • ${helper.availability}',
                      badge: 'Helper',
                    ),
                  ),
                if (helper != null) const SizedBox(height: 12),
                if (group == null && helper == null)
                  const EmptyStateCard(
                    icon: Icons.search_off_rounded,
                    title: 'No backend search results yet',
                    body:
                        'Groups and helpers will appear here after data sync.',
                    action: 'Refresh',
                  ),
                const AppCard(
                  child: _ResultRow(
                    icon: Icons.volunteer_activism_rounded,
                    title: 'Quiet mind tonight',
                    subtitle: 'Prayer request • 53 people prayed',
                    badge: 'Prayer',
                  ),
                ),
                const SizedBox(height: 12),
                const AppCard(
                  child: _ResultRow(
                    icon: Icons.auto_stories_rounded,
                    title: '21-day prayer reset plan',
                    subtitle: 'Resource • Guided devotion',
                    badge: 'Resource',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.softGreen,
          child: Icon(icon, color: AppColors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        StatusBadge(label: badge, color: AppColors.green, icon: Icons.search),
      ],
    );
  }
}

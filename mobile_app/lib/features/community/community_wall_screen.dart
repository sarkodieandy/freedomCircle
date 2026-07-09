import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../data/models/community_post.dart';
import '../../data/providers/repository_provider.dart';
import '../../data/repositories/freedom_repository.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';

class CommunityWallScreen extends StatefulWidget {
  const CommunityWallScreen({super.key});

  @override
  State<CommunityWallScreen> createState() => _CommunityWallScreenState();
}

class _CommunityWallScreenState extends State<CommunityWallScreen> {
  final FreedomRepository _repository = RepositoryProvider.freedomRepository();
  late final Future<List<CommunityPost>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _repository.communityPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<CommunityPost>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            final posts = snapshot.data ?? const <CommunityPost>[];
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 104),
              children: [
                Text(
                  'Community wall',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Prayer, testimony, questions, and moderated support.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                AppSearchBar(
                  hintText:
                      'Search prayer requests, testimonies, and questions',
                  onFilterTap: () =>
                      showComingSoon(context, 'Community filters'),
                ),
                const SizedBox(height: 22),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Share what you need prayer for...',
                          hintStyle: Theme.of(context).textTheme.bodyMedium,
                          prefixIcon: const Icon(Icons.edit_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          SmallTag(label: 'Prayer Request'),
                          SmallTag(label: 'Testimony'),
                          SmallTag(label: 'Struggle'),
                          SmallTag(label: 'Encouragement'),
                          SmallTag(label: 'Question'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: true,
                        onChanged: (_) {},
                        title: const Text('Post anonymously'),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: () =>
                              showComingSoon(context, 'Create post'),
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('Post'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const AppSectionHeader(
                  title: 'Latest activity',
                  subtitle:
                      'Safe, moderated encouragement from your community.',
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
                      'Could not load community posts from backend yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                for (final post in posts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _CommunityPostCard(post: post),
                  ),
                if (posts.isEmpty)
                  const EmptyStateCard(
                    icon: Icons.forum_outlined,
                    title: 'No posts yet',
                    body:
                        'New moderated posts and prayer requests will appear here.',
                    action: 'Refresh feed',
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  const _CommunityPostCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.softGreen,
                child: Icon(
                  post.isAnonymous
                      ? Icons.visibility_off_rounded
                      : Icons.person_rounded,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.author,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      post.type,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (post.reviewed)
                const StatusBadge(
                  label: 'Reviewed',
                  color: AppColors.green,
                  icon: Icons.verified_rounded,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(post.content, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 14),
          Row(
            children: [
              ActionPill(
                icon: Icons.volunteer_activism_rounded,
                label: 'Pray ${post.prayers}',
              ),
              const SizedBox(width: 8),
              const ActionPill(icon: Icons.favorite_rounded, label: 'Amen'),
              const SizedBox(width: 8),
              ActionPill(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${post.comments}',
              ),
              const Spacer(),
              IconButton(
                onPressed: () => showComingSoon(context, 'Post reporting'),
                icon: const Icon(Icons.flag_outlined),
                tooltip: 'Report post',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 18,
                  color: AppColors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post.type == 'Struggle'
                        ? 'Moderator: Thank you for sharing safely. You are not alone.'
                        : 'Community: Praying with you and celebrating the small wins.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

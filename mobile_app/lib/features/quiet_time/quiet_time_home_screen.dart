import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import 'quiet_time_history_screen.dart';
import 'quiet_time_models.dart';
import 'quiet_time_video_feed_screen.dart';
import 'quiet_time_repository.dart';
import 'quiet_time_session_screen.dart';
import 'widgets/guided_session_card.dart';
import 'widgets/mood_selector_card.dart';
import 'widgets/quiet_time_category_card.dart';

class QuietTimeHomeScreen extends StatefulWidget {
  const QuietTimeHomeScreen({super.key});

  @override
  State<QuietTimeHomeScreen> createState() => _QuietTimeHomeScreenState();
}

class _QuietTimeHomeScreenState extends State<QuietTimeHomeScreen> {
  final QuietTimeRepository _repository = const QuietTimeRepository();

  late final Future<List<QuietTimeCategory>> _categoriesFuture;
  late final Future<QuietTimeHistorySummary> _historyFuture;
  QuietTimeMood _selectedMood = QuietTimeMood.needPeace;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _repository.categories();
    _historyFuture = _repository.historySummary();
  }

  void _openSession(QuietTimeSession session) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QuietTimeVideoFeedScreen()));
  }

  IconData _categoryIcon(String key) {
    return switch (key) {
      'volunteer_activism' => Icons.volunteer_activism_rounded,
      'menu_book' => Icons.menu_book_rounded,
      'self_improvement' => Icons.self_improvement_rounded,
      'restart_alt' => Icons.restart_alt_rounded,
      'favorite' => Icons.favorite_rounded,
      'nights_stay' => Icons.nights_stay_rounded,
      'wb_sunny' => Icons.wb_sunny_rounded,
      'front_hand' => Icons.front_hand_rounded,
      _ => Icons.spa_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<QuietTimeSession>>(
          future: _repository.recommendedSessions(mood: _selectedMood),
          builder: (context, recommendedSnapshot) {
            return FutureBuilder<QuietTimeSession?>(
              future: _repository.lastSession(),
              builder: (context, lastSessionSnapshot) {
                return FutureBuilder<List<QuietTimeCategory>>(
                  future: _categoriesFuture,
                  builder: (context, categoriesSnapshot) {
                    return FutureBuilder<QuietTimeHistorySummary>(
                      future: _historyFuture,
                      builder: (context, historySnapshot) {
                        final recommended =
                            recommendedSnapshot.data ??
                            const <QuietTimeSession>[];
                        final lastSession = lastSessionSnapshot.data;
                        final categories =
                            categoriesSnapshot.data ??
                            const <QuietTimeCategory>[];
                        final history =
                            historySnapshot.data ??
                            QuietTimeRepository.mockHistorySummary;

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 104),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Quiet Time',
                                        style: AppTextStyles.screenTitle,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Guided prayer, stillness, and reflection for your journey.',
                                        style: AppTextStyles.body,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Pause, breathe, pray, and continue with grace.',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton.filledTonal(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const QuietTimeHistoryScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.insights_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // ── TikTok-style video feed entry ──────────
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const QuietTimeVideoFeedScreen(),
                                ),
                              ),
                              child: Container(
                                width: double.infinity,
                                height: 108,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF0D2818),
                                      Color(0xFF1C2B44),
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.softGreen.withValues(
                                          alpha: 0.18,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.play_circle_filled_rounded,
                                        color: AppColors.softGreen,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Watch Quiet Time',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Scroll through guided video sessions',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.58,
                                              ),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Colors.white30,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'How are you feeling?',
                              style: AppTextStyles.sectionTitle,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final mood in QuietTimeMood.values)
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: .94, end: 1),
                                    duration: Duration(
                                      milliseconds: 180 + (mood.index * 30),
                                    ),
                                    curve: Curves.easeOutBack,
                                    builder: (context, value, child) =>
                                        Transform.scale(
                                          scale: value,
                                          child: child,
                                        ),
                                    child: MoodSelectorCard(
                                      label: mood.label,
                                      icon: mood.icon,
                                      selected: _selectedMood == mood,
                                      onTap: () =>
                                          setState(() => _selectedMood = mood),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const SectionHeader(
                              title: 'Recommended for now',
                              leadingIcon: Icons.auto_awesome_rounded,
                            ),
                            const SizedBox(height: 10),
                            if (recommended.isNotEmpty)
                              GuidedSessionCard(
                                title: recommended.first.title,
                                description: recommended.first.description,
                                duration: recommended.first.durationLabel,
                                category: 'Recommended',
                                isPremium: recommended.first.isPremium,
                                locked: recommended.first.isPremium,
                                onStart: () => _openSession(recommended.first),
                              )
                            else
                              const EmptyStateCard(
                                icon: Icons.self_improvement_rounded,
                                title: 'No recommendation yet',
                                body:
                                    'Quiet Time recommendations will appear here.',
                                action: 'Refresh',
                              ),
                            const SizedBox(height: 14),
                            if (lastSession != null)
                              AppCard(
                                onTap: () => _openSession(lastSession),
                                child: Row(
                                  children: [
                                    const AppIconContainer(
                                      icon: Icons.history_rounded,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Continue last session',
                                            style: AppTextStyles.cardTitle,
                                          ),
                                          Text(
                                            '${lastSession.title} • ${lastSession.durationLabel}',
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: AppColors.green,
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 18),
                            const SectionHeader(
                              title: 'Quiet Time categories',
                              leadingIcon: Icons.category_rounded,
                            ),
                            const SizedBox(height: 10),
                            GridView.builder(
                              itemCount: categories.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.04,
                                  ),
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                return QuietTimeCategoryCard(
                                  title: category.name,
                                  description: category.description,
                                  icon: _categoryIcon(category.icon),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => QuietTimeSessionScreen(
                                          category: category,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            SectionHeader(
                              title: 'Recent Quiet Time',
                              leadingIcon: Icons.update_rounded,
                              action: 'History',
                              onAction: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const QuietTimeHistoryScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            for (
                              var i = 0;
                              i < history.recentHistory.length && i < 3;
                              i++
                            )
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: AppCard(
                                  child: Row(
                                    children: [
                                      const AppIconContainer(
                                        icon: Icons.check_circle_rounded,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          history
                                                  .recentHistory[i]
                                                  .sessionTitle ??
                                              'Quiet session',
                                          style: AppTextStyles.cardTitle,
                                        ),
                                      ),
                                      Text(
                                        '${(history.recentHistory[i].durationCompletedSeconds / 60).round()} min',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 6),
                            AppCard(
                              color: AppColors.navy,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const QuietTimeVideoFeedScreen(),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const AppIconContainer(
                                    icon: Icons.library_music_rounded,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Premium video library preview',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(color: Colors.white),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Night Peace, Surrender the Struggle, Deep Scripture Stillness videos, and more.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const StatusBadge(
                                    label: 'Premium',
                                    color: AppColors.gold,
                                    icon: Icons.lock_rounded,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

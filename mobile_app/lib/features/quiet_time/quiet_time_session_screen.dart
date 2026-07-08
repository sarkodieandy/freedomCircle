import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import '../monetization/feature_locked_modal.dart';
import 'quiet_time_models.dart';
import 'quiet_time_player_screen.dart';
import 'quiet_time_repository.dart';
import 'widgets/guided_session_card.dart';

class QuietTimeSessionScreen extends StatefulWidget {
  const QuietTimeSessionScreen({super.key, this.category});

  final QuietTimeCategory? category;

  @override
  State<QuietTimeSessionScreen> createState() => _QuietTimeSessionScreenState();
}

class _QuietTimeSessionScreenState extends State<QuietTimeSessionScreen> {
  final QuietTimeRepository _repository = const QuietTimeRepository();
  late Future<List<QuietTimeSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = widget.category == null
        ? _repository.sessions()
        : _repository.sessionsByCategory(widget.category!.slug);
  }

  Future<void> _openSession(QuietTimeSession session) async {
    final allowed = await _repository.canAccessSession(session);
    if (!mounted) return;
    if (!allowed) {
      await FeatureLockedModal.show(
        context,
        featureKey: 'quiet_time_premium_library',
        featureName: 'Quiet Time premium library',
        reason: 'This session is part of the premium Quiet Time library.',
        benefits: const [
          'Longer guided sessions',
          'Premium recovery reset audio',
          'Night peace and surrender journeys',
        ],
        screen: 'quiet_time_session_list',
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuietTimePlayerScreen(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.category?.name ?? 'Quiet Time sessions';
    final subtitle =
        widget.category?.description ??
        'Guided prayer, scripture meditation, and quiet reset sessions.';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: FutureBuilder<List<QuietTimeSession>>(
          future: _sessionsFuture,
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? const <QuietTimeSession>[];
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    SmallTag(label: 'Guided Prayer'),
                    SmallTag(label: 'Scripture Meditation'),
                    SmallTag(label: 'Silent Reflection'),
                    SmallTag(label: 'Recovery Reset'),
                  ],
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (sessions.isEmpty &&
                    snapshot.connectionState != ConnectionState.waiting)
                  const EmptyStateCard(
                    icon: Icons.spa_outlined,
                    title: 'No sessions yet',
                    body: 'Sessions for this category will appear here.',
                    action: 'Refresh',
                  ),
                for (var i = 0; i < sessions.length; i++)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 20, end: 0),
                    duration: Duration(milliseconds: 220 + (i * 34)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Transform.translate(
                      offset: Offset(0, value),
                      child: Opacity(
                        opacity: (1 - (value / 20)).clamp(0, 1),
                        child: child,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GuidedSessionCard(
                        title: sessions[i].title,
                        description: sessions[i].description,
                        duration: sessions[i].durationLabel,
                        category: widget.category?.name ?? 'Quiet Time',
                        isPremium: sessions[i].isPremium,
                        locked: sessions[i].isPremium,
                        onStart: () => _openSession(sessions[i]),
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  'FreedomCircle offers spiritual support and accountability. For urgent or serious concerns, reach out to a trusted person, qualified professional, or local emergency support.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.support),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

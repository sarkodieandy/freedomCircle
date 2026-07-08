import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/animations/pressable_scale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/common_widgets.dart';
import '../helpers/coach_directory_screen.dart';
import '../journal/journal_screen.dart';
import '../groups/groups_screen.dart';
import '../prayer/prayer_wall_screen.dart';
import 'quiet_time_models.dart';
import 'quiet_time_session_screen.dart';

class QuietTimeCompletionScreen extends StatefulWidget {
  const QuietTimeCompletionScreen({
    super.key,
    required this.session,
    required this.durationSeconds,
    required this.moodBefore,
    required this.moodAfter,
    this.reflectionSeed,
  });

  final QuietTimeSession session;
  final int durationSeconds;
  final QuietTimeMood moodBefore;
  final QuietTimeMood moodAfter;
  final String? reflectionSeed;

  @override
  State<QuietTimeCompletionScreen> createState() =>
      _QuietTimeCompletionScreenState();
}

class _QuietTimeCompletionScreenState extends State<QuietTimeCompletionScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _reflectionController = TextEditingController();
  bool _shareWithGroup = false;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _reflectionController.text = widget.reflectionSeed ?? '';
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
      lowerBound: .95,
      upperBound: 1.05,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  String get _durationLabel {
    final minutes = (widget.durationSeconds / 60).round();
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiet Time complete')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                return Transform.scale(
                  scale: _glowController.value,
                  child: Container(
                    width: 96,
                    height: 96,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.softGreen,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: .24),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 58,
                    ),
                  ),
                );
              },
            ),
            Text(
              'Quiet Time completed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'You took $_durationLabel to pause, pray, and continue with grace.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  _MetricRow(label: 'Session', value: widget.session.title),
                  const SizedBox(height: 8),
                  _MetricRow(label: 'Duration', value: _durationLabel),
                  const SizedBox(height: 8),
                  _MetricRow(
                    label: 'Mood before',
                    value: widget.moodBefore.label,
                  ),
                  const SizedBox(height: 8),
                  _MetricRow(
                    label: 'Mood after',
                    value: widget.moodAfter.label,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Private reflection prompt',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reflectionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'What did God or this moment remind you of?',
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const JournalScreen()),
                    ),
                    icon: const Icon(Icons.book_rounded),
                    label: const Text('Save to journal'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _shareWithGroup,
                    onChanged: (value) =>
                        setState(() => _shareWithGroup = value),
                    title: const Text('Share progress with group'),
                    subtitle: const Text(
                      'Only progress summary is shared, not private notes.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Suggested next step',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _NextStepChip(
                  label: 'Pray',
                  icon: Icons.volunteer_activism_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrayerWallScreen()),
                  ),
                ),
                _NextStepChip(
                  label: 'Journal',
                  icon: Icons.edit_note_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const JournalScreen()),
                  ),
                ),
                _NextStepChip(
                  label: 'Check in',
                  icon: Icons.check_circle_rounded,
                  onTap: () => showComingSoon(context, 'Daily check-in'),
                ),
                _NextStepChip(
                  label: 'Message helper',
                  icon: Icons.chat_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CoachDirectoryScreen(),
                    ),
                  ),
                ),
                _NextStepChip(
                  label: 'Join group',
                  icon: Icons.groups_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GroupsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const QuietTimeSessionScreen(),
                  ),
                  (route) => route.isFirst,
                );
              },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

class _NextStepChip extends StatelessWidget {
  const _NextStepChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: ActionChip(
        avatar: Icon(icon, size: 18, color: AppColors.green),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/common_widgets.dart';
import '../helpers/coach_directory_screen.dart';
import '../journal/journal_screen.dart';
import '../prayer/prayer_wall_screen.dart';
import 'quiet_time_completion_screen.dart';
import 'quiet_time_models.dart';
import 'quiet_time_repository.dart';
import 'widgets/breathing_prayer_circle.dart';
import 'widgets/mood_selector_card.dart';
import 'widgets/quiet_time_audio_bar.dart';
import 'widgets/quiet_time_timer.dart';
import 'widgets/reflection_prompt_card.dart';
import 'widgets/scripture_reflection_card.dart';
import 'widgets/session_progress_indicator.dart';

class QuietTimePlayerScreen extends StatefulWidget {
  const QuietTimePlayerScreen({
    super.key,
    required this.session,
    this.initialMood,
  });

  final QuietTimeSession session;
  final QuietTimeMood? initialMood;

  @override
  State<QuietTimePlayerScreen> createState() => _QuietTimePlayerScreenState();
}

class _QuietTimePlayerScreenState extends State<QuietTimePlayerScreen> {
  final QuietTimeRepository _repository = const QuietTimeRepository();
  final TextEditingController _noteController = TextEditingController();

  Timer? _timer;
  bool _playing = true;
  bool _journalAfter = true;
  bool _showScripture = true;
  bool _showSoundPlaceholder = true;
  int _elapsedSeconds = 0;
  int _silentMinutes = 5;
  int _stepIndex = 0;
  QuietTimeMood _moodBefore = QuietTimeMood.needPeace;
  QuietTimeMood _moodAfter = QuietTimeMood.needPeace;

  List<QuietTimeStep> get _steps => widget.session.steps.isEmpty
      ? const <QuietTimeStep>[]
      : widget.session.steps;

  int get _totalSeconds {
    if (widget.session.slug == 'silent-reflection-timer') {
      return _silentMinutes * 60;
    }
    final fromSteps = _steps.fold<int>(
      0,
      (sum, item) => sum + item.durationSeconds,
    );
    return fromSteps > 0 ? fromSteps : widget.session.durationMinutes * 60;
  }

  double get _progress =>
      _totalSeconds == 0 ? 0 : (_elapsedSeconds / _totalSeconds).clamp(0, 1);

  bool get _isRecoveryReset =>
      widget.session.slug.contains('reset') ||
      widget.session.slug.contains('temptation') ||
      widget.session.categoryId == 'qt-cat-recovery-reset';

  @override
  void initState() {
    super.initState();
    _moodBefore = widget.initialMood ?? QuietTimeMood.needPeace;
    _moodAfter = _moodBefore;
    _startTicker();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_playing) return;
      setState(() {
        _elapsedSeconds += 1;
        _syncStepFromProgress();
      });
      if (_elapsedSeconds >= _totalSeconds) {
        _completeSession();
      }
    });
  }

  void _syncStepFromProgress() {
    if (_steps.isEmpty) return;
    var running = 0;
    for (var i = 0; i < _steps.length; i++) {
      running += _steps[i].durationSeconds;
      if (_elapsedSeconds <= running) {
        _stepIndex = i;
        return;
      }
    }
    _stepIndex = _steps.length - 1;
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    await _repository.createHistoryRecord(
      sessionId: widget.session.id,
      durationSeconds: _elapsedSeconds,
      moodBefore: _moodBefore,
      moodAfter: _moodAfter,
      privateNote: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      completed: true,
      sharedWithGroup: false,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuietTimeCompletionScreen(
          session: widget.session,
          durationSeconds: _elapsedSeconds,
          moodBefore: _moodBefore,
          moodAfter: _moodAfter,
          reflectionSeed: _noteController.text,
        ),
      ),
    );
  }

  String _timeLabel(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remaining = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remaining';
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps.isEmpty
        ? QuietTimeStep(
            id: 'default-step',
            sessionId: widget.session.id,
            stepTitle: 'Reflect',
            stepType: 'reflection',
            content: 'Take this moment slowly with honest prayer.',
            scriptureReference: 'Psalm 46:10',
            durationSeconds: 60,
            sortOrder: 1,
          )
        : _steps[_stepIndex.clamp(0, _steps.length - 1)];

    return Scaffold(
      appBar: AppBar(title: const Text('Quiet Time')),
      body: Container(
        decoration: const BoxDecoration(color: AppColors.background),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              left: -10,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.softGreen.withValues(alpha: .6),
                ),
              ),
            ),
            Positioned(
              right: -40,
              top: 240,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: .08),
                ),
              ),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Text(
                    widget.session.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.session.durationLabel} • ${_timeLabel(_elapsedSeconds)} elapsed',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  SessionProgressIndicator(
                    steps: const [
                      'Settle',
                      'Breathe',
                      'Reflect',
                      'Pray',
                      'Journal',
                    ],
                    current: _stepIndex,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: BreathingPrayerCircle(
                      progress: _progress,
                      playing: _playing,
                      label: currentStep.stepTitle,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentStep.stepTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentStep.content,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_showScripture &&
                      (currentStep.scriptureReference?.isNotEmpty ?? false))
                    ScriptureReflectionCard(
                      verse: 'Be still, and know that I am God.',
                      reference:
                          currentStep.scriptureReference ?? 'Psalm 46:10',
                    ),
                  if (_showScripture &&
                      (currentStep.scriptureReference?.isNotEmpty ?? false))
                    const SizedBox(height: 12),
                  QuietTimeAudioBar(
                    playing: _playing,
                    progress: _progress,
                    onPlayPause: () => setState(() => _playing = !_playing),
                    onPrevious: () => setState(
                      () => _stepIndex = (_stepIndex - 1).clamp(0, 4),
                    ),
                    onNext: () => setState(
                      () => _stepIndex = (_stepIndex + 1).clamp(0, 4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _journalAfter,
                    onChanged: (value) => setState(() => _journalAfter = value),
                    title: const Text('Journal after this'),
                    subtitle: const Text(
                      'Save this moment privately in your journal.',
                    ),
                    activeThumbColor: AppColors.green,
                  ),
                  if (widget.session.slug == 'silent-reflection-timer') ...[
                    const SizedBox(height: 10),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Silent Reflection Timer',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          QuietTimeTimer(
                            durations: const [3, 5, 10, 15],
                            selected: _silentMinutes,
                            onSelected: (minutes) => setState(() {
                              _silentMinutes = minutes;
                              _elapsedSeconds = 0;
                            }),
                            onCustom: () =>
                                showComingSoon(context, 'Custom timer'),
                          ),
                          const SizedBox(height: 10),
                          CheckboxListTile(
                            value: _showScripture,
                            onChanged: (value) =>
                                setState(() => _showScripture = value ?? true),
                            title: const Text('Optional scripture card'),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          CheckboxListTile(
                            value: _showSoundPlaceholder,
                            onChanged: (value) => setState(
                              () => _showSoundPlaceholder = value ?? true,
                            ),
                            title: const Text(
                              'Optional background sound placeholder',
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          if (_showSoundPlaceholder)
                            Text(
                              'Soundscape: Soft rain and night ambience (placeholder).',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (_isRecoveryReset) ...[
                    const SizedBox(height: 14),
                    AppCard(
                      color: AppColors.softGreen,
                      child: Text(
                        'You are not your struggle. Pause, breathe, pray, and take the next right step.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'How do you feel right now?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final mood in QuietTimeMood.values.take(5))
                          MoodSelectorCard(
                            label: mood.label,
                            icon: mood.icon,
                            selected: _moodAfter == mood,
                            onTap: () => setState(() => _moodAfter = mood),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ReflectionPromptCard(
                      prompt:
                          'What truth do you need to remember in this moment?',
                      controller: _noteController,
                      hint: 'Write a private note for your reset...',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PrayerWallScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.volunteer_activism_rounded),
                            label: const Text('Request prayer'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CoachDirectoryScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.chat_rounded),
                            label: const Text('Message helper'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const JournalScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.lock_rounded),
                      label: const Text('Save as private journal entry'),
                    ),
                    const SizedBox(height: 10),
                    const SafetyNotice(
                      icon: Icons.info_outline_rounded,
                      text:
                          'FreedomCircle offers spiritual support and accountability. For urgent or serious concerns, reach out to a trusted person, qualified professional, or local emergency support.',
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _completeSession,
                          icon: const Icon(Icons.stop_circle_rounded),
                          label: const Text('End Session'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../core/widgets/app_card.dart';

class QuietTimeAudioBar extends StatelessWidget {
  const QuietTimeAudioBar({
    super.key,
    required this.playing,
    required this.progress,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
  });

  final bool playing;
  final double progress;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.green,
              inactiveTrackColor: AppColors.softGreen,
              thumbColor: AppColors.gold,
              overlayColor: AppColors.gold.withValues(alpha: .12),
            ),
            child: Slider(value: progress.clamp(0, 1), onChanged: (_) {}),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Previous',
                onPressed: onPrevious,
                icon: const Icon(Icons.skip_previous_rounded),
              ),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppColors.green),
                tooltip: playing ? 'Pause' : 'Play',
                onPressed: onPlayPause,
                icon: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
              ),
              IconButton(
                tooltip: 'Next',
                onPressed: onNext,
                icon: const Icon(Icons.skip_next_rounded),
              ),
              const Spacer(),
              const Icon(Icons.volume_up_rounded, color: AppColors.mutedText),
              const SizedBox(width: 8),
              const SizedBox(
                width: 90,
                child: LinearProgressIndicator(
                  value: .66,
                  minHeight: 6,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  color: AppColors.green,
                  backgroundColor: AppColors.softGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

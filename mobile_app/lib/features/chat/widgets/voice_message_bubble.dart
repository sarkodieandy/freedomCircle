import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../data/models/chat_message.dart';
import 'audio_waveform_view.dart';

class VoiceMessageBubble extends StatelessWidget {
  const VoiceMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.onPlay,
    required this.onLongPress,
  });

  final ChatMessage message;
  final bool isMine;
  final VoidCallback onPlay;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          width: 280,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isMine ? AppColors.green : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              IconButton.filled(
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AudioWaveformView(
                  values: message.waveform,
                  color: isMine ? Colors.white : AppColors.green,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${message.audioDurationSeconds ?? 0}s',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isMine ? Colors.white : AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

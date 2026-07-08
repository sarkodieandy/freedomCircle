import 'package:flutter/material.dart';

import '../../../app/constants.dart';

class RecordingButton extends StatelessWidget {
  const RecordingButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
  });

  final bool isRecording;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isRecording ? 1.12 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: IconButton.filled(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: isRecording ? AppColors.support : AppColors.green,
          foregroundColor: Colors.white,
        ),
        icon: Icon(isRecording ? Icons.stop_rounded : Icons.mic_rounded),
        tooltip: isRecording ? 'Stop recording' : 'Record voice note',
      ),
    );
  }
}

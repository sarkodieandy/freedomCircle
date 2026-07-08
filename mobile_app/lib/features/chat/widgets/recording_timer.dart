import 'package:flutter/material.dart';

class RecordingTimer extends StatelessWidget {
  const RecordingTimer({super.key, required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remaining = (seconds % 60).toString().padLeft(2, '0');
    return Text('$minutes:$remaining');
  }
}

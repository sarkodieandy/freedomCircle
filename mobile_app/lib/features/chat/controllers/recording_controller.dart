import 'package:flutter/foundation.dart';

import '../services/audio_recording_service.dart';

class RecordingController extends ChangeNotifier {
  RecordingController({this.service = const AudioRecordingService()});

  final AudioRecordingService service;
  AudioRecordingState state = const AudioRecordingState();

  Future<void> start() async {
    state = await service.startRecording();
    notifyListeners();
  }

  Future<AudioRecordingState> stop() async {
    state = await service.stopRecording();
    notifyListeners();
    return state;
  }

  Future<void> cancel() async {
    state = await service.cancelRecording();
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';

class AudioPlaybackState {
  const AudioPlaybackState({
    this.playingUrl,
    this.isLoading = false,
    this.progress = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  final String? playingUrl;
  final bool isLoading;
  final Duration progress;
  final Duration duration;
  final String? error;
}

class AudioPlaybackService extends ChangeNotifier {
  AudioPlaybackState state = const AudioPlaybackState();

  Future<void> play(String url, {Duration duration = Duration.zero}) async {
    state = AudioPlaybackState(
      playingUrl: url,
      duration: duration,
      isLoading: false,
    );
    notifyListeners();
  }

  Future<void> pause() async {
    state = const AudioPlaybackState();
    notifyListeners();
  }

  Future<void> stop() => pause();
}

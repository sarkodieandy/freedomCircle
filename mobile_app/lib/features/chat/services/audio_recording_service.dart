class AudioRecordingState {
  const AudioRecordingState({
    this.isRecording = false,
    this.isUploading = false,
    this.localFilePath,
    this.durationSeconds = 0,
    this.waveform = const [],
    this.error,
  });

  final bool isRecording;
  final bool isUploading;
  final String? localFilePath;
  final int durationSeconds;
  final List<double> waveform;
  final String? error;

  AudioRecordingState copyWith({
    bool? isRecording,
    bool? isUploading,
    String? localFilePath,
    int? durationSeconds,
    List<double>? waveform,
    String? error,
  }) {
    return AudioRecordingState(
      isRecording: isRecording ?? this.isRecording,
      isUploading: isUploading ?? this.isUploading,
      localFilePath: localFilePath ?? this.localFilePath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      waveform: waveform ?? this.waveform,
      error: error,
    );
  }
}

class AudioRecordingService {
  const AudioRecordingService();

  Future<bool> requestMicrophonePermission() async {
    // The native recorder package should be added here. Keeping this isolated
    // prevents microphone permissions from leaking into chat UI/repository code.
    return false;
  }

  Future<AudioRecordingState> startRecording() async {
    final allowed = await requestMicrophonePermission();
    if (!allowed) {
      return const AudioRecordingState(
        error: 'Microphone recording package is not configured yet.',
      );
    }
    return const AudioRecordingState(isRecording: true);
  }

  Future<AudioRecordingState> stopRecording() async {
    return const AudioRecordingState(
      localFilePath: null,
      durationSeconds: 0,
      waveform: [.2, .45, .33, .7, .38, .55, .29, .62],
    );
  }

  Future<AudioRecordingState> cancelRecording() async {
    return const AudioRecordingState();
  }
}

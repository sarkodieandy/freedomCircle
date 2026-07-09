import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../app/constants.dart';

class QuietVideoPlayer extends StatefulWidget {
  const QuietVideoPlayer({
    super.key,
    required this.videoUrl,
    this.onPlayStateChanged,
  });

  final String videoUrl;
  final ValueChanged<bool>? onPlayStateChanged;

  @override
  State<QuietVideoPlayer> createState() => _QuietVideoPlayerState();
}

class _QuietVideoPlayerState extends State<QuietVideoPlayer> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant QuietVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _initialize();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await controller.initialize();
      await controller.play();
      controller.setLooping(false);
      controller.addListener(_notifyPlayState);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _loading = false;
      });
      _notifyPlayState();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load this video right now.';
      });
    }
  }

  void _disposeController() {
    _controller?.removeListener(_notifyPlayState);
    _controller?.dispose();
    _controller = null;
  }

  void _notifyPlayState() {
    final isPlaying = _controller?.value.isPlaying ?? false;
    widget.onPlayStateChanged?.call(isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _controller == null) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          color: AppColors.softCream,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(_error ?? 'Video unavailable'),
      );
    }

    final controller = _controller!;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio == 0
                ? 16 / 9
                : controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        VideoProgressIndicator(
          controller,
          allowScrubbing: true,
          colors: const VideoProgressColors(
            playedColor: AppColors.green,
            bufferedColor: AppColors.mintGreen,
            backgroundColor: AppColors.line,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        IconButton.filledTonal(
          onPressed: () async {
            if (controller.value.isPlaying) {
              await controller.pause();
            } else {
              await controller.play();
            }
            _notifyPlayState();
            if (mounted) setState(() {});
          },
          icon: Icon(
            controller.value.isPlaying
                ? Icons.pause_circle_rounded
                : Icons.play_circle_rounded,
          ),
        ),
      ],
    );
  }
}

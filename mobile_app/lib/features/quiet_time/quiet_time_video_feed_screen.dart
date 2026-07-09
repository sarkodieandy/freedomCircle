import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../app/constants.dart';
import '../monetization/feature_locked_modal.dart';
import 'quiet_time_models.dart';
import 'quiet_time_repository.dart';

/// Full-screen vertical video feed — swipe up/down like TikTok.
class QuietTimeVideoFeedScreen extends StatefulWidget {
  const QuietTimeVideoFeedScreen({
    super.key,
    this.sessions,
    this.initialIndex = 0,
  });

  /// Pre-loaded sessions. Pass [null] to load all sessions from the repository.
  final List<QuietTimeSession>? sessions;
  final int initialIndex;

  @override
  State<QuietTimeVideoFeedScreen> createState() =>
      _QuietTimeVideoFeedScreenState();
}

class _QuietTimeVideoFeedScreenState extends State<QuietTimeVideoFeedScreen> {
  final _repo = const QuietTimeRepository();
  late final PageController _pages;
  int _current = 0;
  List<QuietTimeSession> _sessions = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pages = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (widget.sessions != null) {
      _sessions = widget.sessions!;
      _loading = false;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  Future<void> _load() async {
    final data = await _repo.sessions();
    if (!mounted) return;
    setState(() {
      _sessions = data;
      _loading = false;
    });
  }

  Future<void> _showPaywall(QuietTimeSession session) async {
    if (!mounted) return;
    await FeatureLockedModal.show(
      context,
      featureKey: 'quiet_time_premium_video_library',
      featureName: 'Premium Quiet Time videos',
      reason:
          'Unlock the full library of guided meditation, prayer, and reflection videos.',
      benefits: const [
        'Full guided video library',
        'Premium recovery reset videos',
        'Night peace and surrender journeys',
      ],
      screen: 'quiet_time_video_feed',
    );
  }

  Future<void> _markDone(QuietTimeSession session, int elapsedSeconds) async {
    await _repo.createHistoryRecord(
      sessionId: session.id,
      durationSeconds: elapsedSeconds,
      completed: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_sessions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.video_library_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No sessions yet',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Video sessions will appear here once published.',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── TikTok-style vertical PageView ──────────────────────────
          PageView.builder(
            controller: _pages,
            scrollDirection: Axis.vertical,
            itemCount: _sessions.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (ctx, i) => _FeedCard(
              key: ValueKey(_sessions[i].id),
              session: _sessions[i],
              repository: _repo,
              isActive: _current == i,
              onPaywall: () => _showPaywall(_sessions[i]),
              onDone: (elapsed) => _markDone(_sessions[i], elapsed),
            ),
          ),
          // ── Back button ─────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black45,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          // ── Scroll position dots ─────────────────────────────────────
          Positioned(
            right: 6,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  _sessions.length.clamp(0, 10),
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 3,
                    height: _current == i ? 22 : 6,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: _current == i ? Colors.white : Colors.white30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Feed card — one full-screen page of the PageView
// ───────────────────────────────────────────────────────────────────────────

class _FeedCard extends StatefulWidget {
  const _FeedCard({
    super.key,
    required this.session,
    required this.repository,
    required this.isActive,
    required this.onPaywall,
    required this.onDone,
  });

  final QuietTimeSession session;
  final QuietTimeRepository repository;
  final bool isActive;
  final VoidCallback onPaywall;
  final ValueChanged<int> onDone; // elapsed seconds

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  VideoPlayerController? _ctrl;
  bool _videoLoading = true;
  bool _videoError = false;
  bool _locked = false;
  bool _liked = false;
  bool _done = false;
  bool _completionRecorded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _FeedCard old) {
    super.didUpdateWidget(old);
    if (old.isActive != widget.isActive) {
      widget.isActive ? _ctrl?.play() : _ctrl?.pause();
    }
  }

  @override
  void dispose() {
    _ctrl?.removeListener(_onVideoProgress);
    _ctrl?.dispose();
    super.dispose();
  }

  /// Auto-marks the session complete when the video reaches 90% played.
  void _onVideoProgress() {
    final c = _ctrl;
    if (c == null || _completionRecorded) return;
    final dur = c.value.duration;
    final pos = c.value.position;
    if (dur.inSeconds > 10 && pos.inSeconds >= (dur.inSeconds * 0.90).round()) {
      _completionRecorded = true;
      if (!mounted) return;
      if (!_done) {
        setState(() => _done = true);
        widget.onDone(pos.inSeconds);
      }
    }
  }

  Future<void> _init() async {
    final allowed = await widget.repository.canAccessSession(widget.session);
    if (!mounted) return;
    if (!allowed) {
      setState(() {
        _locked = true;
        _videoLoading = false;
      });
      return;
    }
    await _loadVideo();
  }

  Future<void> _loadVideo() async {
    setState(() {
      _videoLoading = true;
      _videoError = false;
    });

    // Try signed URL (Supabase-native primary, Laravel fallback)
    String? url = await widget.repository.signedVideoUrl(
      widget.session.id,
      storagePath: widget.session.videoStoragePath,
    );
    url ??= widget.session.videoUrl;

    if (url == null || url.isEmpty) {
      if (!mounted) return;
      setState(() {
        _videoLoading = false;
        _videoError = true;
      });
      return;
    }

    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      await ctrl.initialize();
      ctrl.setLooping(false); // Don't loop — allow completion detection
      ctrl.addListener(_onVideoProgress); // Auto-complete at 90%
      if (widget.isActive) await ctrl.play();
      if (!mounted) {
        ctrl.removeListener(_onVideoProgress);
        await ctrl.dispose();
        return;
      }
      setState(() {
        _ctrl = ctrl;
        _videoLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _videoLoading = false;
        _videoError = true;
      });
    }
  }

  void _togglePlay() {
    final c = _ctrl;
    if (c == null) return;
    c.value.isPlaying ? c.pause() : c.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onTap: _locked ? widget.onPaywall : _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video or spiritual gradient background ─────────────────────
          _buildBackground(),

          // ── Dark gradient scrim at bottom ─────────────────────────────
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 440,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Right-side actions (like TikTok) ─────────────────────────
          Positioned(
            right: 14,
            bottom: bottomPad + 160,
            child: _buildActions(),
          ),

          // ── Session info overlay ───────────────────────────────────────
          Positioned(
            left: 16,
            right: 76,
            bottom: bottomPad + (_ctrl != null ? 38 : 28),
            child: _buildInfo(),
          ),

          // ── Video scrub bar ────────────────────────────────────────────
          if (_ctrl != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPad,
              child: VideoProgressIndicator(
                _ctrl!,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),

          // ── Premium lock overlay ───────────────────────────────────────
          if (_locked) _buildPremiumOverlay(),

          // ── Paused indicator ──────────────────────────────────────────
          if (!_locked && _ctrl != null && !_ctrl!.value.isPlaying)
            const Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black38,
                ),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (_videoLoading) {
      return Container(
        color: const Color(0xFF0C1E10),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white54,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final c = _ctrl;
    if (c != null && !_videoError) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: c.value.size.width,
            height: c.value.size.height,
            child: VideoPlayer(c),
          ),
        ),
      );
    }

    // Spiritual gradient fallback for sessions without a video yet
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2818), Color(0xFF172033)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.self_improvement_rounded,
          size: 120,
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(
          icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: 'Like',
          color: _liked ? Colors.redAccent : Colors.white,
          onTap: () => setState(() => _liked = !_liked),
        ),
        const SizedBox(height: 22),
        _Btn(
          icon: _done
              ? Icons.check_circle_rounded
              : Icons.check_circle_outline_rounded,
          label: 'Done',
          color: _done ? AppColors.success : Colors.white,
          onTap: () {
            if (_done) return;
            setState(() => _done = true);
            widget.onDone(
              _ctrl?.value.position.inSeconds ??
                  widget.session.durationMinutes * 60,
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfo() {
    final s = widget.session;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (s.isPremium)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 12,
                ),
                SizedBox(width: 4),
                Text(
                  'Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        Text(
          s.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        if ((s.scriptureReference ?? '').isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_rounded,
                color: Colors.white60,
                size: 13,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  s.scriptureReference!,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.white38, size: 13),
            const SizedBox(width: 4),
            Text(
              s.durationLabel,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(width: 10),
            Icon(
              s.isVideoSession
                  ? Icons.videocam_rounded
                  : Icons.headphones_rounded,
              color: Colors.white38,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              s.isVideoSession ? 'Video' : 'Audio',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPremiumOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: AppColors.gold,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Premium Video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Unlock the full Quiet Time video library',
                style: TextStyle(color: Colors.white70, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              onPressed: widget.onPaywall,
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text(
                'Unlock Premium',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────

class _Btn extends StatelessWidget {
  const _Btn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}

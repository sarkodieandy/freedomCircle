import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/backend_config.dart';
import '../../core/services/monetization_service.dart';
import '../../data/supabase/supabase_service.dart';
import 'quiet_time_models.dart';

class QuietTimeRepository {
  const QuietTimeRepository();

  Future<List<QuietTimeCategory>> categories() async {
    if (!SupabaseService.isInitialized) return mockCategories;
    try {
      final rows = await SupabaseService.client
          .from('quiet_time_categories')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      return (rows as List).map(_categoryFromMap).toList();
    } catch (_) {
      return mockCategories;
    }
  }

  Future<List<QuietTimeSession>> sessionsByCategory(String categorySlug) async {
    final all = await sessions();
    final allCategories = await categories();
    if (allCategories.isEmpty) return all;
    final category = allCategories.firstWhere(
      (item) => item.slug == categorySlug,
      orElse: () => allCategories.first,
    );
    return all.where((item) => item.categoryId == category.id).toList();
  }

  Future<List<QuietTimeSession>> sessions() async {
    if (!SupabaseService.isInitialized) return mockSessions;
    try {
      final rows = await SupabaseService.client
          .from('quiet_time_sessions')
          .select('*, quiet_time_steps(*), quiet_time_video_chapters(*)')
          .eq('is_active', true)
          .eq('status', 'published')
          .order('sort_order');
      return (rows as List).map(_sessionFromMap).toList();
    } catch (_) {
      return mockSessions;
    }
  }

  Future<List<QuietTimeSession>> recommendedSessions({
    QuietTimeMood? mood,
  }) async {
    final all = await sessions();
    if (mood == null) return all.take(4).toList();
    final keyword = switch (mood) {
      QuietTimeMood.tempted => 'temptation',
      QuietTimeMood.alone => 'peace',
      QuietTimeMood.needStrength => 'strength',
      QuietTimeMood.needPeace => 'peace',
      QuietTimeMood.reset => 'reset',
      QuietTimeMood.grateful => 'gratitude',
      QuietTimeMood.silence => 'silent',
    };
    final filtered = all.where((session) {
      final haystack = '${session.title} ${session.description}'.toLowerCase();
      return haystack.contains(keyword);
    }).toList();
    return filtered.isEmpty ? all.take(4).toList() : filtered.take(4).toList();
  }

  Future<QuietTimeSession?> lastSession() async {
    if (!SupabaseService.isInitialized || SupabaseService.currentUser == null) {
      return mockSessions.first;
    }
    try {
      final row = await SupabaseService.client
          .from('quiet_time_history')
          .select('session_id,quiet_time_sessions(*)')
          .eq('user_id', SupabaseService.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return mockSessions.first;
      return _sessionFromMap(
        row['quiet_time_sessions'] as Map<String, dynamic>,
      );
    } catch (_) {
      return mockSessions.first;
    }
  }

  Future<QuietTimeHistorySummary> historySummary() async {
    if (!SupabaseService.isInitialized || SupabaseService.currentUser == null) {
      return mockHistorySummary;
    }
    try {
      final userId = SupabaseService.currentUser!.id;
      final historyRows = await SupabaseService.client
          .from('quiet_time_history')
          .select('*, quiet_time_sessions(title)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(24);
      final favoriteRows = await SupabaseService.client
          .from('quiet_time_favorites')
          .select('*, quiet_time_sessions(title)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(8);
      final history = (historyRows as List).map(_historyFromMap).toList();
      final favorites = (favoriteRows as List).map(_favoriteFromMap).toList();
      final totalSeconds = history
          .map((item) => item.durationCompletedSeconds)
          .fold<int>(0, (sum, value) => sum + value);
      final moodSummary = <String, int>{};
      for (final item in history) {
        final mood = item.moodAfter ?? item.moodBefore;
        if (mood == null || mood.isEmpty) continue;
        moodSummary[mood] = (moodSummary[mood] ?? 0) + 1;
      }
      return QuietTimeHistorySummary(
        totalSessions: history.where((item) => item.completed).length,
        totalMinutes: (totalSeconds / 60).round(),
        currentStreak: _estimateStreak(history),
        recentHistory: history.take(8).toList(),
        favorites: favorites,
        moodSummary: moodSummary,
      );
    } catch (_) {
      return mockHistorySummary;
    }
  }

  Future<void> createHistoryRecord({
    required String sessionId,
    required int durationSeconds,
    QuietTimeMood? moodBefore,
    QuietTimeMood? moodAfter,
    String? privateNote,
    bool sharedWithGroup = false,
    bool completed = true,
  }) async {
    if (!SupabaseService.isInitialized || SupabaseService.currentUser == null) {
      return;
    }
    await SupabaseService.client.from('quiet_time_history').insert({
      'user_id': SupabaseService.currentUser!.id,
      'session_id': sessionId,
      'mood_before': moodBefore?.key,
      'mood_after': moodAfter?.key,
      'duration_completed_seconds': durationSeconds,
      'completed': completed,
      'private_note': privateNote,
      'shared_with_group': sharedWithGroup,
    });
  }

  Future<bool> canAccessSession(QuietTimeSession session) async {
    return MonetizationService.instance.canAccessQuietTimeSession(session.id);
  }

  Future<bool> canAccessVideoSession(QuietTimeSession session) async {
    return MonetizationService.instance.canAccessQuietTimeVideo(session.id);
  }

  /// Returns a short-lived signed URL for a private video stored in Supabase.
  ///
  /// Primary path: Supabase-native signed URL (works for any authenticated
  /// user with SELECT on the quiet-time-videos bucket).
  /// Fallback: Laravel API endpoint (adds server-side entitlement re-check
  /// when BackendConfig.laravelApiBaseUrl is configured).
  Future<String?> signedVideoUrl(
    String sessionId, {
    String? storagePath,
  }) async {
    if (!SupabaseService.isInitialized) return null;

    // ── PRIMARY: Supabase-native signed URL ──────────────────────────────
    final path = storagePath;
    if (path != null && path.isNotEmpty) {
      try {
        final url = await SupabaseService.client.storage
            .from('quiet-time-videos')
            .createSignedUrl(path, 900);
        if (url.isNotEmpty) return url;
      } catch (_) {
        // Path known but signing failed; try Laravel fallback
      }
    }

    // ── FALLBACK: Laravel API with server-side entitlement check ─────────
    if (!BackendConfig.isConfigured) return null;
    final supaSession = SupabaseService.currentSession;
    final accessToken = supaSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) return null;

    final uri = Uri.parse(
      '${BackendConfig.laravelApiBaseUrl}/api/quiet-time/sessions/$sessionId/signed-video-url',
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) return null;
      final signedUrl = payload['signed_url'] as String?;
      if (signedUrl == null || signedUrl.isEmpty) return null;
      return signedUrl;
    } catch (_) {
      return null;
    }
  }

  Future<bool> canAccessAdvancedInsights() {
    return MonetizationService.instance.hasFeature(
      'quiet_time_advanced_insights',
    );
  }

  Future<bool> canUseOfflineSessions() {
    return MonetizationService.instance.hasFeature(
      'quiet_time_offline_sessions',
    );
  }

  int _estimateStreak(List<QuietTimeHistory> history) {
    if (history.isEmpty) return 0;
    final dates =
        history
            .where((item) => item.completed)
            .map(
              (item) => DateTime(
                item.createdAt.year,
                item.createdAt.month,
                item.createdAt.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    if (dates.isEmpty) return 0;
    var streak = 1;
    for (var i = 1; i < dates.length; i++) {
      final diff = dates[i - 1].difference(dates[i]).inDays;
      if (diff == 1) {
        streak += 1;
      } else if (diff > 1) {
        break;
      }
    }
    return streak;
  }

  QuietTimeCategory _categoryFromMap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    return QuietTimeCategory(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
      slug: (map['slug'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      icon: (map['icon'] as String?) ?? 'self_improvement',
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }

  QuietTimeStep _stepFromMap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    return QuietTimeStep(
      id: map['id'] as String,
      sessionId: (map['session_id'] as String?) ?? '',
      stepTitle: (map['step_title'] as String?) ?? 'Reflect',
      stepType: (map['step_type'] as String?) ?? 'reflection',
      content: (map['content'] as String?) ?? '',
      scriptureReference: map['scripture_reference'] as String?,
      durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 60,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  QuietTimeSession _sessionFromMap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    final stepsRaw = map['quiet_time_steps'] as List?;
    final chaptersRaw = map['quiet_time_video_chapters'] as List?;
    final steps = (stepsRaw ?? const []).map(_stepFromMap).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final chapters = (chaptersRaw ?? const []).map(_chapterFromMap).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return QuietTimeSession(
      id: map['id'] as String,
      categoryId: (map['category_id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      slug: (map['slug'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 5,
      sessionType: QuietTimeSessionTypeX.fromKey(
        (map['session_type'] as String?) ?? 'audio',
      ),
      status: (map['status'] as String?) ?? 'published',
      audioUrl: map['audio_url'] as String?,
      videoUrl: map['video_url'] as String?,
      videoStoragePath: map['video_storage_path'] as String?,
      videoProvider: map['video_provider'] as String?,
      backgroundImageUrl: map['background_image_url'] as String?,
      scriptureReference: map['scripture_reference'] as String?,
      reflectionPrompt: map['reflection_prompt'] as String?,
      difficultyLevel: map['difficulty_level'] as String?,
      isPremium: (map['is_premium'] as bool?) ?? false,
      isActive: (map['is_active'] as bool?) ?? true,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      steps: steps.isEmpty ? _defaultSteps(map['id'] as String) : steps,
      videoChapters: chapters,
    );
  }

  QuietTimeVideoChapter _chapterFromMap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    return QuietTimeVideoChapter(
      id: map['id'] as String,
      sessionId: (map['session_id'] as String?) ?? '',
      title: (map['title'] as String?) ?? 'Chapter',
      description: map['description'] as String?,
      startSeconds: (map['start_seconds'] as num?)?.toInt() ?? 0,
      endSeconds: (map['end_seconds'] as num?)?.toInt(),
      scriptureReference: map['scripture_reference'] as String?,
      reflectionPrompt: map['reflection_prompt'] as String?,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  QuietTimeHistory _historyFromMap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    final sessionMap = map['quiet_time_sessions'] as Map<String, dynamic>?;
    return QuietTimeHistory(
      id: map['id'] as String,
      userId: (map['user_id'] as String?) ?? '',
      sessionId: (map['session_id'] as String?) ?? '',
      moodBefore: map['mood_before'] as String?,
      moodAfter: map['mood_after'] as String?,
      durationCompletedSeconds:
          (map['duration_completed_seconds'] as num?)?.toInt() ?? 0,
      completed: (map['completed'] as bool?) ?? false,
      privateNote: map['private_note'] as String?,
      sharedWithGroup: (map['shared_with_group'] as bool?) ?? false,
      createdAt:
          DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
      sessionTitle: sessionMap?['title'] as String?,
    );
  }

  QuietTimeFavorite _favoriteFromMap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    final sessionMap = map['quiet_time_sessions'] as Map<String, dynamic>?;
    return QuietTimeFavorite(
      id: map['id'] as String,
      userId: (map['user_id'] as String?) ?? '',
      sessionId: (map['session_id'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
      sessionTitle: sessionMap?['title'] as String?,
    );
  }

  List<QuietTimeStep> _defaultSteps(String sessionId) {
    return [
      QuietTimeStep(
        id: '$sessionId-step-settle',
        sessionId: sessionId,
        stepTitle: 'Settle',
        stepType: 'settle',
        content:
            'Find a comfortable place and release tension from your shoulders.',
        durationSeconds: 60,
        sortOrder: 1,
      ),
      QuietTimeStep(
        id: '$sessionId-step-breathe',
        sessionId: sessionId,
        stepTitle: 'Breathe',
        stepType: 'breathing',
        content: 'Breathe in with gratitude, breathe out with surrender.',
        durationSeconds: 90,
        sortOrder: 2,
      ),
      QuietTimeStep(
        id: '$sessionId-step-reflect',
        sessionId: sessionId,
        stepTitle: 'Reflect',
        stepType: 'reflection',
        content:
            'Notice what your heart is carrying right now, without judgment.',
        scriptureReference: 'Psalm 46:10',
        durationSeconds: 120,
        sortOrder: 3,
      ),
      QuietTimeStep(
        id: '$sessionId-step-pray',
        sessionId: sessionId,
        stepTitle: 'Pray',
        stepType: 'prayer',
        content:
            'Offer this moment honestly to God and ask for the next right step.',
        durationSeconds: 120,
        sortOrder: 4,
      ),
      QuietTimeStep(
        id: '$sessionId-step-journal',
        sessionId: sessionId,
        stepTitle: 'Journal',
        stepType: 'journal',
        content: 'Write one prayer and one action for today.',
        durationSeconds: 90,
        sortOrder: 5,
      ),
    ];
  }

  static const mockCategories = [
    QuietTimeCategory(
      id: 'qt-cat-guided-prayer',
      name: 'Guided Prayer',
      slug: 'guided-prayer',
      description: 'Spirit-led prayer prompts for calm focus and trust.',
      icon: 'volunteer_activism',
      sortOrder: 1,
    ),
    QuietTimeCategory(
      id: 'qt-cat-scripture-meditation',
      name: 'Scripture Meditation',
      slug: 'scripture-meditation',
      description: 'Slow scripture reflection with gentle stillness.',
      icon: 'menu_book',
      sortOrder: 2,
    ),
    QuietTimeCategory(
      id: 'qt-cat-silent-reflection',
      name: 'Silent Reflection',
      slug: 'silent-reflection',
      description: 'Timed quiet with breathing prayer and optional verse.',
      icon: 'self_improvement',
      sortOrder: 3,
    ),
    QuietTimeCategory(
      id: 'qt-cat-recovery-reset',
      name: 'Recovery Reset',
      slug: 'recovery-reset',
      description: 'Gentle reset when tempted, tired, or discouraged.',
      icon: 'restart_alt',
      sortOrder: 4,
    ),
    QuietTimeCategory(
      id: 'qt-cat-gratitude',
      name: 'Gratitude',
      slug: 'gratitude',
      description: 'Give thanks for grace, progress, and provision.',
      icon: 'favorite',
      sortOrder: 5,
    ),
    QuietTimeCategory(
      id: 'qt-cat-night-peace',
      name: 'Night Peace',
      slug: 'night-peace',
      description: 'End your day in peace, prayer, and surrender.',
      icon: 'nights_stay',
      sortOrder: 6,
    ),
    QuietTimeCategory(
      id: 'qt-cat-morning-strength',
      name: 'Morning Strength',
      slug: 'morning-strength',
      description: 'Start your day anchored in strength and scripture.',
      icon: 'wb_sunny',
      sortOrder: 7,
    ),
    QuietTimeCategory(
      id: 'qt-cat-surrender',
      name: 'Surrender',
      slug: 'surrender',
      description: 'Lay down burdens and receive God’s peace.',
      icon: 'front_hand',
      sortOrder: 8,
    ),
  ];

  static const mockSessions = [
    QuietTimeSession(
      id: 'qt-s-1',
      categoryId: 'qt-cat-silent-reflection',
      title: '3-Minute Stillness',
      slug: '3-minute-stillness',
      description: 'A short quiet pause to breathe, settle, and reconnect.',
      durationMinutes: 3,
      sessionType: QuietTimeSessionType.video,
      status: 'published',
      videoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      videoProvider: 'sample',
      isPremium: false,
      isActive: true,
      sortOrder: 1,
      videoChapters: [
        QuietTimeVideoChapter(
          id: 'qt-c-1',
          sessionId: 'qt-s-1',
          title: 'Breathe and Settle',
          startSeconds: 0,
          sortOrder: 1,
          scriptureReference: 'Psalm 46:10',
        ),
        QuietTimeVideoChapter(
          id: 'qt-c-2',
          sessionId: 'qt-s-1',
          title: 'Quiet Reflection',
          startSeconds: 70,
          sortOrder: 2,
          reflectionPrompt: 'What do you need to surrender right now?',
        ),
      ],
    ),
    QuietTimeSession(
      id: 'qt-s-2',
      categoryId: 'qt-cat-morning-strength',
      title: 'Morning Strength Prayer',
      slug: 'morning-strength-prayer',
      description: 'Start strong with scripture, prayer, and intention.',
      durationMinutes: 5,
      isPremium: false,
      isActive: true,
      sortOrder: 2,
    ),
    QuietTimeSession(
      id: 'qt-s-3',
      categoryId: 'qt-cat-recovery-reset',
      title: 'Reset With Grace',
      slug: 'reset-with-grace',
      description: 'Pause after a hard moment and take the next faithful step.',
      durationMinutes: 7,
      isPremium: false,
      isActive: true,
      sortOrder: 3,
    ),
    QuietTimeSession(
      id: 'qt-s-4',
      categoryId: 'qt-cat-gratitude',
      title: 'Gratitude Reflection',
      slug: 'gratitude-reflection',
      description: 'Name today’s mercies and end with hopeful prayer.',
      durationMinutes: 6,
      isPremium: false,
      isActive: true,
      sortOrder: 4,
    ),
    QuietTimeSession(
      id: 'qt-s-5',
      categoryId: 'qt-cat-guided-prayer',
      title: '21-Day Quiet Time Journey',
      slug: '21-day-quiet-time-journey',
      description: 'A premium guided video path for spiritual consistency.',
      durationMinutes: 12,
      sessionType: QuietTimeSessionType.video,
      status: 'published',
      videoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      videoProvider: 'sample',
      isPremium: true,
      isActive: true,
      sortOrder: 5,
      videoChapters: [
        QuietTimeVideoChapter(
          id: 'qt-c-5',
          sessionId: 'qt-s-5',
          title: 'Opening Prayer',
          startSeconds: 0,
          sortOrder: 1,
          scriptureReference: 'Matthew 11:28',
        ),
        QuietTimeVideoChapter(
          id: 'qt-c-6',
          sessionId: 'qt-s-5',
          title: 'Scripture Meditation',
          startSeconds: 180,
          sortOrder: 2,
        ),
      ],
    ),
    QuietTimeSession(
      id: 'qt-s-6',
      categoryId: 'qt-cat-night-peace',
      title: 'Night Peace Audio Prayer',
      slug: 'night-peace-audio-prayer',
      description: 'A calm prayer flow to release anxiety before sleep.',
      durationMinutes: 10,
      isPremium: true,
      isActive: true,
      sortOrder: 6,
    ),
    QuietTimeSession(
      id: 'qt-s-7',
      categoryId: 'qt-cat-recovery-reset',
      title: 'Strength Before Temptation',
      slug: 'strength-before-temptation',
      description: 'Ground your next decision in truth, grace, and support.',
      durationMinutes: 8,
      isPremium: true,
      isActive: true,
      sortOrder: 7,
    ),
    QuietTimeSession(
      id: 'qt-s-8',
      categoryId: 'qt-cat-surrender',
      title: 'Surrender the Struggle',
      slug: 'surrender-the-struggle',
      description: 'Release shame and surrender burdens in prayer.',
      durationMinutes: 9,
      isPremium: true,
      isActive: true,
      sortOrder: 8,
    ),
    QuietTimeSession(
      id: 'qt-s-9',
      categoryId: 'qt-cat-scripture-meditation',
      title: 'Deep Scripture Stillness',
      slug: 'deep-scripture-stillness',
      description: 'Meditate deeply on scripture with guided silence.',
      durationMinutes: 10,
      isPremium: true,
      isActive: true,
      sortOrder: 9,
    ),
    QuietTimeSession(
      id: 'qt-s-10',
      categoryId: 'qt-cat-recovery-reset',
      title: 'Guided Recovery Reset',
      slug: 'guided-recovery-reset',
      description:
          'A longer recovery reset with prayer and private reflection.',
      durationMinutes: 11,
      isPremium: true,
      isActive: true,
      sortOrder: 10,
    ),
    QuietTimeSession(
      id: 'qt-s-11',
      categoryId: 'qt-cat-scripture-meditation',
      title: '10-Minute Scripture Stillness',
      slug: '10-minute-scripture-stillness',
      description: 'Rest in one passage and listen quietly.',
      durationMinutes: 10,
      isPremium: false,
      isActive: true,
      sortOrder: 11,
    ),
    QuietTimeSession(
      id: 'qt-s-12',
      categoryId: 'qt-cat-silent-reflection',
      title: 'Silent Reflection Timer',
      slug: 'silent-reflection-timer',
      description: 'Choose your own timer and practice stillness with prayer.',
      durationMinutes: 5,
      isPremium: false,
      isActive: true,
      sortOrder: 12,
    ),
    QuietTimeSession(
      id: 'qt-s-13',
      categoryId: 'qt-cat-guided-prayer',
      title: 'Breathe and Pray',
      slug: 'breathe-and-pray',
      description: 'Simple breath prayer for calm and clarity.',
      durationMinutes: 7,
      isPremium: false,
      isActive: true,
      sortOrder: 13,
    ),
    QuietTimeSession(
      id: 'qt-s-14',
      categoryId: 'qt-cat-night-peace',
      title: 'Gratitude Before Sleep',
      slug: 'gratitude-before-sleep',
      description: 'Close your day with gratitude and trust.',
      durationMinutes: 8,
      isPremium: false,
      isActive: true,
      sortOrder: 14,
    ),
  ];

  static final mockHistorySummary = QuietTimeHistorySummary(
    totalSessions: 18,
    totalMinutes: 142,
    currentStreak: 6,
    recentHistory: [
      QuietTimeHistory(
        id: 'qt-h-1',
        userId: 'mock-user',
        sessionId: 'qt-s-3',
        sessionTitle: 'Reset With Grace',
        moodBefore: 'tempted',
        moodAfter: 'need_peace',
        durationCompletedSeconds: 420,
        completed: true,
        sharedWithGroup: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      QuietTimeHistory(
        id: 'qt-h-2',
        userId: 'mock-user',
        sessionId: 'qt-s-2',
        sessionTitle: 'Morning Strength Prayer',
        moodBefore: 'need_strength',
        moodAfter: 'grateful',
        durationCompletedSeconds: 300,
        completed: true,
        sharedWithGroup: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      QuietTimeHistory(
        id: 'qt-h-3',
        userId: 'mock-user',
        sessionId: 'qt-s-12',
        sessionTitle: 'Silent Reflection Timer',
        moodBefore: 'alone',
        moodAfter: 'need_peace',
        durationCompletedSeconds: 600,
        completed: true,
        sharedWithGroup: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ],
    favorites: [
      QuietTimeFavorite(
        id: 'qt-f-1',
        userId: 'mock-user',
        sessionId: 'qt-s-2',
        sessionTitle: 'Morning Strength Prayer',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      QuietTimeFavorite(
        id: 'qt-f-2',
        userId: 'mock-user',
        sessionId: 'qt-s-13',
        sessionTitle: 'Breathe and Pray',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ],
    moodSummary: const {
      'need_peace': 8,
      'grateful': 5,
      'need_strength': 3,
      'reset': 2,
    },
  );
}

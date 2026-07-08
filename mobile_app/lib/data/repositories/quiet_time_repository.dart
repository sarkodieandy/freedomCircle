import '../../features/quiet_time/quiet_time_models.dart';
import '../../features/quiet_time/quiet_time_repository.dart' as qt;
import '../supabase/supabase_service.dart';

class QuietTimeRepository extends qt.QuietTimeRepository {
  const QuietTimeRepository();

  Future<List<QuietTimeCategory>> getQuietTimeCategories() => categories();

  Future<List<QuietTimeSession>> getQuietTimeSessions() => sessions();

  Future<QuietTimeSession?> getSessionById(String sessionId) async {
    final all = await sessions();
    for (final session in all) {
      if (session.id == sessionId) return session;
    }
    return null;
  }

  Future<List<QuietTimeStep>> getSessionSteps(String sessionId) async {
    final session = await getSessionById(sessionId);
    return session?.steps ?? const <QuietTimeStep>[];
  }

  Future<void> startQuietTimeSession({
    required String sessionId,
    QuietTimeMood? moodBefore,
  }) async {
    // TODO(analytics): persist session start analytics event server-side.
  }

  Future<void> completeQuietTimeSession({
    required String sessionId,
    required int durationSeconds,
    QuietTimeMood? moodBefore,
    QuietTimeMood? moodAfter,
    String? privateNote,
    bool sharedWithGroup = false,
  }) {
    return createHistoryRecord(
      sessionId: sessionId,
      durationSeconds: durationSeconds,
      moodBefore: moodBefore,
      moodAfter: moodAfter,
      privateNote: privateNote,
      sharedWithGroup: sharedWithGroup,
      completed: true,
    );
  }

  Future<QuietTimeHistorySummary> getQuietTimeHistory() => historySummary();

  Future<void> favoriteSession({
    required String userId,
    required String sessionId,
  }) {
    if (!SupabaseService.isInitialized) return Future.value();
    return SupabaseService.client.from('quiet_time_favorites').upsert({
      'user_id': userId,
      'session_id': sessionId,
    }, onConflict: 'user_id,session_id');
  }

  Future<void> unfavoriteSession({
    required String userId,
    required String sessionId,
  }) {
    if (!SupabaseService.isInitialized) return Future.value();
    return SupabaseService.client
        .from('quiet_time_favorites')
        .delete()
        .eq('user_id', userId)
        .eq('session_id', sessionId);
  }
}

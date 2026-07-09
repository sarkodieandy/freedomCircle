import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import 'supabase_config.dart';

class SupabaseService {
  const SupabaseService._();

  static bool _initialized = false;

  static bool get isConfigured => SupabaseConfig.isConfigured;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized || !SupabaseConfig.isConfigured) {
      AppLogger.supabase(
        'Supabase initialization skipped',
        data: {
          'already_initialized': _initialized,
          'configured': SupabaseConfig.isConfigured,
        },
      );
      return;
    }

    try {
      AppLogger.supabase(
        'Supabase initialization started',
        data: {'module': 'SupabaseService.initialize'},
      );
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      );
      _initialized = true;
      AppLogger.supabase('Supabase initialization success');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Supabase initialization failed',
        tag: 'SUPABASE',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'Supabase is not initialized. Start Flutter with '
        '${SupabaseConfig.dartDefineHelp}.',
      );
    }

    return Supabase.instance.client;
  }

  static User? get currentUser =>
      _initialized ? Supabase.instance.client.auth.currentUser : null;

  static Session? get currentSession =>
      _initialized ? Supabase.instance.client.auth.currentSession : null;

  static bool get isLoggedIn => currentUser != null;

  static String? get currentUserId => currentUser?.id;

  static Stream<AuthState> get authStateChanges {
    if (!_initialized) {
      return const Stream<AuthState>.empty();
    }

    return Supabase.instance.client.auth.onAuthStateChange;
  }

  static Future<void> signOut() async {
    if (!_initialized) {
      AppLogger.auth('Sign out skipped because Supabase is not initialized');
      return;
    }

    AppLogger.auth(
      'Logout started',
      data: {'source': 'SupabaseService.signOut'},
    );
    await Supabase.instance.client.auth.signOut();
    AppLogger.auth(
      'Logout success',
      data: {'source': 'SupabaseService.signOut'},
    );
  }

  static Future<void> refreshSession() async {
    if (!_initialized) return;
    AppLogger.auth('Session refresh started');
    await Supabase.instance.client.auth.refreshSession();
    AppLogger.auth('Session refresh success');
  }
}

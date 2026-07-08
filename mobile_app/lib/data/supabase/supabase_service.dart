import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class SupabaseService {
  const SupabaseService._();

  static bool _initialized = false;

  static bool get isConfigured => SupabaseConfig.isConfigured;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized || !SupabaseConfig.isConfigured) {
      return;
    }

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    _initialized = true;
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

  static Stream<AuthState> get authStateChanges {
    if (!_initialized) {
      return const Stream<AuthState>.empty();
    }

    return Supabase.instance.client.auth.onAuthStateChange;
  }

  static Future<void> signOut() async {
    if (!_initialized) {
      return;
    }

    await Supabase.instance.client.auth.signOut();
  }
}

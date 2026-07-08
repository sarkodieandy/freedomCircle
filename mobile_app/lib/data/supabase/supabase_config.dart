class SupabaseConfig {
  const SupabaseConfig._();

  // Provide values via --dart-define, never hardcode secrets in source.
  // Example:
  // flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static const dartDefineHelp =
      '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...';
}

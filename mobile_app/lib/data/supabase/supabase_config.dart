class SupabaseConfig {
  const SupabaseConfig._();

  // Provide values via --dart-define, never hardcode secrets in source.
  // Example:
  // flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bwfwzhzjvggntmyceezs.supabase.co',
  );
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ3Znd6aHpqdmdnbnRteWNlZXpzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM0MTUxNzgsImV4cCI6MjA5ODk5MTE3OH0.AEaMrkzKxmghl7kH_8CTRS4B5mdudwYK-xis_AcO0_A',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static const dartDefineHelp =
      '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... '
      'or --dart-define-from-file=.env.local.json';
}

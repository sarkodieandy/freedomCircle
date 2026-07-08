class BackendConfig {
  const BackendConfig._();

  static const laravelApiBaseUrl = String.fromEnvironment(
    'LARAVEL_API_BASE_URL',
  );

  static bool get isConfigured => laravelApiBaseUrl.isNotEmpty;

  static String get dartDefineHelp =>
      '--dart-define=LARAVEL_API_BASE_URL=https://your-domain.com';
}

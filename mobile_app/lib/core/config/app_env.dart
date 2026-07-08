class AppEnv {
  const AppEnv._();

  static const useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: false,
  );
}

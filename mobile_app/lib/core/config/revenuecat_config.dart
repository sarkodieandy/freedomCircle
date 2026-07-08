class RevenueCatConfig {
  const RevenueCatConfig._();

  static const revenueCatIosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
  );
  static const revenueCatAndroidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );

  static const entitlementPremium = 'premium';
  static const defaultOfferingId = 'default';

  static String get dartDefineHelp =>
      '--dart-define=REVENUECAT_IOS_API_KEY=... '
      '--dart-define=REVENUECAT_ANDROID_API_KEY=...';

  static String apiKeyForPlatform({
    required bool isIOS,
    required bool isAndroid,
  }) {
    if (isIOS) {
      if (revenueCatIosApiKey.isEmpty) {
        throw StateError(
          'RevenueCat iOS API key is missing. Start Flutter with '
          '$dartDefineHelp.',
        );
      }
      return revenueCatIosApiKey;
    }

    if (isAndroid) {
      if (revenueCatAndroidApiKey.isEmpty) {
        throw StateError(
          'RevenueCat Android API key is missing. Start Flutter with '
          '$dartDefineHelp.',
        );
      }
      return revenueCatAndroidApiKey;
    }

    throw UnsupportedError(
      'RevenueCat is only supported on iOS and Android in this app.',
    );
  }
}

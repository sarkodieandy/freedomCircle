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

  static const productPremiumWeekly = 'freedomcircle_premium_weekly';
  static const productPremiumMonthly = 'freedomcircle_premium_monthly';
  static const productPremiumYearly = 'freedomcircle_premium_yearly';

  static const planFree = 'free';
  static const planPremiumWeekly = 'premium_weekly';
  static const planPremiumMonthly = 'premium_monthly';
  static const planPremiumYearly = 'premium_yearly';

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

  static String planCodeForProductId(String productId) {
    switch (productId) {
      case productPremiumWeekly:
        return planPremiumWeekly;
      case productPremiumMonthly:
        return planPremiumMonthly;
      case productPremiumYearly:
        return planPremiumYearly;
      default:
        return planFree;
    }
  }
}

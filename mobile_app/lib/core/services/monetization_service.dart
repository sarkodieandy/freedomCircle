import '../../data/models/monetization_models.dart';
import '../../data/models/revenuecat_models.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/supabase/supabase_service.dart';
import '../config/revenuecat_config.dart';
import '../utils/app_logger.dart';

class MonetizationService {
  const MonetizationService._();

  static const instance = MonetizationService._();

  static const premiumFeatureKeys = {
    'premium_access',
    'recovery_goals_unlimited',
    'advanced_recovery_insights',
    'premium_groups',
    'unlimited_journal',
    'quiet_time_premium_library',
    'quiet_time_premium_video_library',
    'quiet_time_video_practice',
    'quiet_time_video_downloads',
    'quiet_time_advanced_insights',
    'helper_matching',
    'guided_programs',
    'private_anonymous_controls',
    'milestone_badges',
    'advanced_streak_calendar',
    'priority_support_prompts',
  };

  static const _defaultFreeRecoveryGoalLimit = 1;
  static const _defaultFreeGroupJoinLimit = 2;
  static const _defaultFreeJournalEntryLimit = 5;
  static const _defaultFreeQuietTimeSessionLimit = 4;

  static const _subscriptionRepository = SubscriptionRepository();

  static CustomerPremiumStatus? _cachedPremiumStatus;

  Future<void> initializePremiumWatcher() async {
    AppLogger.payment(
      'Payment request started',
      data: {'source': 'MonetizationService.initializePremiumWatcher'},
    );
    _subscriptionRepository.watchPremiumStatus().listen((status) {
      _cachedPremiumStatus = status;
      AppLogger.info(
        status.isPremium
            ? 'Premium entitlement active'
            : 'Premium entitlement inactive',
        tag: 'REVENUECAT',
        data: {'user_id': status.userId},
      );
    });
    await refreshEntitlements();
  }

  Future<void> refreshEntitlements() async {
    if (!SupabaseService.isInitialized ||
        SupabaseService.currentUserId == null) {
      AppLogger.warning(
        'Entitlement refresh skipped',
        tag: 'PAYMENT',
        data: {'initialized': SupabaseService.isInitialized},
      );
      return;
    }

    AppLogger.payment(
      'Payment verification waiting',
      data: {'source': 'MonetizationService.refreshEntitlements'},
    );
    final status = await _subscriptionRepository.getCustomerStatus();
    _cachedPremiumStatus = status;
    await _subscriptionRepository.syncPremiumStatusToSupabase();
    AppLogger.payment(
      'Booking payment status updated',
      data: {
        'is_premium': status.isPremium,
        'source': 'MonetizationService.refreshEntitlements',
      },
    );
  }

  Future<bool> _isRevenueCatPremium() async {
    if (_cachedPremiumStatus != null) {
      return _cachedPremiumStatus!.isPremium;
    }

    final status = await _subscriptionRepository.getCustomerStatus();
    _cachedPremiumStatus = status;
    return status.isPremium;
  }

  Future<bool> hasFeature(String featureKey) async {
    final userId = SupabaseService.currentUser?.id;
    if (!SupabaseService.isInitialized || userId == null) {
      return !premiumFeatureKeys.contains(featureKey);
    }

    if (!premiumFeatureKeys.contains(featureKey)) {
      return true;
    }

    if (premiumFeatureKeys.contains(featureKey) &&
        await _isRevenueCatPremium()) {
      return true;
    }

    final freeToggle = await _readSettingBool(
      'free_$featureKey',
      fallback: false,
    );
    if (freeToggle) return true;

    final result = await SupabaseService.client.rpc<bool>(
      'verify_entitlement',
      params: {'user_uuid': userId, 'feature': featureKey},
    );
    return result;
  }

  Future<bool> canJoinGroup(String groupId) async {
    if (!SupabaseService.isInitialized) return true;
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;
    final freeLimit = await _readSettingInt(
      'free_group_join_limit',
      fallback: _defaultFreeGroupJoinLimit,
    );

    final rows = await SupabaseService.client
        .from('group_members')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'approved');

    final currentCount = (rows as List).length;
    await _trackFeatureUsage('groups_joined', value: currentCount);
    if (currentCount < freeLimit) return true;

    await trackPaywallView('groups', 'premium_groups');
    return hasFeature('premium_groups');
  }

  Future<bool> canCreateRecoveryGoal() async {
    if (!SupabaseService.isInitialized) return false;
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;
    if (await hasFeature('recovery_goals_unlimited')) return true;

    final freeLimit = await _readSettingInt(
      'free_recovery_goal_limit',
      fallback: _defaultFreeRecoveryGoalLimit,
    );

    final rows = await SupabaseService.client
        .from('user_recovery_goals')
        .select('id')
        .eq('user_id', userId);

    final currentCount = (rows as List).length;
    await _trackFeatureUsage('recovery_goals_created', value: currentCount);
    if (currentCount >= freeLimit) {
      await trackPaywallView('recovery', 'recovery_goals_unlimited');
    }

    return currentCount < freeLimit;
  }

  Future<bool> canAccessPremiumGroup(String groupId) {
    return hasFeature('premium_groups');
  }

  Future<bool> canAccessPremiumQuietTimeSession(String sessionId) {
    return canAccessQuietTimeSession(sessionId);
  }

  Future<bool> canAccessQuietTimeVideo(String sessionId) async {
    if (!SupabaseService.isInitialized) return true;
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    final session = await SupabaseService.client
        .from('quiet_time_sessions')
        .select('is_premium,session_type')
        .eq('id', sessionId)
        .maybeSingle();

    final isVideo = (session?['session_type'] as String?) == 'video';
    if (!isVideo) {
      return canAccessQuietTimeSession(sessionId);
    }

    final isPremiumSession = (session?['is_premium'] as bool?) ?? false;
    if (!isPremiumSession) return true;

    await trackPaywallView(
      'quiet_time_video',
      'quiet_time_premium_video_library',
    );
    final hasVideoPremium = await hasFeature(
      'quiet_time_premium_video_library',
    );
    if (hasVideoPremium) return true;
    return hasFeature('quiet_time_premium_library');
  }

  Future<bool> canAccessPremiumQuietTimeVideos() {
    return hasFeature('quiet_time_premium_video_library');
  }

  Future<bool> canDownloadQuietTimeVideo(String sessionId) async {
    final canAccess = await canAccessQuietTimeVideo(sessionId);
    if (!canAccess) return false;
    return hasFeature('quiet_time_video_downloads');
  }

  Future<void> showPaywallForQuietTimeVideo(String sessionId) {
    return showPaywallForFeature('quiet_time_premium_video_library');
  }

  Future<bool> canUseAdvancedRecoveryInsights() {
    return hasFeature('advanced_recovery_insights');
  }

  Future<bool> canUseAdvancedInsights() => canUseAdvancedRecoveryInsights();

  Future<bool> canCreateJournalEntry() async {
    if (await hasFeature('unlimited_journal')) return true;
    if (!SupabaseService.isInitialized) return false;
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;
    final rows = await SupabaseService.client
        .from('journal_entries')
        .select('id')
        .eq('user_id', userId);

    final freeLimit = await _readSettingInt(
      'free_journal_entry_limit',
      fallback: _defaultFreeJournalEntryLimit,
    );

    final currentCount = (rows as List).length;
    await _trackFeatureUsage('journal_entries_created', value: currentCount);
    if (currentCount >= freeLimit) {
      await trackPaywallView('journal', 'unlimited_journal');
    }

    return currentCount < freeLimit;
  }

  Future<bool> canAccessQuietTimeSession(String sessionId) async {
    if (!SupabaseService.isInitialized) return true;
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    final session = await SupabaseService.client
        .from('quiet_time_sessions')
        .select('is_premium')
        .eq('id', sessionId)
        .maybeSingle();

    final isPremiumSession = (session?['is_premium'] as bool?) ?? false;
    if (isPremiumSession) {
      await trackPaywallView('quiet_time', 'quiet_time_premium_library');
      return hasFeature('quiet_time_premium_library');
    }

    if (await _isRevenueCatPremium()) return true;

    final freeLimit = await _readSettingInt(
      'free_quiet_time_session_limit',
      fallback: _defaultFreeQuietTimeSessionLimit,
    );

    final history = await SupabaseService.client
        .from('quiet_time_history')
        .select('id')
        .eq('user_id', userId)
        .eq('completed', true);

    final completedCount = (history as List).length;
    await _trackFeatureUsage(
      'quiet_time_sessions_completed',
      value: completedCount,
    );
    if (completedCount >= freeLimit) {
      await trackPaywallView('quiet_time', 'quiet_time_premium_library');
      return false;
    }

    return true;
  }

  Future<bool> canUseHelperMatching() => hasFeature('helper_matching');

  Future<bool> canAccessGuidedProgram(String programId) {
    return canAccessProgram(programId);
  }

  Future<bool> canAccessProgram(String programId) async {
    if (!SupabaseService.isInitialized) return false;
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;
    final row = await SupabaseService.client
        .from('paid_programs')
        .select('price,is_premium_included')
        .eq('id', programId)
        .maybeSingle();
    if (row == null) return false;
    if ((row['price'] as num? ?? 0) == 0) return true;
    if (row['is_premium_included'] == true &&
        await hasFeature('guided_programs')) {
      return true;
    }
    final purchase = await SupabaseService.client
        .from('program_purchases')
        .select('id')
        .eq('user_id', userId)
        .eq('program_id', programId)
        .eq('access_status', 'active')
        .maybeSingle();
    return purchase != null;
  }

  Future<bool> isPremiumUser() => _isRevenueCatPremium();

  Future<String> getCurrentPlan() async {
    if (!SupabaseService.isInitialized ||
        SupabaseService.currentUserId == null) {
      return RevenueCatConfig.planFree;
    }

    final status =
        _cachedPremiumStatus ??
        await _subscriptionRepository.getCustomerStatus();
    _cachedPremiumStatus = status;

    if (!status.isPremium) return RevenueCatConfig.planFree;

    final activeIds = status.activeProductIds;
    if (activeIds.contains(RevenueCatConfig.productPremiumYearly)) {
      return RevenueCatConfig.planPremiumYearly;
    }
    if (activeIds.contains(RevenueCatConfig.productPremiumMonthly)) {
      return RevenueCatConfig.planPremiumMonthly;
    }
    if (activeIds.contains(RevenueCatConfig.productPremiumWeekly)) {
      return RevenueCatConfig.planPremiumWeekly;
    }

    return RevenueCatConfig.planPremiumMonthly;
  }

  Future<void> showPaywallForFeature(String featureKey) async {
    await _trackPaywallEvent(
      screen: 'feature_gate',
      featureKey: featureKey,
      eventType: 'viewed',
    );
    await _trackFeatureUsage('premium_feature_taps');
  }

  Future<void> openPaywallForFeature(String featureKey) {
    return showPaywallForFeature(featureKey);
  }

  Future<bool> isChurchPlanActive(String organizationId) async {
    if (!SupabaseService.isInitialized) return false;
    final result = await SupabaseService.client.rpc<bool>(
      'verify_org_entitlement',
      params: {'org_uuid': organizationId, 'feature': 'church_private_groups'},
    );
    return result;
  }

  Future<void> trackPaywallView(String screen, String featureKey) {
    return _trackPaywallEvent(
      screen: screen,
      featureKey: featureKey,
      eventType: 'viewed',
    );
  }

  Future<void> trackUpgradeClick(String screen, String planCode) {
    _trackFeatureUsage('upgrade_clicks');
    return _trackPaywallEvent(
      screen: screen,
      featureKey: 'upgrade',
      eventType: 'clicked_upgrade',
      planCode: planCode,
    );
  }

  Future<void> trackPurchaseStarted(String screen, String planCode) {
    _trackFeatureUsage('purchase_started');
    return _trackPaywallEvent(
      screen: screen,
      featureKey: 'premium_access',
      eventType: 'purchase_started',
      planCode: planCode,
    );
  }

  Future<void> trackPurchaseResult({
    required String screen,
    required String planCode,
    required PurchaseResult result,
  }) {
    final eventType = result.cancelled
        ? 'dismissed'
        : (result.success ? 'purchased' : 'purchase_failed');

    _trackFeatureUsage(
      result.success
          ? 'purchase_success'
          : (result.cancelled ? 'purchase_cancelled' : 'purchase_failed'),
    );

    return _trackPaywallEvent(
      screen: screen,
      featureKey: 'premium_access',
      eventType: eventType,
      planCode: planCode,
      metadata: {
        'status': result.status,
        if (result.message != null) 'message': result.message,
      },
    );
  }

  Future<void> trackRestoreStarted(String screen) {
    return _trackPaywallEvent(
      screen: screen,
      featureKey: 'premium_access',
      eventType: 'viewed',
      metadata: const {'action': 'restore_started'},
    );
  }

  Future<void> trackRestoreResult(String screen, PurchaseResult result) {
    return _trackPaywallEvent(
      screen: screen,
      featureKey: 'premium_access',
      eventType: 'restored',
      metadata: {
        'restore_outcome': result.success ? 'success' : 'failed',
        'status': result.status,
        if (result.message != null) 'message': result.message,
      },
    );
  }

  Future<List<MonetizationPlan>> plans({String? type}) async {
    if (!SupabaseService.isInitialized) return mockPlans;
    var query = SupabaseService.client
        .from('plans')
        .select('*, plan_features(*)')
        .eq('is_active', true);
    if (type != null) query = query.eq('plan_type', type);
    final rows = await query.order('sort_order');
    return (rows as List)
        .map((row) => MonetizationPlan.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<PaidProgram>> paidPrograms() async {
    if (!SupabaseService.isInitialized) return mockPrograms;
    final rows = await SupabaseService.client
        .from('paid_programs')
        .select('*, program_modules(*, program_lessons(*))')
        .eq('status', 'active')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => PaidProgram.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<CoachEarningsSummary> coachEarningsSummary(String helperId) async {
    if (!SupabaseService.isInitialized) return mockCoachEarnings;
    final row = await SupabaseService.client
        .from('helper_earnings_summary')
        .select()
        .eq('helper_id', helperId)
        .maybeSingle();
    if (row == null) return mockCoachEarnings;
    return CoachEarningsSummary.fromMap(Map<String, dynamic>.from(row));
  }

  Future<AdminRevenueSummary> adminRevenueSummary() async {
    if (!SupabaseService.isInitialized) return mockAdminRevenue;
    final revenue = await SupabaseService.client
        .from('admin_revenue_summary')
        .select()
        .maybeSingle();
    final mrr = await SupabaseService.client
        .from('admin_mrr_summary')
        .select()
        .maybeSingle();
    return AdminRevenueSummary.fromMaps(
      revenue: Map<String, dynamic>.from(revenue ?? const {}),
      mrr: Map<String, dynamic>.from(mrr ?? const {}),
    );
  }

  Future<void> _trackPaywallEvent({
    required String screen,
    required String featureKey,
    required String eventType,
    String? planCode,
    Map<String, dynamic>? metadata,
  }) async {
    if (!SupabaseService.isInitialized) return;
    AppLogger.payment(
      'Payment reference created',
      data: {
        'screen': screen,
        'feature_key': featureKey,
        'event_type': eventType,
        'plan_code': planCode,
      },
    );
    await SupabaseService.client.from('paywall_events').insert({
      'user_id': SupabaseService.currentUser?.id,
      'screen': screen,
      'feature_key': featureKey,
      'event_type': eventType,
      'plan_code': planCode,
      'metadata': metadata ?? const {},
    });
  }

  Future<int> _readSettingInt(String key, {required int fallback}) async {
    final value = await _readSettingValue(key);
    if (value is num) return value.toInt();

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final fromLimit = (map['limit'] as num?)?.toInt();
      final fromAmount = (map['amount'] as num?)?.toInt();
      return fromLimit ?? fromAmount ?? fallback;
    }

    return fallback;
  }

  Future<bool> _readSettingBool(String key, {required bool fallback}) async {
    final value = await _readSettingValue(key);
    if (value is bool) return value;

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final enabled = map['enabled'];
      if (enabled is bool) return enabled;
    }

    return fallback;
  }

  Future<dynamic> _readSettingValue(String key) async {
    if (!SupabaseService.isInitialized) return null;

    final row = await SupabaseService.client
        .from('app_settings')
        .select('value')
        .eq('key', key)
        .maybeSingle();

    return row?['value'];
  }

  Future<void> _trackFeatureUsage(String featureKey, {int? value}) async {
    if (!SupabaseService.isInitialized) return;

    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final periodStart = DateTime.now().toIso8601String().split('T').first;
    final existing = await SupabaseService.client
        .from('feature_usage')
        .select('id,usage_count')
        .eq('user_id', userId)
        .eq('feature_key', featureKey)
        .eq('usage_period', 'daily')
        .eq('period_start', periodStart)
        .maybeSingle();

    if (existing == null) {
      await SupabaseService.client.from('feature_usage').insert({
        'user_id': userId,
        'feature_key': featureKey,
        'usage_count': value ?? 1,
        'usage_period': 'daily',
        'period_start': periodStart,
      });
      return;
    }

    final current = (existing['usage_count'] as num?)?.toInt() ?? 0;
    await SupabaseService.client
        .from('feature_usage')
        .update({'usage_count': value ?? (current + 1)})
        .eq('id', existing['id'] as String);
  }

  static const mockPlans = [
    MonetizationPlan(
      id: 'free',
      code: 'free',
      name: 'Free',
      description: 'Build trust and daily habits with core growth tools.',
      planType: 'user',
      billingInterval: 'free',
      price: 0,
      currency: 'USD',
      trialDays: 0,
    ),
    MonetizationPlan(
      id: 'premium_weekly',
      code: 'premium_weekly',
      name: 'Premium Weekly',
      description: 'Try Premium for a week and unlock deeper support.',
      planType: 'user',
      billingInterval: 'weekly',
      price: 3,
      currency: 'USD',
      trialDays: 0,
    ),
    MonetizationPlan(
      id: 'premium_monthly',
      code: 'premium_monthly',
      name: 'Premium Monthly',
      description: 'Stay consistent with full monthly access.',
      planType: 'user',
      billingInterval: 'monthly',
      price: 10,
      currency: 'USD',
      trialDays: 0,
    ),
    MonetizationPlan(
      id: 'premium_yearly',
      code: 'premium_yearly',
      name: 'Premium Yearly',
      description: 'Best value for your full growth journey.',
      planType: 'user',
      billingInterval: 'yearly',
      price: 30,
      currency: 'USD',
      trialDays: 0,
    ),
    MonetizationPlan(
      id: 'church_starter',
      code: 'church_starter',
      name: 'Church Starter',
      description: 'Private groups, announcements, prayer, and reports.',
      planType: 'church',
      billingInterval: 'monthly',
      price: 150,
      currency: 'GHS',
      trialDays: 0,
    ),
    MonetizationPlan(
      id: 'church_growth',
      code: 'church_growth',
      name: 'Church Growth',
      description: 'More members, reports, helper assignment, and admins.',
      planType: 'church',
      billingInterval: 'monthly',
      price: 400,
      currency: 'GHS',
      trialDays: 0,
    ),
    MonetizationPlan(
      id: 'church_pro',
      code: 'church_pro',
      name: 'Church Pro',
      description: 'Advanced reports, branding, exports, and priority support.',
      planType: 'church',
      billingInterval: 'monthly',
      price: 800,
      currency: 'GHS',
      trialDays: 0,
    ),
  ];

  static const mockPrograms = [
    PaidProgram(
      id: 'program-7-day',
      title: '7-Day Discipline Plan',
      slug: '7-day-discipline-plan',
      description: 'A short guided rhythm for prayer and accountability.',
      programType: 'general',
      price: 0,
      currency: 'GHS',
      isPremiumIncluded: true,
      status: 'active',
    ),
    PaidProgram(
      id: 'program-21-day',
      title: '21-Day Freedom Challenge',
      slug: '21-day-freedom-challenge',
      description: 'Guided recovery prompts with premium accountability.',
      programType: 'recovery',
      price: 45,
      currency: 'GHS',
      isPremiumIncluded: true,
      status: 'active',
    ),
  ];

  static const mockCoachEarnings = CoachEarningsSummary(
    grossEarnings: 1840,
    platformFees: 368,
    netEarnings: 1472,
    availableBalance: 720,
    pendingBalance: 352,
    paidBalance: 400,
  );

  static const mockAdminRevenue = AdminRevenueSummary(
    lifetimeRevenue: 24580,
    dailyRevenue: 980,
    monthRevenue: 7200,
    successfulEvents: 186,
    failedEvents: 9,
    mrr: 5380,
    arr: 64560,
  );
}

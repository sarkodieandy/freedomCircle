import '../../data/models/monetization_models.dart';
import '../../data/models/revenuecat_models.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/supabase/supabase_service.dart';

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
    'quiet_time_advanced_insights',
    'helper_matching',
    'guided_programs',
    'private_anonymous_controls',
  };

  static const _subscriptionRepository = SubscriptionRepository();

  static CustomerPremiumStatus? _cachedPremiumStatus;

  Future<void> initializePremiumWatcher() async {
    _subscriptionRepository.watchPremiumStatus().listen((status) {
      _cachedPremiumStatus = status;
    });
    await refreshEntitlements();
  }

  Future<void> refreshEntitlements() async {
    if (!SupabaseService.isInitialized ||
        SupabaseService.currentUserId == null) {
      return;
    }

    final status = await _subscriptionRepository.getCustomerStatus();
    _cachedPremiumStatus = status;
    await _subscriptionRepository.syncPremiumStatusToSupabase();
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

    if (premiumFeatureKeys.contains(featureKey) &&
        await _isRevenueCatPremium()) {
      return true;
    }

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
    final rows = await SupabaseService.client
        .from('group_members')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'approved');
    if ((rows as List).length < 2) return true;
    return hasFeature('premium_groups');
  }

  Future<bool> canCreateRecoveryGoal() async {
    if (!SupabaseService.isInitialized) return false;
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;
    if (await hasFeature('recovery_goals_unlimited')) return true;

    final appSettings = await SupabaseService.client
        .from('app_settings')
        .select('setting_value')
        .eq('setting_key', 'free_recovery_goals_limit')
        .maybeSingle();
    final freeLimit =
        (appSettings?['setting_value']?['limit'] as num?)?.toInt() ?? 2;

    final rows = await SupabaseService.client
        .from('user_recovery_goals')
        .select('id')
        .eq('user_id', userId);
    return (rows as List).length < freeLimit;
  }

  Future<bool> canAccessPremiumGroup(String groupId) {
    return hasFeature('premium_groups');
  }

  Future<bool> canAccessPremiumQuietTimeSession(String sessionId) {
    return hasFeature('quiet_time_premium_library');
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

    final appSettings = await SupabaseService.client
        .from('app_settings')
        .select('setting_value')
        .eq('setting_key', 'free_journal_entry_limit')
        .maybeSingle();
    final freeLimit =
        (appSettings?['setting_value']?['limit'] as num?)?.toInt() ?? 10;
    return (rows as List).length < freeLimit;
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

  Future<void> openPaywallForFeature(String featureKey) async {
    await _trackPaywallEvent(
      screen: 'feature_gate',
      featureKey: featureKey,
      eventType: 'viewed',
    );
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
    return _trackPaywallEvent(
      screen: screen,
      featureKey: 'upgrade',
      eventType: 'selected_package',
      planCode: planCode,
    );
  }

  Future<void> trackPurchaseStarted(String screen, String planCode) {
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
        ? 'purchase_cancelled'
        : (result.success ? 'purchase_success' : 'purchase_failed');
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
      eventType: 'restore_started',
    );
  }

  Future<void> trackRestoreResult(String screen, PurchaseResult result) {
    return _trackPaywallEvent(
      screen: screen,
      featureKey: 'premium_access',
      eventType: result.success ? 'restore_success' : 'restore_failed',
      metadata: {
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
    await SupabaseService.client.from('paywall_events').insert({
      'user_id': SupabaseService.currentUser?.id,
      'screen': screen,
      'feature_key': featureKey,
      'event_type': eventType,
      'plan_code': planCode,
      'metadata': metadata ?? const {},
    });
  }

  static const mockPlans = [
    MonetizationPlan(
      id: 'free',
      code: 'free',
      name: 'Free',
      description: 'Basic tracker, groups, prayer wall, and journal access.',
      planType: 'user',
      billingInterval: 'free',
      price: 0,
      currency: 'GHS',
      trialDays: 0,
    ),
    MonetizationPlan(
      id: 'premium_monthly',
      code: 'premium_monthly',
      name: 'Premium Monthly',
      description: 'Unlimited goals, insights, premium groups, and programs.',
      planType: 'user',
      billingInterval: 'monthly',
      price: 25,
      currency: 'GHS',
      trialDays: 7,
    ),
    MonetizationPlan(
      id: 'premium_yearly',
      code: 'premium_yearly',
      name: 'Premium Yearly',
      description: 'Best value yearly premium access.',
      planType: 'user',
      billingInterval: 'yearly',
      price: 250,
      currency: 'GHS',
      trialDays: 7,
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

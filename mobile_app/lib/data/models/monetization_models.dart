import 'model_helpers.dart';

class MonetizationPlan {
  const MonetizationPlan({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.planType,
    required this.billingInterval,
    required this.price,
    required this.currency,
    required this.trialDays,
    this.isActive = true,
    this.features = const [],
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final String planType;
  final String billingInterval;
  final num price;
  final String currency;
  final int trialDays;
  final bool isActive;
  final List<PlanFeature> features;

  String get priceLabel {
    if (price == 0) return '$currency 0';
    return '$currency ${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)}';
  }

  factory MonetizationPlan.fromMap(JsonMap map) {
    return MonetizationPlan(
      id: readString(map, 'id'),
      code: readString(map, 'code'),
      name: readString(map, 'name'),
      description: readString(map, 'description'),
      planType: readString(map, 'plan_type', fallback: 'user'),
      billingInterval: readString(map, 'billing_interval', fallback: 'free'),
      price: readNum(map, 'price'),
      currency: readString(map, 'currency', fallback: 'GHS'),
      trialDays: readInt(map, 'trial_days'),
      isActive: readBool(map, 'is_active', fallback: true),
      features: (map['plan_features'] as List? ?? const [])
          .map((row) => PlanFeature.fromMap(asJsonMap(row)))
          .toList(),
    );
  }
}

class PlanFeature {
  const PlanFeature({
    required this.featureKey,
    required this.featureName,
    required this.isEnabled,
    this.featureDescription,
    this.featureLimit,
  });

  final String featureKey;
  final String featureName;
  final bool isEnabled;
  final String? featureDescription;
  final int? featureLimit;

  factory PlanFeature.fromMap(JsonMap map) {
    return PlanFeature(
      featureKey: readString(map, 'feature_key'),
      featureName: readString(map, 'feature_name'),
      isEnabled: readBool(map, 'is_enabled', fallback: true),
      featureDescription: readNullableString(map, 'feature_description'),
      featureLimit: map['feature_limit'] == null
          ? null
          : readInt(map, 'feature_limit'),
    );
  }
}

class UserEntitlement {
  const UserEntitlement({
    required this.entitlementKey,
    this.planCode,
    this.planName,
    this.expiresAt,
  });

  final String entitlementKey;
  final String? planCode;
  final String? planName;
  final DateTime? expiresAt;

  factory UserEntitlement.fromMap(JsonMap map) {
    return UserEntitlement(
      entitlementKey: readString(map, 'entitlement_key'),
      planCode: readNullableString(map, 'plan_code'),
      planName: readNullableString(map, 'plan_name'),
      expiresAt: DateTime.tryParse(readString(map, 'expires_at')),
    );
  }
}

class PaidProgram {
  const PaidProgram({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.programType,
    required this.price,
    required this.currency,
    required this.isPremiumIncluded,
    required this.status,
    this.coverImageUrl,
    this.modules = const [],
  });

  final String id;
  final String title;
  final String slug;
  final String description;
  final String programType;
  final num price;
  final String currency;
  final bool isPremiumIncluded;
  final String status;
  final String? coverImageUrl;
  final List<ProgramModule> modules;

  String get priceLabel {
    if (price == 0) return 'Free';
    return '$currency ${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)}';
  }

  factory PaidProgram.fromMap(JsonMap map) {
    return PaidProgram(
      id: readString(map, 'id'),
      title: readString(map, 'title'),
      slug: readString(map, 'slug'),
      description: readString(map, 'description'),
      programType: readString(map, 'program_type', fallback: 'general'),
      price: readNum(map, 'price'),
      currency: readString(map, 'currency', fallback: 'GHS'),
      isPremiumIncluded: readBool(map, 'is_premium_included'),
      status: readString(map, 'status', fallback: 'active'),
      coverImageUrl: readNullableString(map, 'cover_image_url'),
      modules: (map['program_modules'] as List? ?? const [])
          .map((row) => ProgramModule.fromMap(asJsonMap(row)))
          .toList(),
    );
  }
}

class ProgramModule {
  const ProgramModule({
    required this.id,
    required this.title,
    required this.sortOrder,
    this.description,
    this.lessons = const [],
  });

  final String id;
  final String title;
  final int sortOrder;
  final String? description;
  final List<ProgramLesson> lessons;

  factory ProgramModule.fromMap(JsonMap map) {
    return ProgramModule(
      id: readString(map, 'id'),
      title: readString(map, 'title'),
      sortOrder: readInt(map, 'sort_order'),
      description: readNullableString(map, 'description'),
      lessons: (map['program_lessons'] as List? ?? const [])
          .map((row) => ProgramLesson.fromMap(asJsonMap(row)))
          .toList(),
    );
  }
}

class ProgramLesson {
  const ProgramLesson({
    required this.id,
    required this.title,
    required this.lessonType,
    required this.durationMinutes,
    required this.sortOrder,
    this.content,
  });

  final String id;
  final String title;
  final String lessonType;
  final int durationMinutes;
  final int sortOrder;
  final String? content;

  factory ProgramLesson.fromMap(JsonMap map) {
    return ProgramLesson(
      id: readString(map, 'id'),
      title: readString(map, 'title'),
      lessonType: readString(map, 'lesson_type', fallback: 'text'),
      durationMinutes: readInt(map, 'duration_minutes'),
      sortOrder: readInt(map, 'sort_order'),
      content: readNullableString(map, 'content'),
    );
  }
}

class CoachEarningsSummary {
  const CoachEarningsSummary({
    required this.grossEarnings,
    required this.platformFees,
    required this.netEarnings,
    required this.availableBalance,
    required this.pendingBalance,
    required this.paidBalance,
  });

  final num grossEarnings;
  final num platformFees;
  final num netEarnings;
  final num availableBalance;
  final num pendingBalance;
  final num paidBalance;

  factory CoachEarningsSummary.fromMap(JsonMap map) {
    return CoachEarningsSummary(
      grossEarnings: readNum(map, 'gross_earnings'),
      platformFees: readNum(map, 'platform_fees'),
      netEarnings: readNum(map, 'net_earnings'),
      availableBalance: readNum(map, 'available_balance'),
      pendingBalance: readNum(map, 'pending_balance'),
      paidBalance: readNum(map, 'paid_balance'),
    );
  }
}

class AdminRevenueSummary {
  const AdminRevenueSummary({
    required this.lifetimeRevenue,
    required this.dailyRevenue,
    required this.monthRevenue,
    required this.successfulEvents,
    required this.failedEvents,
    required this.mrr,
    required this.arr,
  });

  final num lifetimeRevenue;
  final num dailyRevenue;
  final num monthRevenue;
  final int successfulEvents;
  final int failedEvents;
  final num mrr;
  final num arr;

  factory AdminRevenueSummary.fromMaps({
    required JsonMap revenue,
    required JsonMap mrr,
  }) {
    return AdminRevenueSummary(
      lifetimeRevenue: readNum(revenue, 'lifetime_revenue'),
      dailyRevenue: readNum(revenue, 'daily_revenue'),
      monthRevenue: readNum(revenue, 'month_revenue'),
      successfulEvents: readInt(revenue, 'successful_events'),
      failedEvents: readInt(revenue, 'failed_events'),
      mrr: readNum(mrr, 'mrr'),
      arr: readNum(mrr, 'arr'),
    );
  }
}

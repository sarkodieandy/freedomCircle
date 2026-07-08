import '../../core/services/monetization_service.dart';
import '../models/monetization_models.dart';

class MonetizationRepository {
  const MonetizationRepository({this.service = MonetizationService.instance});

  final MonetizationService service;

  Future<bool> hasFeature(String featureKey) => service.hasFeature(featureKey);

  Future<bool> canAccessPremiumGroup(String groupId) =>
      service.canAccessPremiumGroup(groupId);

  Future<bool> canCreateRecoveryGoal() => service.canCreateRecoveryGoal();

  Future<bool> canCreateJournalEntry() => service.canCreateJournalEntry();

  Future<bool> canAccessProgram(String programId) =>
      service.canAccessProgram(programId);

  Future<void> trackPaywallView(String screen, String featureKey) =>
      service.trackPaywallView(screen, featureKey);

  Future<void> trackUpgradeClick(String screen, String planCode) =>
      service.trackUpgradeClick(screen, planCode);

  Future<List<MonetizationPlan>> getPaywallPlans({String? type}) =>
      service.plans(type: type);
}

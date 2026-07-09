import '../../core/services/monetization_service.dart';
import '../models/monetization_models.dart';

class MonetizationRepository {
  const MonetizationRepository({this.service = MonetizationService.instance});

  final MonetizationService service;

  Future<bool> hasFeature(String featureKey) => service.hasFeature(featureKey);

  Future<bool> canAccessPremiumGroup(String groupId) =>
      service.canAccessPremiumGroup(groupId);

  Future<bool> canJoinGroup(String groupId) => service.canJoinGroup(groupId);

  Future<bool> canCreateRecoveryGoal() => service.canCreateRecoveryGoal();

  Future<bool> canCreateJournalEntry() => service.canCreateJournalEntry();

  Future<bool> canAccessQuietTimeSession(String sessionId) =>
      service.canAccessQuietTimeSession(sessionId);

  Future<bool> canUseHelperMatching() => service.canUseHelperMatching();

  Future<bool> canAccessGuidedProgram(String programId) =>
      service.canAccessGuidedProgram(programId);

  Future<String> getCurrentPlan() => service.getCurrentPlan();

  Future<bool> canAccessProgram(String programId) =>
      service.canAccessProgram(programId);

  Future<void> trackPaywallView(String screen, String featureKey) =>
      service.trackPaywallView(screen, featureKey);

  Future<void> trackUpgradeClick(String screen, String planCode) =>
      service.trackUpgradeClick(screen, planCode);

  Future<void> showPaywallForFeature(String featureKey) =>
      service.showPaywallForFeature(featureKey);

  Future<List<MonetizationPlan>> getPaywallPlans({String? type}) =>
      service.plans(type: type);
}

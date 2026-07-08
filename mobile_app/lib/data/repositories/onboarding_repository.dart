import '../models/user_onboarding_preferences.dart';
import 'supabase_repository.dart';

class OnboardingRepository extends SupabaseRepository {
  const OnboardingRepository({super.supabaseClient});

  Future<void> saveUserPreferences(UserOnboardingPreferences preferences) {
    return guard(() async {
      await client
          .from('user_onboarding_preferences')
          .upsert(preferences.toJson(), onConflict: 'user_id');
    });
  }

  Future<UserOnboardingPreferences?> getUserPreferences(String userId) {
    return guard(() async {
      final row = await client
          .from('user_onboarding_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return row == null
          ? null
          : UserOnboardingPreferences.fromJson(mapRow(row));
    });
  }

  Future<void> markOnboardingComplete(String userId) {
    return guard(() async {
      await client
          .from('profiles')
          .update({'onboarding_completed': true})
          .eq('user_id', userId);
    });
  }
}

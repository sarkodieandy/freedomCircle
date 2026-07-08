import '../models/helper_availability.dart';
import '../models/helper_profile.dart';
import 'supabase_repository.dart';

class HelperRepository extends SupabaseRepository {
  const HelperRepository({super.supabaseClient});

  Future<List<HelperProfile>> getVerifiedHelpers() => helpers();

  Future<List<HelperProfile>> searchHelpers(String query) {
    return guard(() async {
      final q = query.trim();
      if (q.isEmpty) return helpers();
      final rows = await client
          .from('helper_public_profiles')
          .select()
          .or('name.ilike.%$q%,organization.ilike.%$q%')
          .order('rating', ascending: false);
      return mapRows(rows, HelperProfile.fromMap);
    });
  }

  Future<HelperProfile?> getHelperProfile(String helperId) => helper(helperId);

  Future<List<HelperAvailability>> getHelperAvailability(String helperId) =>
      availability(helperId);

  Future<List<HelperProfile>> helpers() {
    return guard(() async {
      final rows = await client
          .from('helper_public_profiles')
          .select()
          .order('rating', ascending: false);
      return mapRows(rows, HelperProfile.fromMap);
    });
  }

  Future<HelperProfile?> helper(String helperId) {
    return guard(() async {
      final row = await client
          .from('helper_public_profiles')
          .select()
          .eq('id', helperId)
          .maybeSingle();
      return row == null ? null : HelperProfile.fromMap(mapRow(row));
    });
  }

  Future<List<HelperAvailability>> availability(String helperId) {
    return guard(() async {
      final rows = await client
          .from('helper_availability')
          .select()
          .eq('helper_id', helperId)
          .eq('is_active', true)
          .order('day_of_week');
      return mapRows(rows, HelperAvailability.fromMap);
    });
  }

  Future<Map<String, dynamic>> requestSupport(Map<String, dynamic> values) {
    return guard(() async {
      final row = await client
          .from('support_requests')
          .insert(values)
          .select()
          .single();
      return mapRow(row);
    });
  }

  Future<List<Map<String, dynamic>>> getSupportRequests(String userId) {
    return guard(() async {
      final rows = await client
          .from('support_requests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (rows as List).map((item) => mapRow(item)).toList();
    });
  }
}

import '../models/helper_availability.dart';
import '../models/helper_profile.dart';
import 'supabase_repository.dart';

class HelperRepository extends SupabaseRepository {
  const HelperRepository({super.supabaseClient});

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
}

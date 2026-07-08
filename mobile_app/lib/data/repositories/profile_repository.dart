import '../models/organization.dart';
import '../models/profile.dart';
import 'supabase_repository.dart';

class ProfileRepository extends SupabaseRepository {
  const ProfileRepository({super.supabaseClient});

  Future<Profile?> currentProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    return profileForUser(user.id);
  }

  Future<Profile?> profileForUser(String userId) {
    return guard(() async {
      final row = await client
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return row == null ? null : Profile.fromMap(mapRow(row));
    });
  }

  Future<Profile> upsertProfile(Map<String, dynamic> values) {
    return guard(() async {
      final row = await client
          .from('profiles')
          .upsert(values)
          .select()
          .single();
      return Profile.fromMap(mapRow(row));
    });
  }

  Future<List<Organization>> organizations() {
    return guard(() async {
      final rows = await client
          .from('organizations')
          .select()
          .eq('status', 'active')
          .order('name');
      return mapRows(rows, Organization.fromMap);
    });
  }
}

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/organization.dart';
import '../models/profile.dart';
import 'supabase_repository.dart';

class ProfileRepository extends SupabaseRepository {
  const ProfileRepository({super.supabaseClient});

  Future<Profile?> getCurrentProfile() => currentProfile();

  Future<Profile?> getProfileByUserId(String userId) => profileForUser(userId);

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

  Future<Profile> updateProfile(Map<String, dynamic> values) =>
      upsertProfile(values);

  Future<void> updateLastSeen(String userId) {
    return guard(() async {
      await client
          .from('profiles')
          .update({'last_seen_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId);
    });
  }

  Future<void> completeOnboarding(String userId) {
    return guard(() async {
      await client
          .from('profiles')
          .update({'onboarding_completed': true})
          .eq('user_id', userId);
    });
  }

  Future<String?> uploadAvatar({
    required String userId,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) {
    return guard(() async {
      final path =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await client.storage
          .from('avatars')
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: sb.FileOptions(contentType: contentType, upsert: true),
          );
      return client.storage.from('avatars').getPublicUrl(path);
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

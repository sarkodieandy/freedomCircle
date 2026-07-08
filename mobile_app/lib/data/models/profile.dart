import 'model_helpers.dart';

class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
    this.avatarUrl,
    this.churchName,
    this.isAnonymousEnabled = true,
  });

  final String id;
  final String fullName;
  final String username;
  final String role;
  final String? avatarUrl;
  final String? churchName;
  final bool isAnonymousEnabled;

  factory Profile.fromMap(JsonMap map) {
    return Profile(
      id: readString(map, 'id'),
      fullName: readString(map, 'full_name', fallback: 'FreedomCircle member'),
      username: readString(map, 'username'),
      role: readString(map, 'role', fallback: 'user'),
      avatarUrl: readNullableString(map, 'avatar_url'),
      churchName: readNullableString(map, 'church_name'),
      isAnonymousEnabled: readBool(map, 'is_anonymous_enabled', fallback: true),
    );
  }
}

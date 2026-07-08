import 'model_helpers.dart';

class UserPushToken {
  const UserPushToken({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.platform,
    required this.pushToken,
    this.provider = 'fcm',
    this.isActive = true,
  });

  final String id;
  final String userId;
  final String deviceId;
  final String platform;
  final String pushToken;
  final String provider;
  final bool isActive;

  factory UserPushToken.fromMap(JsonMap map) {
    return UserPushToken(
      id: readString(map, 'id'),
      userId: readString(map, 'user_id'),
      deviceId: readString(map, 'device_id'),
      platform: readString(map, 'platform'),
      pushToken: readString(map, 'push_token'),
      provider: readString(map, 'provider', fallback: 'fcm'),
      isActive: readBool(map, 'is_active', fallback: true),
    );
  }
}

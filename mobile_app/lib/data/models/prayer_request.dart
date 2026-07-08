import 'model_helpers.dart';

class PrayerRequest {
  const PrayerRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.prayedCount,
    required this.status,
    this.groupId,
    this.isAnonymous = true,
  });

  final String id;
  final String title;
  final String description;
  final int prayedCount;
  final String status;
  final String? groupId;
  final bool isAnonymous;

  factory PrayerRequest.fromMap(JsonMap map) {
    return PrayerRequest(
      id: readString(map, 'id'),
      title: readString(map, 'title'),
      description: readString(map, 'description'),
      prayedCount: readInt(map, 'prayed_count'),
      status: readString(map, 'status', fallback: 'active'),
      groupId: readNullableString(map, 'group_id'),
      isAnonymous: readBool(map, 'is_anonymous'),
    );
  }
}

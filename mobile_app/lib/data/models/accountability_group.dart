import 'model_helpers.dart';

class AccountabilityGroup {
  const AccountabilityGroup({
    this.id = '',
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.type,
    required this.members,
    required this.online,
    required this.checkInRate,
    required this.tags,
    required this.isPremium,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String type;
  final int members;
  final int online;
  final double checkInRate;
  final List<String> tags;
  final bool isPremium;

  factory AccountabilityGroup.fromMap(JsonMap map) {
    return AccountabilityGroup(
      id: readString(map, 'id'),
      name: readString(map, 'name'),
      description: readString(map, 'description'),
      imageUrl: readString(
        map,
        'cover_image_url',
        fallback: readString(map, 'cover_image'),
      ),
      type: readString(map, 'group_type', fallback: 'accountability'),
      members: readInt(map, 'member_count'),
      online: readInt(map, 'online_count'),
      checkInRate: readDouble(map, 'checkin_rate'),
      tags: readStringList(map, 'tags'),
      isPremium: readBool(map, 'is_premium'),
    );
  }
}

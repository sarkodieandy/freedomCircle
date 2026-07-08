import 'model_helpers.dart';

class RecoveryCategory {
  const RecoveryCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.isSensitive,
    required this.sortOrder,
    this.icon,
    this.description,
  });

  final String id;
  final String name;
  final String slug;
  final bool isSensitive;
  final int sortOrder;
  final String? icon;
  final String? description;

  factory RecoveryCategory.fromMap(JsonMap map) {
    return RecoveryCategory(
      id: readString(map, 'id'),
      name: readString(map, 'name'),
      slug: readString(map, 'slug'),
      isSensitive: readBool(map, 'is_sensitive', fallback: true),
      sortOrder: readInt(map, 'sort_order'),
      icon: readNullableString(map, 'icon'),
      description: readNullableString(map, 'description'),
    );
  }
}

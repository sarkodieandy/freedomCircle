import 'model_helpers.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.body,
    this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final DateTime createdAt;
  final String? body;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory NotificationItem.fromMap(JsonMap map) {
    return NotificationItem(
      id: readString(map, 'id'),
      type: readString(map, 'type', fallback: 'system'),
      title: readString(map, 'title'),
      createdAt: readDateTime(map, 'created_at', fallback: DateTime.now()),
      body: readNullableString(map, 'body'),
      readAt: DateTime.tryParse(readString(map, 'read_at')),
    );
  }
}

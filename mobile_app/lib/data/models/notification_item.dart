import 'model_helpers.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.body,
    this.data = const {},
    this.priority = 'normal',
    this.channel = 'in_app',
    this.isRead = false,
    this.readAt,
    this.actionUrl,
    this.imageUrl,
    this.updatedAt,
  });

  final String id;
  final String type;
  final String title;
  final DateTime createdAt;
  final String? body;
  final JsonMap data;
  final String priority;
  final String channel;
  final bool isRead;
  final DateTime? readAt;
  final String? actionUrl;
  final String? imageUrl;
  final DateTime? updatedAt;

  bool get isUnread => !isRead;

  String? stringData(String key) {
    final value = data[key];
    return value?.toString();
  }

  factory NotificationItem.fromMap(JsonMap map) {
    final dataValue = map['data'];
    final parsedReadAt = DateTime.tryParse(readString(map, 'read_at'));

    return NotificationItem(
      id: readString(map, 'id'),
      type: readString(map, 'type', fallback: 'system'),
      title: readString(map, 'title'),
      createdAt: readDateTime(map, 'created_at', fallback: DateTime.now()),
      body: readNullableString(map, 'body'),
      data: dataValue is Map ? JsonMap.from(dataValue) : const {},
      priority: readString(map, 'priority', fallback: 'normal'),
      channel: readString(map, 'channel', fallback: 'in_app'),
      isRead: readBool(map, 'is_read', fallback: parsedReadAt != null),
      readAt: parsedReadAt,
      actionUrl: readNullableString(map, 'action_url'),
      imageUrl: readNullableString(map, 'image_url'),
      updatedAt: DateTime.tryParse(readString(map, 'updated_at')),
    );
  }
}

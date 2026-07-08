import 'model_helpers.dart';

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.body,
    required this.createdAt,
    this.title,
    this.entryType,
    this.mood,
    this.isLocked = true,
  });

  final String id;
  final String body;
  final DateTime createdAt;
  final String? title;
  final String? entryType;
  final String? mood;
  final bool isLocked;

  factory JournalEntry.fromMap(JsonMap map) {
    return JournalEntry(
      id: readString(map, 'id'),
      body: readString(map, 'body'),
      createdAt: readDateTime(map, 'created_at', fallback: DateTime.now()),
      title: readNullableString(map, 'title'),
      entryType: readNullableString(map, 'entry_type'),
      mood: readNullableString(map, 'mood'),
      isLocked: readBool(map, 'is_locked', fallback: true),
    );
  }
}

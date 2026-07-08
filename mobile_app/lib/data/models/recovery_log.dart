import 'model_helpers.dart';

class RecoveryLog {
  const RecoveryLog({
    required this.id,
    required this.goalId,
    required this.type,
    required this.mood,
    required this.trigger,
    required this.note,
    required this.createdAt,
    this.isPrivate = true,
  });

  final String id;
  final String goalId;
  final String type;
  final String mood;
  final String trigger;
  final String note;
  final DateTime createdAt;
  final bool isPrivate;

  factory RecoveryLog.fromMap(JsonMap map) {
    return RecoveryLog(
      id: readString(map, 'id'),
      goalId: readString(map, 'goal_id'),
      type: readString(map, 'log_type', fallback: readString(map, 'type')),
      mood: readString(map, 'mood'),
      trigger: readString(
        map,
        'trigger_note',
        fallback: readString(map, 'trigger'),
      ),
      note: readString(
        map,
        'reflection_note',
        fallback: readString(map, 'note'),
      ),
      createdAt: readDateTime(map, 'created_at', fallback: DateTime.now()),
      isPrivate: readBool(map, 'is_private', fallback: true),
    );
  }
}

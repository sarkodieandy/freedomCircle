import 'model_helpers.dart';

class RecoveryGoal {
  const RecoveryGoal({
    required this.id,
    required this.category,
    required this.title,
    required this.currentStreak,
    required this.longestStreak,
    required this.status,
  });

  final String id;
  final String category;
  final String title;
  final int currentStreak;
  final int longestStreak;
  final String status;

  factory RecoveryGoal.fromMap(JsonMap map) {
    return RecoveryGoal(
      id: readString(map, 'id'),
      category: readString(
        map,
        'category_name',
        fallback: readString(map, 'category_id'),
      ),
      title: readString(map, 'title', fallback: readString(map, 'goal_title')),
      currentStreak: readInt(map, 'current_streak'),
      longestStreak: readInt(map, 'longest_streak'),
      status: readString(map, 'status', fallback: 'active'),
    );
  }
}

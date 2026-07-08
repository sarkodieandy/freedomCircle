import 'model_helpers.dart';

class Booking {
  const Booking({
    required this.id,
    required this.helperId,
    required this.sessionType,
    required this.dateLabel,
    required this.timeLabel,
    required this.amount,
    required this.status,
  });

  final String id;
  final String helperId;
  final String sessionType;
  final String dateLabel;
  final String timeLabel;
  final num amount;
  final String status;

  factory Booking.fromMap(JsonMap map) {
    final scheduledAt = readDateTime(
      map,
      'scheduled_at',
      fallback: DateTime.now(),
    );

    return Booking(
      id: readString(map, 'id'),
      helperId: readString(map, 'helper_id'),
      sessionType: readString(map, 'session_type', fallback: 'support'),
      dateLabel: '${scheduledAt.year}-${scheduledAt.month}-${scheduledAt.day}',
      timeLabel:
          '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}',
      amount: readNum(map, 'amount'),
      status: readString(map, 'status', fallback: 'requested'),
    );
  }
}

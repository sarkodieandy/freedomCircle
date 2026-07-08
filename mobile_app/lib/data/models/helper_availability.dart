import 'model_helpers.dart';

class HelperAvailability {
  const HelperAvailability({
    required this.id,
    required this.helperId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  final String id;
  final String helperId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isActive;

  factory HelperAvailability.fromMap(JsonMap map) {
    return HelperAvailability(
      id: readString(map, 'id'),
      helperId: readString(map, 'helper_id'),
      dayOfWeek: readInt(map, 'day_of_week'),
      startTime: readString(map, 'start_time'),
      endTime: readString(map, 'end_time'),
      isActive: readBool(map, 'is_active', fallback: true),
    );
  }
}

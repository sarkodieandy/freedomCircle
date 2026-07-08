import 'model_helpers.dart';

class ReportItem {
  const ReportItem({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.details,
  });

  final String id;
  final String targetType;
  final String targetId;
  final String reason;
  final String status;
  final DateTime createdAt;
  final String? details;

  factory ReportItem.fromMap(JsonMap map) {
    return ReportItem(
      id: readString(map, 'id'),
      targetType: readString(map, 'target_type'),
      targetId: readString(map, 'target_id'),
      reason: readString(map, 'reason'),
      status: readString(map, 'status', fallback: 'open'),
      createdAt: readDateTime(map, 'created_at', fallback: DateTime.now()),
      details: readNullableString(map, 'details'),
    );
  }
}

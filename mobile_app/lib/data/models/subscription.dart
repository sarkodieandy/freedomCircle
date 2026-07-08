import 'model_helpers.dart';

class UserSubscription {
  const UserSubscription({
    required this.id,
    required this.plan,
    required this.status,
    required this.renewsOn,
  });

  final String id;
  final String plan;
  final String status;
  final DateTime renewsOn;

  factory UserSubscription.fromMap(JsonMap map) {
    return UserSubscription(
      id: readString(map, 'id'),
      plan: readString(map, 'plan', fallback: 'free'),
      status: readString(map, 'status', fallback: 'active'),
      renewsOn: readDateTime(
        map,
        'current_period_end',
        fallback: readDateTime(map, 'end_date', fallback: DateTime.now()),
      ),
    );
  }
}

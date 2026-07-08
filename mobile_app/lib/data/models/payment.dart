import 'model_helpers.dart';

class Payment {
  const Payment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.reference,
    required this.status,
  });

  final String id;
  final num amount;
  final String currency;
  final String provider;
  final String reference;
  final String status;

  factory Payment.fromMap(JsonMap map) {
    return Payment(
      id: readString(map, 'id'),
      amount: readNum(map, 'amount'),
      currency: readString(map, 'currency', fallback: 'GHS'),
      provider: readString(
        map,
        'provider',
        fallback: readString(map, 'payment_provider'),
      ),
      reference: readString(
        map,
        'provider_reference',
        fallback: readString(map, 'reference'),
      ),
      status: readString(map, 'status', fallback: 'pending'),
    );
  }
}

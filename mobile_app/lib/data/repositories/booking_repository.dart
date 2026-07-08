import '../models/booking.dart';
import 'supabase_repository.dart';

class BookingRepository extends SupabaseRepository {
  const BookingRepository({super.supabaseClient});

  Future<List<Booking>> getUserBookings(String userId) => userBookings(userId);

  Future<List<Booking>> getHelperBookings(String helperId) =>
      helperBookings(helperId);

  Future<List<Booking>> userBookings(String userId) {
    return guard(() async {
      final rows = await client
          .from('coach_bookings')
          .select()
          .eq('user_id', userId)
          .order('scheduled_at', ascending: false);
      return mapRows(rows, Booking.fromMap);
    });
  }

  Future<List<Booking>> helperBookings(String helperId) {
    return guard(() async {
      final rows = await client
          .from('coach_bookings')
          .select()
          .eq('helper_id', helperId)
          .order('scheduled_at', ascending: false);
      return mapRows(rows, Booking.fromMap);
    });
  }

  Future<Booking> createBooking(Map<String, dynamic> values) {
    return guard(() async {
      final row = await client
          .from('coach_bookings')
          .insert(values)
          .select()
          .single();
      return Booking.fromMap(mapRow(row));
    });
  }

  Future<Booking> updateStatus(String bookingId, String status) {
    return guard(() async {
      final row = await client
          .from('coach_bookings')
          .update({'status': status})
          .eq('id', bookingId)
          .select()
          .single();
      return Booking.fromMap(mapRow(row));
    });
  }

  Future<Booking> updateBookingStatus(String bookingId, String status) =>
      updateStatus(bookingId, status);

  Future<Map<String, dynamic>> createPaymentRequestPlaceholder({
    required String bookingId,
    required String userId,
    required num amount,
    String currency = 'GHS',
  }) {
    // TODO(server): verify provider callback/webhook before marking paid.
    return guard(() async {
      final row = await client
          .from('payments')
          .insert({
            'booking_id': bookingId,
            'user_id': userId,
            'amount': amount,
            'currency': currency,
            'status': 'pending',
            'provider': 'paystack_placeholder',
          })
          .select()
          .single();
      return mapRow(row);
    });
  }

  Future<Map<String, dynamic>?> getBookingPaymentStatus(String bookingId) {
    return guard(() async {
      final row = await client
          .from('payments')
          .select()
          .eq('booking_id', bookingId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null ? null : mapRow(row);
    });
  }
}

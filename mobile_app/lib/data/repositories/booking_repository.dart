import '../models/booking.dart';
import 'supabase_repository.dart';

class BookingRepository extends SupabaseRepository {
  const BookingRepository({super.supabaseClient});

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
}

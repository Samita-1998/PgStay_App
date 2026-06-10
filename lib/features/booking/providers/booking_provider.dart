import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/features/booking/models/booking_model.dart';

// Mock list of bookings
final mockBookingsProvider = StateProvider<List<BookingModel>>((ref) {
  return [
    BookingModel(
      id: 'b1',
      pgId: 'pg1',
      pgName: 'Sunshine Co-Living',
      userId: 'user1',
      roomId: 'room1',
      roomType: 'Single Sharing',
      checkInDate: DateTime.now().add(const Duration(days: 5)),
      durationMonths: 6,
      totalAmount: 12000 * 6,
      amountPaid: 12000, // Deposit
      status: 'confirmed',
    ),
    BookingModel(
      id: 'b2',
      pgId: 'pg2',
      pgName: 'Urban Nest PG',
      userId: 'user1',
      roomId: 'room2',
      roomType: 'Double Sharing',
      checkInDate: DateTime.now().subtract(const Duration(days: 60)),
      durationMonths: 11,
      totalAmount: 8500 * 11,
      amountPaid: 8500 * 3,
      status: 'completed',
    )
  ];
});

class BookingNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  BookingNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> createBooking(BookingModel newBooking) async {
    state = const AsyncValue.loading();
    try {
      // Simulate network request
      await Future.delayed(const Duration(seconds: 2));
      
      final currentBookings = ref.read(mockBookingsProvider);
      ref.read(mockBookingsProvider.notifier).state = [newBooking, ...currentBookings];
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final bookingNotifierProvider =
    StateNotifierProvider<BookingNotifier, AsyncValue<void>>((ref) {
  return BookingNotifier(ref);
});

final userBookingsProvider = Provider<List<BookingModel>>((ref) {
  return ref.watch(mockBookingsProvider);
});

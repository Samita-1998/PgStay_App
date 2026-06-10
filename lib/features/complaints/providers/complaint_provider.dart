import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/features/complaints/models/complaint_model.dart';

// Mock list of complaints
final mockComplaintsProvider = StateProvider<List<ComplaintModel>>((ref) {
  return [
    ComplaintModel(
      id: 'c1',
      pgId: 'pg1',
      userId: 'user1',
      userName: 'Tenant One',
      category: 'Maintenance',
      description: 'The AC in room 204 is making a loud noise and not cooling properly.',
      status: 'Open',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ComplaintModel(
      id: 'c2',
      pgId: 'pg1',
      userId: 'user2',
      userName: 'Tenant Two',
      category: 'Cleaning',
      description: 'The common washroom on the 2nd floor needs cleaning.',
      status: 'Resolved',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    )
  ];
});

class ComplaintNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ComplaintNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> createComplaint(ComplaintModel newComplaint) async {
    state = const AsyncValue.loading();
    try {
      // Simulate network request
      await Future.delayed(const Duration(seconds: 1));
      
      final currentComplaints = ref.read(mockComplaintsProvider);
      ref.read(mockComplaintsProvider.notifier).state = [newComplaint, ...currentComplaints];
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(String complaintId, String newStatus) async {
    state = const AsyncValue.loading();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final currentComplaints = ref.read(mockComplaintsProvider);
      final updatedList = currentComplaints.map((c) {
        if (c.id == complaintId) {
          return ComplaintModel(
            id: c.id,
            pgId: c.pgId,
            userId: c.userId,
            userName: c.userName,
            category: c.category,
            description: c.description,
            status: newStatus,
            createdAt: c.createdAt,
          );
        }
        return c;
      }).toList();
      
      ref.read(mockComplaintsProvider.notifier).state = updatedList;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final complaintNotifierProvider =
    StateNotifierProvider<ComplaintNotifier, AsyncValue<void>>((ref) {
  return ComplaintNotifier(ref);
});

final propertyComplaintsProvider = Provider<List<ComplaintModel>>((ref) {
  return ref.watch(mockComplaintsProvider);
});

final userComplaintsProvider = Provider<List<ComplaintModel>>((ref) {
  final allComplaints = ref.watch(mockComplaintsProvider);
  // In a real app, filter by userId
  return allComplaints;
});

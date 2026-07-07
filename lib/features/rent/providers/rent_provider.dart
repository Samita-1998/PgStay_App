import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/rent/models/rent_model.dart';
import 'package:pgstay/features/rent/repositories/rent_repository.dart';

final rentRepositoryProvider = Provider<RentRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return RentRepository(apiClient);
});

final myRentsProvider = FutureProvider.autoDispose<List<RentModel>>((ref) async {
  final repo = ref.read(rentRepositoryProvider);
  return repo.fetchMyRents();
});

final pgRentsProvider = FutureProvider.autoDispose.family<List<RentModel>, String>((ref, pgId) async {
  final repo = ref.read(rentRepositoryProvider);
  return repo.fetchRents(pgId: pgId);
});

// For filtering by month
final filteredPgRentsProvider = FutureProvider.autoDispose.family<List<RentModel>, Map<String, String>>((ref, params) async {
  final repo = ref.read(rentRepositoryProvider);
  return repo.fetchRents(
    pgId: params['pgId'],
    month: params['month'],
    status: params['status'],
  );
});

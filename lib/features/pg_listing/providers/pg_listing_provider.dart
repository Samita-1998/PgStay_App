import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/repositories/pg_listing_repository.dart';

final pgListingRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PgListingRepository(apiClient);
});

final pgSearchCityProvider = StateProvider<String>((ref) => '');
final pgTypeFilterProvider = StateProvider<String>((ref) => 'All');
final pgOccupancyFilterProvider = StateProvider<String>((ref) => 'All');
final pgMaxPriceFilterProvider = StateProvider<double>((ref) => 0.0);

final pgListProvider = FutureProvider<List<PgPost>>((ref) async {
  final repository = ref.watch(pgListingRepositoryProvider);
  final authState = ref.watch(authProvider);
  final user = authState.valueOrNull;

  if (user != null && (user.role == 'owner' || user.role == 'manager')) {
    return repository.fetchStaffPosts();
  }

  final city = ref.watch(pgSearchCityProvider);
  final pgType = ref.watch(pgTypeFilterProvider);
  final occupancy = ref.watch(pgOccupancyFilterProvider);
  final maxPrice = ref.watch(pgMaxPriceFilterProvider);

  return repository.fetchRecommendations(
    city: city,
    pgType: pgType,
    occupancyType: occupancy,
    maxPrice: maxPrice > 0 ? maxPrice : null,
  );
});

final pgDetailsProvider = FutureProvider.family<PgPost, String>((ref, postId) async {
  final repository = ref.watch(pgListingRepositoryProvider);
  return repository.fetchPostDetails(postId);
});

final ownerPgsProvider = FutureProvider<List<PgModel>>((ref) async {
  final repository = ref.watch(pgListingRepositoryProvider);
  return repository.fetchOwnerPGs();
});

final pgRoomsProvider = FutureProvider.family<List<dynamic>, String>((ref, pgId) async {
  final repository = ref.watch(pgListingRepositoryProvider);
  return repository.fetchRooms(pgId);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/repositories/pg_listing_repository.dart';

final pgListingRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PgListingRepository(apiClient);
});

final pgSearchCityProvider = StateProvider<String>((ref) => '');
final pgTypeFilterProvider = StateProvider<String>((ref) => 'Any Type');
final pgOccupancyFilterProvider = StateProvider<String>((ref) => 'Sharing');
final pgMinPriceFilterProvider = StateProvider<double>((ref) => 0.0);
final pgMaxPriceFilterProvider = StateProvider<double>((ref) => 0.0);
final pgActiveVacanciesProvider = StateProvider<bool>((ref) => false);
final pgFacilitiesFilterProvider = StateProvider<List<String>>((ref) => []);

class PgListNotifier extends StateNotifier<AsyncValue<List<PgPost>>> {
  final PgListingRepository repository;
  final String? role;
  final String city;
  final String pgType;
  final String occupancy;
  final double minPrice;
  final double maxPrice;

  int _page = 1;
  bool hasMore = true;
  bool _isLoadingMore = false;

  PgListNotifier({
    required this.repository,
    required this.role,
    required this.city,
    required this.pgType,
    required this.occupancy,
    required this.minPrice,
    required this.maxPrice,
  }) : super(const AsyncValue.loading()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    try {
      state = const AsyncValue.loading();
      _page = 1;
      hasMore = true;

      List<PgPost> posts;
      if (role == 'owner' || role == 'manager') {
        posts = await repository.fetchStaffPosts();
        hasMore = false;
      } else {
        posts = await repository.fetchRecommendations(
          city: city,
          pgType: pgType == 'Any Type' ? null : pgType,
          occupancyType: occupancy == 'Sharing' ? null : occupancy,
          minPrice: minPrice > 0 ? minPrice : null,
          maxPrice: maxPrice > 0 ? maxPrice : null,
          page: _page,
          limit: 10,
        );
        if (posts.length < 10) hasMore = false;
      }
      state = AsyncValue.data(posts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore || role == 'owner' || role == 'manager')
      return;
    final currentPosts = state.valueOrNull ?? [];
    _isLoadingMore = true;
    _page++;
    try {
      final newPosts = await repository.fetchRecommendations(
        city: city,
        pgType: pgType == 'Any Type' ? null : pgType,
        occupancyType: occupancy == 'Sharing' ? null : occupancy,
        minPrice: minPrice > 0 ? minPrice : null,
        maxPrice: maxPrice > 0 ? maxPrice : null,
        page: _page,
        limit: 10,
      );
      if (newPosts.length < 10) hasMore = false;
      state = AsyncValue.data([...currentPosts, ...newPosts]);
    } catch (e) {
      _page--;
    } finally {
      _isLoadingMore = false;
    }
  }
}

final pgListProvider =
    StateNotifierProvider<PgListNotifier, AsyncValue<List<PgPost>>>((ref) {
      final repository = ref.watch(pgListingRepositoryProvider);
      final authState = ref.watch(authProvider);
      final user = authState.valueOrNull;

      final city = ref.watch(pgSearchCityProvider);
      final pgType = ref.watch(pgTypeFilterProvider);
      final occupancy = ref.watch(pgOccupancyFilterProvider);
      final minPrice = ref.watch(pgMinPriceFilterProvider);
      final maxPrice = ref.watch(pgMaxPriceFilterProvider);

      return PgListNotifier(
        repository: repository,
        role: user?.role,
        city: city,
        pgType: pgType,
        occupancy: occupancy,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
    });

class DiscoverPgNotifier extends StateNotifier<AsyncValue<List<PgModel>>> {
  final PgListingRepository repository;
  final String city;
  final String pgType;

  int _page = 1;
  bool hasMore = true;
  bool _isLoadingMore = false;

  DiscoverPgNotifier({
    required this.repository,
    required this.city,
    required this.pgType,
  }) : super(const AsyncValue.loading()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    try {
      state = const AsyncValue.loading();
      _page = 1;
      hasMore = true;
      final pgs = await repository.fetchDiscoverPGs(
        city: city,
        pgType: pgType,
        page: _page,
        limit: 10,
      );
      if (pgs.length < 10) hasMore = false;
      state = AsyncValue.data(pgs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;
    final currentPgs = state.valueOrNull ?? [];
    _isLoadingMore = true;
    _page++;
    try {
      final newPgs = await repository.fetchDiscoverPGs(
        city: city,
        pgType: pgType,
        page: _page,
        limit: 10,
      );
      if (newPgs.length < 10) hasMore = false;
      state = AsyncValue.data([...currentPgs, ...newPgs]);
    } catch (e) {
      _page--;
    } finally {
      _isLoadingMore = false;
    }
  }
}

final discoverPgCityProvider = StateProvider<String>((ref) => '');
final discoverPgTypeProvider = StateProvider<String>((ref) => 'All');

final discoverPgProvider =
    StateNotifierProvider<DiscoverPgNotifier, AsyncValue<List<PgModel>>>((ref) {
      ref.watch(authProvider); // Rebuild on login/logout
      final repository = ref.watch(pgListingRepositoryProvider);
      final city = ref.watch(discoverPgCityProvider);
      final pgType = ref.watch(discoverPgTypeProvider);

      return DiscoverPgNotifier(
        repository: repository,
        city: city,
        pgType: pgType,
      );
    });

final pgDetailsProvider = FutureProvider.family<PgPost, String>((
  ref,
  postId,
) async {
  final repository = ref.watch(pgListingRepositoryProvider);
  return repository.fetchPostDetails(postId);
});

class OwnerPgNotifier extends StateNotifier<AsyncValue<List<PgModel>>> {
  final PgListingRepository repository;

  int _page = 1;
  bool hasMore = true;
  bool _isLoadingMore = false;

  OwnerPgNotifier({required this.repository})
    : super(const AsyncValue.loading()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    try {
      state = const AsyncValue.loading();
      _page = 1;
      hasMore = true;
      final pgs = await repository.fetchOwnerPGs(page: _page, limit: 10);
      if (pgs.length < 10) hasMore = false;
      state = AsyncValue.data(pgs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;
    final currentPgs = state.valueOrNull ?? [];
    _isLoadingMore = true;
    _page++;
    try {
      final newPgs = await repository.fetchOwnerPGs(page: _page, limit: 10);
      if (newPgs.length < 10) hasMore = false;
      state = AsyncValue.data([...currentPgs, ...newPgs]);
    } catch (e) {
      _page--;
    } finally {
      _isLoadingMore = false;
    }
  }
}

final ownerPgsProvider =
    StateNotifierProvider<OwnerPgNotifier, AsyncValue<List<PgModel>>>((ref) {
      ref.watch(authProvider); // Rebuild on login/logout
      final repository = ref.watch(pgListingRepositoryProvider);
      return OwnerPgNotifier(repository: repository);
    });

final pgRoomsProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  pgId,
) async {
  final repository = ref.watch(pgListingRepositoryProvider);
  return repository.fetchRooms(pgId);
});

// ─── Browse Posts (Search) providers ──────────────────────────────────────────
final browsePostTitleProvider = StateProvider<String>((ref) => '');
final browsePostCityProvider = StateProvider<String>((ref) => '');
final browsePostTypeProvider = StateProvider<String>((ref) => 'Any Type');
final browsePostOccupancyProvider = StateProvider<String>((ref) => 'Sharing');
final browsePostMinPriceProvider = StateProvider<double>((ref) => 0);
final browsePostMaxPriceProvider = StateProvider<double>((ref) => 0);
final browsePostMinRatingProvider = StateProvider<double>((ref) => 0);
final browsePostOnlyVacancyProvider = StateProvider<bool>((ref) => false);
final browsePostFacilitiesProvider = StateProvider<List<String>>((ref) => []);

class BrowsePostNotifier extends StateNotifier<AsyncValue<List<PgPost>>> {
  final PgListingRepository repository;
  final String title;
  final String city;
  final String pgType;
  final String occupancy;
  final double minPrice;
  final double maxPrice;
  final double minRating;
  final bool onlyWithVacancy;
  final List<String> facilities;

  int _page = 1;
  bool hasMore = true;
  bool _isLoadingMore = false;

  BrowsePostNotifier({
    required this.repository,
    required this.title,
    required this.city,
    required this.pgType,
    required this.occupancy,
    required this.minPrice,
    required this.maxPrice,
    required this.minRating,
    required this.onlyWithVacancy,
    required this.facilities,
  }) : super(const AsyncValue.loading()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    try {
      state = const AsyncValue.loading();
      _page = 1;
      hasMore = true;
      final posts = await repository.searchPosts(
        title: title,
        city: city,
        pgType: pgType,
        occupancyType: occupancy,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
        onlyWithVacancy: onlyWithVacancy,
        facilities: facilities,
        page: _page,
        limit: 12,
      );
      if (posts.length < 12) hasMore = false;
      state = AsyncValue.data(posts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;
    final current = state.valueOrNull ?? [];
    _isLoadingMore = true;
    _page++;
    try {
      final more = await repository.searchPosts(
        title: title,
        city: city,
        pgType: pgType,
        occupancyType: occupancy,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
        onlyWithVacancy: onlyWithVacancy,
        facilities: facilities,
        page: _page,
        limit: 12,
      );
      if (more.length < 12) hasMore = false;
      state = AsyncValue.data([...current, ...more]);
    } catch (_) {
      _page--;
    } finally {
      _isLoadingMore = false;
    }
  }
}

final browsePostProvider =
    StateNotifierProvider<BrowsePostNotifier, AsyncValue<List<PgPost>>>((ref) {
      ref.watch(authProvider); // Rebuild on login/logout
      return BrowsePostNotifier(
        repository: ref.watch(pgListingRepositoryProvider),
        title: ref.watch(browsePostTitleProvider),
        city: ref.watch(browsePostCityProvider),
        pgType: ref.watch(browsePostTypeProvider),
        occupancy: ref.watch(browsePostOccupancyProvider),
        minPrice: ref.watch(browsePostMinPriceProvider),
        maxPrice: ref.watch(browsePostMaxPriceProvider),
        minRating: ref.watch(browsePostMinRatingProvider),
        onlyWithVacancy: ref.watch(browsePostOnlyVacancyProvider),
        facilities: ref.watch(browsePostFacilitiesProvider),
      );
    });

final facilitiesListProvider = FutureProvider<List<Map<String, String>>>((
  ref,
) async {
  final repository = ref.watch(pgListingRepositoryProvider);
  return repository.fetchFacilities();
});

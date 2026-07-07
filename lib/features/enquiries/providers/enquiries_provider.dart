import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/enquiries/models/enquiry_model.dart';
import 'package:pgstay/features/enquiries/repositories/enquiries_repository.dart';

final enquiriesRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EnquiriesRepository(apiClient);
});

final enquiriesListProvider = FutureProvider<List<EnquiryModel>>((ref) async {
  final repository = ref.watch(enquiriesRepositoryProvider);
  return repository.fetchMyEnquiries();
});

// For owner: derives count from enquiriesListProvider (avoids duplicate API calls)
final ownerEnquiriesCountProvider = FutureProvider<int>((ref) async {
  final enquiries = await ref.watch(enquiriesListProvider.future);
  return enquiries.length;
});

final paginatedEnquiriesProvider = FutureProvider.family<List<EnquiryModel>, int>((ref, page) async {
  final repository = ref.watch(enquiriesRepositoryProvider);
  return repository.fetchPaginatedEnquiries(page: page, limit: 10);
});

final userEnquiriesFilterProvider = StateProvider<String>((ref) => 'All');

class UserEnquiriesNotifier extends StateNotifier<AsyncValue<List<EnquiryModel>>> {
  final EnquiriesRepository repository;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  UserEnquiriesNotifier(this.repository) : super(const AsyncValue.loading()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    try {
      state = const AsyncValue.loading();
      _page = 1;
      _hasMore = true;
      final enquiries = await repository.fetchPaginatedEnquiries(page: _page, limit: 10);
      if (enquiries.length < 10) _hasMore = false;
      state = AsyncValue.data(enquiries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final currentList = state.valueOrNull ?? [];
    _isLoadingMore = true;
    _page++;
    try {
      final newList = await repository.fetchPaginatedEnquiries(page: _page, limit: 10);
      if (newList.length < 10) _hasMore = false;
      state = AsyncValue.data([...currentList, ...newList]);
    } catch (e) {
      _page--;
    } finally {
      _isLoadingMore = false;
    }
  }
}

final userEnquiriesProvider = StateNotifierProvider<UserEnquiriesNotifier, AsyncValue<List<EnquiryModel>>>((ref) {
  final repository = ref.watch(enquiriesRepositoryProvider);
  return UserEnquiriesNotifier(repository);
});

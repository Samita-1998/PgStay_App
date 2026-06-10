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

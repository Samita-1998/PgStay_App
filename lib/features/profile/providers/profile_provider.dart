import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/profile/models/profile_model.dart';
import 'package:pgstay/features/profile/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ProfileRepository(apiClient);
});

final userProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) async {
  final repo = ref.read(profileRepositoryProvider);
  return repo.fetchProfile();
});

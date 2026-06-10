import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/core/api/api_client.dart';
import 'package:pgstay/features/auth/models/user_model.dart';
import 'package:pgstay/features/auth/repositories/auth_repository.dart';

// Provider for ApiClient
final apiClientProvider = Provider((ref) => ApiClient());

// Provider for AuthRepository
final authRepositoryProvider = Provider((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

// StateNotifier to handle Auth State
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = const AsyncValue.loading();
    try {
      final isAuthenticated = await _repository.isAuthenticated();
      if (isAuthenticated) {
        final user = await _repository.getProfile();
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      await _repository.logout();
      state = const AsyncValue.data(null);
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.login(email, password);
      state = AsyncValue.data(user);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String mobNo1,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.register(
        name: name,
        email: email,
        password: password,
        mobNo1: mobNo1,
        role: role,
      );
      // Registration successful, transition back to login or auto-login
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

import 'package:dio/dio.dart';
import 'package:pgstay/core/api/api_client.dart';
import 'package:pgstay/features/auth/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<User> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data['success'] == true) {
        final token = response.data['data']['token'];
        final userData = response.data['data']['user'];
        
        // Save token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        return User.fromJson(userData);
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String mobNo1,
    required String role,
  }) async {
    try {
      final response = await _apiClient.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'mobNo1': mobNo1,
        'role': role,
      });

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  Future<User> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/profile');
      if (response.data['success'] == true) {
        final userData = response.data['data'];
        return User.fromJson(userData);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load profile');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }
}

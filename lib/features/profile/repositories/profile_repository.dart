import 'package:dio/dio.dart';
import 'package:pgstay/core/api/api_client.dart';
import 'package:pgstay/features/profile/models/profile_model.dart';

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  Future<UserProfile> fetchProfile() async {
    try {
      final response = await _apiClient.dio.get('/profile');
      if (response.data['success'] == true) {
        return UserProfile.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load profile');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch('/profile', data: data);
      if (response.data['success'] == true) {
        return UserProfile.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update profile');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }
}

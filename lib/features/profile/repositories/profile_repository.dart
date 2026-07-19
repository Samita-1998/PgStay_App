import 'dart:io';
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

  Future<UserProfile> uploadAadharDocument(String filePath, String fileName) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (ext == 'png') mimeType = 'image/png';
      else if (ext == 'pdf') mimeType = 'application/pdf';

      // 1. Get presigned URL
      final presignedResponse = await _apiClient.dio.get(
        '/profile/aadhar/upload-url',
        queryParameters: {
          'fileName': fileName,
          'fileType': mimeType,
        },
      );

      if (presignedResponse.data['success'] != true) {
        throw Exception(presignedResponse.data['message'] ?? 'Failed to get upload URL');
      }

      final uploadUrl = presignedResponse.data['data']['uploadUrl'];
      final key = presignedResponse.data['data']['key'];

      // 2. Upload file to S3
      final file = File(filePath);
      final fileLength = await file.length();
      
      final s3Dio = Dio();
      await s3Dio.put(
        uploadUrl,
        data: file.openRead(),
        options: Options(
          headers: {
            'Content-Type': mimeType,
            'Content-Length': fileLength.toString(),
          },
        ),
      );

      // 3. Update profile with the new key
      return await updateProfile({
        'aadharFileKey': key,
      });

    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message ?? 'Network error occurred');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserProfile> uploadProfilePicture(String filePath, String fileName) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (ext == 'png') mimeType = 'image/png';
      else if (ext == 'webp') mimeType = 'image/webp';

      // 1. Get presigned URL
      final presignedResponse = await _apiClient.dio.get(
        '/profile/avatar/upload-url',
        queryParameters: {
          'fileName': fileName,
          'fileType': mimeType,
        },
      );

      if (presignedResponse.data['success'] != true) {
        throw Exception(presignedResponse.data['message'] ?? 'Failed to get upload URL');
      }

      final uploadUrl = presignedResponse.data['data']['uploadUrl'];
      final key = presignedResponse.data['data']['key'];

      // 2. Upload file to S3
      final file = File(filePath);
      final fileLength = await file.length();
      
      final s3Dio = Dio();
      await s3Dio.put(
        uploadUrl,
        data: file.openRead(),
        options: Options(
          headers: {
            'Content-Type': mimeType,
            'Content-Length': fileLength.toString(),
          },
        ),
      );

      // 3. Update profile with the new key using the avatar endpoint
      final updateResponse = await _apiClient.dio.patch(
        '/profile/avatar',
        data: {'key': key},
      );
      
      if (updateResponse.data['success'] == true) {
        return await fetchProfile();
      } else {
        throw Exception(updateResponse.data['message'] ?? 'Failed to update avatar');
      }

    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message ?? 'Network error occurred');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserProfile> removeProfilePicture() async {
    try {
      final response = await _apiClient.dio.delete('/profile/avatar');
      
      if (response.data['success'] == true) {
        return await fetchProfile();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to remove avatar');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message ?? 'Network error occurred');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

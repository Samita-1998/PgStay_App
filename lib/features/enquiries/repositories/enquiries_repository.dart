import 'package:dio/dio.dart';
import 'package:pgstay/core/api/api_client.dart';
import 'package:pgstay/features/enquiries/models/enquiry_model.dart';

class EnquiriesRepository {
  final ApiClient _apiClient;

  EnquiriesRepository(this._apiClient);

  Future<List<EnquiryModel>> fetchMyEnquiries() async {
    try {
      final response = await _apiClient.dio.get('/enquiry');

      if (response.data['success'] == true) {
        final List<dynamic> listJson = response.data['data']['enquiries'] ?? [];
        return listJson.map((json) => EnquiryModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch enquiries');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while fetching enquiries');
    }
  }

  Future<List<EnquiryModel>> fetchPaginatedEnquiries({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get('/enquiry?page=$page&limit=$limit');

      if (response.data['success'] == true) {
        final List<dynamic> listJson = response.data['data']['enquiries'] ?? [];
        return listJson.map((json) => EnquiryModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch paginated enquiries');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while fetching paginated enquiries');
    }
  }

  Future<void> updateEnquiry(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch('/enquiry/$id', data: data);
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update enquiry');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while updating enquiry');
    }
  }
}

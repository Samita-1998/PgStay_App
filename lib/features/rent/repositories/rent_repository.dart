import 'package:dio/dio.dart';
import 'package:pgstay/core/api/api_client.dart';
import 'package:pgstay/features/rent/models/rent_model.dart';

class RentRepository {
  final ApiClient _apiClient;

  RentRepository(this._apiClient);

  Future<List<RentModel>> fetchRents({String? pgId, String? month, String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (pgId != null) queryParams['pgId'] = pgId;
      if (month != null) queryParams['rentMonth'] = month;
      if (status != null) queryParams['status'] = status;

      final response = await _apiClient.dio.get('/rent', queryParameters: queryParams);

      if (response.data['success'] == true) {
        final List<dynamic> rentsJson = response.data['data']['records'] ?? [];
        return rentsJson.map((json) => RentModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch rents');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }

  Future<void> updateRent(String rentId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch('/rent/$rentId', data: data);

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update rent');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }

  Future<void> generateRent(String pgId, String month, String dueDate) async {
    try {
      final response = await _apiClient.dio.post('/rent/auto-generate', data: {
        'pgId': pgId,
        'rentMonth': month,
        'dueDate': dueDate,
      });

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to generate rent');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }

  Future<void> createRent(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/rent', data: data);

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to create rent record');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }
}

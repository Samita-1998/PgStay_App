import 'package:dio/dio.dart';
import 'package:pgstay/core/api/api_client.dart';
import 'package:pgstay/features/rent/models/rent_model.dart';

class RentRepository {
  final ApiClient _apiClient;

  RentRepository(this._apiClient);

  Future<List<RentModel>> fetchRents({String? pgId, String? month, String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (pgId != null && pgId.trim().isNotEmpty) queryParams['pgId'] = pgId;
      if (month != null && month.trim().isNotEmpty) queryParams['rentMonth'] = month;
      if (status != null && status.trim().isNotEmpty) queryParams['status'] = status;

      final response = await _apiClient.dio.get('/rent', queryParameters: queryParams);

      if (response.data['success'] == true) {
        final data = response.data['data'];
        List<dynamic> rentsJson = [];
        if (data is List) {
          rentsJson = data;
        } else if (data is Map) {
          rentsJson = data['records'] ?? data['rents'] ?? [];
        }
        return rentsJson.map((json) => RentModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch rents');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }

  Future<List<RentModel>> fetchMyRents() async {
    try {
      final response = await _apiClient.dio.get('/rent/my-rent');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        List<dynamic> rentsJson = [];
        if (data is List) {
          rentsJson = data;
        } else if (data is Map) {
          rentsJson = data['records'] ?? data['rents'] ?? [];
        }
        return rentsJson.map((json) => RentModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch my rents');
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

  Future<Map<String, dynamic>> generateRent(String pgId, String month, String dueDate) async {
    try {
      final response = await _apiClient.dio.post('/rent/generate', data: {
        'pgId': pgId,
        'rentMonth': month,
        'dueDate': dueDate,
      });

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to generate rent');
      }
      return response.data;
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

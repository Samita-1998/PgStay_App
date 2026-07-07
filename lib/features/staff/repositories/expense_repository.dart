import 'package:dio/dio.dart';
import 'package:pgstay/core/api/api_client.dart';
import 'package:pgstay/features/staff/models/expense_model.dart';

class ExpenseRepository {
  final ApiClient _apiClient;

  ExpenseRepository(this._apiClient);

  Future<List<ExpenseModel>> fetchExpenses({
    String? month,
    int limit = 100,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'page': page,
      };
      
      if (month != null) {
        queryParams['month'] = month; // Format: 'YYYY-MM'
      }

      final response = await _apiClient.dio.get('/expenses', queryParameters: queryParams);

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final List<dynamic> expensesJson = data['expenses'] ?? [];
        return expensesJson.map((json) => ExpenseModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch expenses');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while fetching expenses');
    }
  }

  Future<ExpenseModel> addExpense({
    required String pgId,
    required double amount,
    required String category,
    required String description,
    required String spentDate,
    String? reimbursementType,
    String? onBehalfOf,
  }) async {
    try {
      final data = {
        'pgId': pgId,
        'amount': amount.truncateToDouble() == amount ? amount.toInt() : amount,
        'category': category,
        'description': description,
        'spentDate': spentDate,
        if (reimbursementType != null) 'reimbursementType': reimbursementType,
        if (onBehalfOf != null) 'onBehalfOf': onBehalfOf,
      };
      final response = await _apiClient.dio.post('/expenses', data: data);

      if (response.data['success'] == true) {
        return ExpenseModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to add expense');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while adding expense');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      final response = await _apiClient.dio.delete('/expenses/$id');

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete expense');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while deleting expense');
    }
  }

  Future<ExpenseModel> reviewExpense({
    required String id,
    required String status,
    String? reimbursementType,
    String? rejectionReason,
  }) async {
    try {
      final action = status == 'approved' ? 'approve' : 'reject';
      final data = {
        'action': action,
        if (reimbursementType != null) 'reimbursementType': reimbursementType,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      };
      
      final response = await _apiClient.dio.patch('/expenses/$id/process', data: data);

      if (response.data['success'] == true) {
        return ExpenseModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to review expense');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while reviewing expense');
    }
  }

  Future<ExpenseModel> payExpense(String id) async {
    try {
      final response = await _apiClient.dio.patch('/expenses/$id/pay');

      if (response.data['success'] == true) {
        return ExpenseModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to mark expense as paid');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while paying expense');
    }
  }
}

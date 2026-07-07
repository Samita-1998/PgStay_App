import 'package:dio/dio.dart';
import 'package:pgstay/core/api/api_client.dart';
import 'package:pgstay/features/staff/models/employee_model.dart';
import 'package:pgstay/features/staff/models/payment_model.dart';

class StaffRepository {
  final ApiClient _apiClient;

  StaffRepository(this._apiClient);

  Future<List<EmployeeModel>> fetchEmployees({int limit = 100}) async {
    try {
      final response = await _apiClient.dio.get('/employees', queryParameters: {'limit': limit});

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final List<dynamic> employeesJson = data['employees'] ?? [];
        return employeesJson.map((json) => EmployeeModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch employees');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }
  Future<EmployeeModel> addEmployee({
    required String userId,
    required List<String> pgIds,
    required Map<String, dynamic> pgSalaries,
    required double monthlySalary,
    required String joinedDate,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.post('/employees', data: {
        'userId': userId,
        'pgIds': pgIds,
        'pgSalaries': pgSalaries,
        'monthlySalary': monthlySalary,
        'joinedDate': joinedDate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });

      if (response.data['success'] == true) {
        return EmployeeModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to add employee');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }

  Future<List<EmployeeUser>> searchUsers(String query, {int limit = 10}) async {
    if (query.isEmpty) return [];
    try {
      final response = await _apiClient.dio.get('/employees/search-users', queryParameters: {
        'search': query,
        'limit': limit,
      });

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final List<dynamic> usersJson = data['users'] ?? [];
        return usersJson.map((json) => EmployeeUser.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to search users');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }
  Future<EmployeeModel> updateEmployee(
    String id, {
    required String status,
    required List<String> pgIds,
    required Map<String, dynamic> pgSalaries,
    required double monthlySalary,
    required String joinedDate,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.patch('/employees/$id', data: {
        'status': status,
        'pgIds': pgIds,
        'pgSalaries': pgSalaries,
        'monthlySalary': monthlySalary,
        'joinedDate': joinedDate,
        if (notes != null) 'notes': notes,
      });

      if (response.data['success'] == true) {
        return EmployeeModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update employee');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }

  Future<void> removeEmployee(String id) async {
    try {
      final response = await _apiClient.dio.delete('/employees/$id');
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to remove employee');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }

  Future<void> generatePayroll({
    required String employeeId,
    required String month,
    required Map<String, dynamic> customSalaries,
  }) async {
    try {
      final response = await _apiClient.dio.post('/staff-payments/generate', data: {
        'employeeId': employeeId,
        'month': month,
        'customSalaries': customSalaries,
      });

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to generate payroll');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }

  Future<List<PaymentModel>> fetchPayments({
    required String month,
    int limit = 100,
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.dio.get('/staff-payments', queryParameters: {
        'month': month,
        'limit': limit,
        'page': page,
      });

      if (response.data['success'] == true) {
        final List<dynamic> paymentsJson = response.data['data']['payments'] ?? [];
        return paymentsJson.map((json) => PaymentModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch payments');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }

  Future<void> updatePayment({
    required String paymentId,
    required double salaryAmount,
    required double reimbursedExpenses,
  }) async {
    try {
      final response = await _apiClient.dio.patch('/staff-payments/$paymentId', data: {
        'salaryAmount': salaryAmount,
        'reimbursedExpenses': reimbursedExpenses,
      });

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update payment');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }

  Future<void> markPaymentAsPaid({
    required String paymentId,
    required String paidDate,
    required String paymentMode,
    String referenceNo = '',
    String notes = '',
  }) async {
    try {
      final response = await _apiClient.dio.patch('/staff-payments/$paymentId/pay', data: {
        'paidDate': paidDate,
        'paymentMode': paymentMode,
        'referenceNo': referenceNo,
        'notes': notes,
      });

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to mark payment as paid');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred');
    }
  }
}

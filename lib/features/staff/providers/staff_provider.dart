import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/staff/models/employee_model.dart';
import 'package:pgstay/features/staff/models/payment_model.dart';
import 'package:pgstay/features/staff/repositories/staff_repository.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StaffRepository(apiClient);
});

final employeesProvider = FutureProvider.autoDispose<List<EmployeeModel>>((
  ref,
) async {
  final repository = ref.watch(staffRepositoryProvider);
  return repository.fetchEmployees(limit: 100);
});

final currentMonthProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return "${now.year}-${now.month.toString().padLeft(2, '0')}";
});

final paymentsProvider = FutureProvider.autoDispose<List<PaymentModel>>((ref) async {
  final repository = ref.watch(staffRepositoryProvider);
  final month = ref.watch(currentMonthProvider);
  return repository.fetchPayments(month: month);
});

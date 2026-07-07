import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';

import 'package:pgstay/features/staff/models/expense_model.dart';
import 'package:pgstay/features/staff/repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExpenseRepository(apiClient);
});

final currentMonthProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
});

final expensesProvider = FutureProvider<List<ExpenseModel>>((ref) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final month = ref.watch(currentMonthProvider);
  return await repository.fetchExpenses(month: month, limit: 100);
});

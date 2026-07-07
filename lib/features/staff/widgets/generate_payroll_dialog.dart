import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/features/staff/models/employee_model.dart';
import 'package:pgstay/features/staff/providers/staff_provider.dart';

class GeneratePayrollDialog extends ConsumerStatefulWidget {
  const GeneratePayrollDialog({super.key});

  @override
  ConsumerState<GeneratePayrollDialog> createState() => _GeneratePayrollDialogState();
}

class _GeneratePayrollDialogState extends ConsumerState<GeneratePayrollDialog> {
  String? _selectedPgFilter;
  EmployeeModel? _selectedEmployee;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  
  bool _isSubmitting = false;
  
  // Custom salaries mapped by PG ID
  final Map<String, TextEditingController> _salaryControllers = {};

  List<String> _generateMonths() {
    final now = DateTime.now();
    final months = <String>[];
    for (int i = 0; i < 6; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      months.add(DateFormat('yyyy-MM').format(date));
    }
    return months;
  }

  void _onEmployeeSelected(EmployeeModel? employee) {
    setState(() {
      _selectedEmployee = employee;
      _salaryControllers.forEach((_, controller) => controller.dispose());
      _salaryControllers.clear();

      if (employee != null) {
        for (final pg in employee.assignedPgs) {
          final salary = employee.pgSalaries[pg.id] ?? 0;
          _salaryControllers[pg.id] = TextEditingController(text: salary.toString());
        }
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _salaryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a staff member'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final customSalaries = <String, dynamic>{};
      for (final entry in _salaryControllers.entries) {
        customSalaries[entry.key] = double.tryParse(entry.value.text) ?? 0;
      }

      await ref.read(staffRepositoryProvider).generatePayroll(
        employeeId: _selectedEmployee!.id,
        month: _selectedMonth,
        customSalaries: customSalaries,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payroll generated successfully', style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pgsAsync = ref.watch(ownerPgsProvider);
    final employeesAsync = ref.watch(employeesProvider);
    final months = _generateMonths();

    return Dialog(
      backgroundColor: AppTheme.surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Generate Payroll Record',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Text(
                  'This creates a payroll entry for the selected month. Approved "Add to Salary" expenses for that month are automatically included.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Filter by PG
              Text(
                'Filter by PG (optional)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              pgsAsync.when(
                data: (pgs) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedPgFilter,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        hint: Text('All PGs / No filter', style: GoogleFonts.inter(color: AppTheme.textHint)),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'All PGs / No filter',
                              style: GoogleFonts.inter(color: AppTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          ...pgs.map((pg) {
                            return DropdownMenuItem<String?>(
                              value: pg.id,
                              child: Text(
                                pg.name,
                                style: GoogleFonts.inter(color: AppTheme.textPrimary),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPgFilter = value;
                            _onEmployeeSelected(null); // Reset employee selection on filter change
                          });
                        },
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const Text('Failed to load PGs', style: TextStyle(color: AppTheme.error)),
              ),
              const SizedBox(height: 24),

              // Select Staff Member
              Text(
                'Select Staff Member *',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              employeesAsync.when(
                data: (employees) {
                  final filteredEmployees = _selectedPgFilter == null
                      ? employees
                      : employees.where((e) => e.assignedPgs.any((pg) => pg.id == _selectedPgFilter)).toList();

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<EmployeeModel>(
                        value: _selectedEmployee,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        hint: Text('Choose staff...', style: GoogleFonts.inter(color: AppTheme.textHint)),
                        items: filteredEmployees.map((emp) {
                          final salaryText = emp.monthlySalary == emp.monthlySalary.toInt() 
                              ? emp.monthlySalary.toInt().toString() 
                              : emp.monthlySalary.toString();
                          return DropdownMenuItem<EmployeeModel>(
                            value: emp,
                            child: Text(
                              '${emp.user.name} (${emp.user.role}) — ₹$salaryText/mo',
                              style: GoogleFonts.inter(color: AppTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: _onEmployeeSelected,
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const Text('Failed to load staff', style: TextStyle(color: AppTheme.error)),
              ),
              
              if (_selectedEmployee != null && _selectedEmployee!.assignedPgs.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Column(
                    children: _selectedEmployee!.assignedPgs.map((pg) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                pg.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: _salaryControllers[pg.id],
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(fontSize: 14),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppTheme.surfaceBorder),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Month Selector
              Text(
                'Month *',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMonth,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    items: months.map((month) {
                      final parsed = DateFormat('yyyy-MM').parse(month);
                      final displayLabel = DateFormat('MMMM yyyy').format(parsed);
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(displayLabel, style: GoogleFonts.inter(color: AppTheme.textPrimary)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedMonth = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              Divider(color: AppTheme.surfaceBorder, height: 1),
              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _isSubmitting
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Generate',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

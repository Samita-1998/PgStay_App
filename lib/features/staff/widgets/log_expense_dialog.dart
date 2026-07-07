import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/features/staff/providers/staff_provider.dart';
import 'package:pgstay/features/staff/providers/expense_provider.dart';

class LogExpenseDialog extends ConsumerStatefulWidget {
  const LogExpenseDialog({super.key});

  @override
  ConsumerState<LogExpenseDialog> createState() => _LogExpenseDialogState();
}

class _LogExpenseDialogState extends ConsumerState<LogExpenseDialog> {
  String? _selectedPgId;
  String? _selectedStaffId;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'General';
  DateTime _spentDate = DateTime.now();
  String _reimbursementType = 'Decide later during approval';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General',
    'Maintenance',
    'Utilities',
    'Supplies',
    'Travel',
    'Food',
    'Other'
  ];

  final List<String> _reimbursementTypes = [
    'Decide later during approval',
    'Direct Pay (cash/UPI now)',
    'Add to Next Salary'
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedPgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a PG')));
      return;
    }
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a description')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(expenseRepositoryProvider);
      
      String? backendReimbType;
      if (_reimbursementType == 'Direct Pay (cash/UPI now)') backendReimbType = 'direct';
      if (_reimbursementType == 'Add to Next Salary') backendReimbType = 'add_to_salary';

      final formattedDate = DateFormat('yyyy-MM-dd').format(_spentDate);
      
      await repository.addExpense(
        pgId: _selectedPgId!,
        amount: amount,
        category: _selectedCategory,
        description: description,
        spentDate: formattedDate,
        reimbursementType: backendReimbType,
        onBehalfOf: _selectedStaffId,
      );

      ref.invalidate(expensesProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Expense logged successfully', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _spentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _spentDate) {
      setState(() {
        _spentDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch staff members for the "On Behalf of" dropdown
    final employeesAsync = ref.watch(employeesProvider);
    // Watch owner PGs for the PG dropdown
    final ownerPgsAsync = ref.watch(ownerPgsProvider);

    return Dialog(
      backgroundColor: AppTheme.surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Log Expense Claim',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // PG Dropdown
                _buildLabel('PG', isRequired: true),
                const SizedBox(height: 8),
                ownerPgsAsync.when(
                  data: (pgs) {
                    final items = pgs.map((pg) => DropdownMenuItem<String>(
                          value: pg.id,
                          child: Text(pg.name, style: GoogleFonts.inter(color: AppTheme.textPrimary)),
                        )).toList();
                    return _buildDropdown<String>(
                      value: _selectedPgId,
                      hint: 'Select PG...',
                      items: items,
                      onChanged: (value) => setState(() => _selectedPgId = value),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error loading PGs: $err', style: const TextStyle(color: AppTheme.error)),
                ),
                const SizedBox(height: 16),

                // On Behalf of Dropdown
                _buildLabel('On Behalf of (optional)'),
                const SizedBox(height: 8),
                employeesAsync.when(
                  data: (employees) {
                    final items = [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('Self (me)', style: GoogleFonts.inter(color: AppTheme.textPrimary)),
                      ),
                      ...employees.map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Text('${e.user.name} (${e.user.role})', style: GoogleFonts.inter(color: AppTheme.textPrimary)),
                          ))
                    ];
                    return _buildDropdown<String?>(
                      value: _selectedStaffId,
                      hint: 'Self (me)',
                      items: items,
                      onChanged: (value) => setState(() => _selectedStaffId = value),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading staff'),
                ),
                const SizedBox(height: 16),

                // Amount
                _buildLabel('Amount (₹)', isRequired: true),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _amountController,
                  hint: 'e.g. 500',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Description
                _buildLabel('Description', isRequired: true),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _descriptionController,
                  hint: 'What was this expense for?',
                ),
                const SizedBox(height: 16),

                // Category
                _buildLabel('Category'),
                const SizedBox(height: 8),
                _buildDropdown<String>(
                  value: _selectedCategory,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value!),
                ),
                const SizedBox(height: 16),

                // Spent Date
                _buildLabel('Spent Date', isRequired: true),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.surfaceBorder),
                      borderRadius: BorderRadius.circular(8),
                      color: AppTheme.backgroundLight,
                    ),
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(_spentDate),
                      style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Reimbursement Type
                _buildLabel('Reimbursement Type'),
                const SizedBox(height: 8),
                _buildDropdown<String>(
                  value: _reimbursementType,
                  items: _reimbursementTypes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (value) => setState(() => _reimbursementType = value!),
                ),
                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: AppTheme.textSecondary,
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: _isSubmitting 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              'Submit Claim',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
        children: [
          if (isRequired)
            TextSpan(
              text: ' *',
              style: GoogleFonts.inter(color: AppTheme.error),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.surfaceBorder),
        borderRadius: BorderRadius.circular(8),
        color: AppTheme.backgroundLight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: hint != null ? Text(hint, style: GoogleFonts.inter(color: AppTheme.textHint)) : null,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textHint),
          items: items,
          onChanged: onChanged,
          dropdownColor: AppTheme.surfaceWhite,
          style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppTheme.textHint),
        filled: true,
        fillColor: AppTheme.backgroundLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }
}

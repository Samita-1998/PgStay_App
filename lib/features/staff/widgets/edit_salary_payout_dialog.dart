import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/staff/models/payment_model.dart';
import 'package:pgstay/features/staff/providers/staff_provider.dart';

class EditSalaryPayoutDialog extends ConsumerStatefulWidget {
  final PaymentModel payment;

  const EditSalaryPayoutDialog({super.key, required this.payment});

  @override
  ConsumerState<EditSalaryPayoutDialog> createState() => _EditSalaryPayoutDialogState();
}

class _EditSalaryPayoutDialogState extends ConsumerState<EditSalaryPayoutDialog> {
  late TextEditingController _salaryController;
  late TextEditingController _expensesController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final salary = widget.payment.salaryAmount;
    final expenses = widget.payment.reimbursedExpenses;
    
    _salaryController = TextEditingController(
        text: salary == salary.toInt() ? salary.toInt().toString() : salary.toString());
    _expensesController = TextEditingController(
        text: expenses == expenses.toInt() ? expenses.toInt().toString() : expenses.toString());

    _salaryController.addListener(() => setState(() {}));
    _expensesController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _expensesController.dispose();
    super.dispose();
  }

  double get _recalculatedTotal {
    final salary = double.tryParse(_salaryController.text) ?? 0;
    final expenses = double.tryParse(_expensesController.text) ?? 0;
    return salary + expenses;
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _submit() async {
    final salary = double.tryParse(_salaryController.text);
    final expenses = double.tryParse(_expensesController.text);

    if (salary == null || expenses == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numeric amounts')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(staffRepositoryProvider).updatePayment(
            paymentId: widget.payment.id,
            salaryAmount: salary,
            reimbursedExpenses: expenses,
          );

      ref.invalidate(paymentsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payroll record updated successfully'), backgroundColor: AppTheme.success),
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
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Edit Salary Payout',
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

              // Staff Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.payment.user.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_capitalize(widget.payment.user.role)} · ${widget.payment.pgName}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Salary Amount
              RichText(
                text: TextSpan(
                  text: 'Salary Amount (₹) ',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  children: [
                    TextSpan(text: '*', style: GoogleFonts.inter(color: AppTheme.error)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _salaryController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.surfaceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Reimbursed Expenses
              RichText(
                text: TextSpan(
                  text: 'Reimbursed Expenses (₹) ',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  children: [
                    TextSpan(text: '*', style: GoogleFonts.inter(color: AppTheme.error)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _expensesController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.surfaceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Recalculated Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recalculated Total:',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '₹${_recalculatedTotal.toInt()}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
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
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: AppTheme.textSecondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text('Save Changes', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
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

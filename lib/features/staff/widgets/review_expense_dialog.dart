import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/staff/models/expense_model.dart';
import 'package:pgstay/features/staff/providers/expense_provider.dart';

class ReviewExpenseDialog extends ConsumerStatefulWidget {
  final ExpenseModel expense;

  const ReviewExpenseDialog({super.key, required this.expense});

  @override
  ConsumerState<ReviewExpenseDialog> createState() => _ReviewExpenseDialogState();
}

class _ReviewExpenseDialogState extends ConsumerState<ReviewExpenseDialog> {
  bool _isApprove = true;
  String _reimbursementType = 'direct'; // 'direct' or 'add_to_salary'
  bool _isSubmitting = false;
  final TextEditingController _rejectionReasonController = TextEditingController();

  final List<Map<String, String>> _reimbursementOptions = [
    {'value': 'direct', 'label': '💸 Direct Pay — Pay immediately'},
    {'value': 'add_to_salary', 'label': '📅 Add to Salary — Include in next payroll'},
  ];

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(expenseRepositoryProvider);
      
      await repository.reviewExpense(
        id: widget.expense.id,
        status: _isApprove ? 'approved' : 'rejected',
        reimbursementType: _isApprove ? _reimbursementType : null,
        rejectionReason: !_isApprove ? _rejectionReasonController.text.trim() : null,
      );

      ref.invalidate(expensesProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Expense claim ${_isApprove ? 'approved' : 'rejected'} successfully', style: const TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceWhite, // Following light theme as previously established
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Review Expense Claim',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Expense Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.expense.spentBy.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${widget.expense.amount == widget.expense.amount.toInt() ? widget.expense.amount.toInt() : widget.expense.amount}',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.expense.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('dd MMM yyyy').format(widget.expense.spentDate)} · ${widget.expense.category}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Approve / Reject Toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isApprove = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isApprove ? AppTheme.success.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isApprove ? AppTheme.success.withOpacity(0.5) : AppTheme.surfaceBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, 
                              color: _isApprove ? AppTheme.success : AppTheme.textSecondary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Approve',
                            style: GoogleFonts.inter(
                              color: _isApprove ? AppTheme.success : AppTheme.textSecondary,
                              fontWeight: _isApprove ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isApprove = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isApprove ? AppTheme.error.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: !_isApprove ? AppTheme.error.withOpacity(0.5) : AppTheme.surfaceBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel_outlined, 
                              color: !_isApprove ? AppTheme.error : AppTheme.textSecondary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Reject',
                            style: GoogleFonts.inter(
                              color: !_isApprove ? AppTheme.error : AppTheme.textSecondary,
                              fontWeight: !_isApprove ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_isApprove) ...[
              Text(
                'Reimbursement Method *',
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
                    value: _reimbursementType,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                    items: _reimbursementOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option['value'],
                        child: Text(option['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _reimbursementType = value;
                        });
                      }
                    },
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Rejection Reason',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _rejectionReasonController,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Why is this being rejected?',
                  hintStyle: GoogleFonts.inter(color: AppTheme.textHint),
                  filled: true,
                  fillColor: AppTheme.backgroundLight,
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
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
            ],

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
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.success))
                      : TextButton(
                          onPressed: _submit,
                          child: Text(
                            _isApprove ? 'Approve Claim' : 'Reject Claim',
                            style: GoogleFonts.inter(
                              color: _isApprove ? AppTheme.success : AppTheme.error,
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
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/rent/models/rent_model.dart';
import 'package:pgstay/features/rent/repositories/rent_repository.dart';
import 'package:pgstay/features/rent/providers/rent_provider.dart';

class EditPaymentDialog extends ConsumerStatefulWidget {
  final RentModel rent;
  const EditPaymentDialog({super.key, required this.rent});

  @override
  ConsumerState<EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends ConsumerState<EditPaymentDialog> {
  late String _status;
  late String? _paymentMode;
  late TextEditingController _amountPaidCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _referenceNoCtrl;
  DateTime? _paymentDate;

  bool _isSaving = false;

  final List<String> _statusOptions = ['pending', 'paid', 'partial', 'under review'];
  final List<String> _paymentModeOptions = ['cash', 'upi', 'bank_transfer', 'cheque', 'online'];

  @override
  void initState() {
    super.initState();
    _status = widget.rent.status;
    // Map existing status to supported options if needed
    if (!_statusOptions.contains(_status)) _status = 'pending';

    _paymentMode = widget.rent.paymentMethod;
    _amountPaidCtrl = TextEditingController(text: widget.rent.paidAmount > 0 ? widget.rent.paidAmount.toInt().toString() : '');
    _notesCtrl = TextEditingController(text: widget.rent.staffRemarks ?? '');
    _referenceNoCtrl = TextEditingController(text: widget.rent.receiptNo ?? '');
    _paymentDate = widget.rent.paidDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountPaidCtrl.dispose();
    _notesCtrl.dispose();
    _referenceNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _paymentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _paymentDate = date);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(rentRepositoryProvider);
      
      final data = <String, dynamic>{
        'status': _status,
        'amountPaid': double.tryParse(_amountPaidCtrl.text) ?? 0.0,
      };

      if (_status == 'paid' || _status == 'partial') {
        data['paymentMode'] = _paymentMode;
        data['paidDate'] = _paymentDate?.toIso8601String();
        data['referenceNo'] = _referenceNoCtrl.text.trim();
      }
      
      if (_notesCtrl.text.trim().isNotEmpty) {
        data['notes'] = _notesCtrl.text.trim();
      }

      await repo.updateRent(widget.rent.id, data);
      ref.invalidate(pgRentsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment record updated!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatMonth(String monthStr) {
    try {
      final parts = monthStr.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('MMMM, yyyy').format(date);
    } catch (_) {
      return monthStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E), // Darker premium look as per image
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Payment Record',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // User Info Badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Text(
                      '${widget.rent.userName ?? 'Tenant'} · Bed ${widget.rent.bedNumber ?? 'N/A'} · ${widget.rent.month}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Fields Row 1
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputGroup(
                          label: 'Rent Month *',
                          child: _buildDisabledField(_formatMonth(widget.rent.month), icon: Icons.calendar_today_rounded),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInputGroup(
                          label: 'Due Date *',
                          child: _buildDisabledField(DateFormat('yyyy-MM-dd').format(widget.rent.dueDate)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Form Fields Row 2
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputGroup(
                          label: 'Rent Amount (₹) *',
                          child: _buildDisabledField(widget.rent.amount.toInt().toString()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInputGroup(
                          label: 'PAYMENT STATUS',
                          child: _buildDropdown(
                            value: _status,
                            items: _statusOptions,
                            onChanged: (val) {
                              if (val != null) setState(() => _status = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Form Fields Row 3
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputGroup(
                          label: 'Amount Paid (₹) *',
                          child: _buildTextField(_amountPaidCtrl, keyboardType: TextInputType.number),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInputGroup(
                          label: 'PAYMENT MODE',
                          child: (_status == 'paid' || _status == 'partial')
                              ? _buildDropdown(
                                  value: _paymentMode,
                                  items: _paymentModeOptions,
                                  hint: '-- Select Mode --',
                                  onChanged: (val) {
                                    if (val != null) setState(() => _paymentMode = val);
                                  },
                                )
                              : _buildDisabledField('-- No Payment Mode --', dropdownIcon: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Form Fields Row 4
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputGroup(
                          label: 'Payment Date',
                          child: GestureDetector(
                            onTap: (_status == 'paid' || _status == 'partial') ? _pickDate : null,
                            child: _buildDisabledField(
                              _paymentDate != null ? DateFormat('yyyy-MM-dd').format(_paymentDate!) : 'Select date...',
                              enabled: (_status == 'paid' || _status == 'partial'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInputGroup(
                          label: 'Reference / Txn ID',
                          child: _buildTextField(
                            _referenceNoCtrl,
                            hint: 'UPI ID, cheque no...',
                            enabled: (_status == 'paid' || _status == 'partial'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  _buildInputGroup(
                    label: 'Notes',
                    child: _buildTextField(_notesCtrl, hint: 'Any remarks...', maxLines: 2),
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B4EFF), // Exact purple from image
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Changes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputGroup({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildDisabledField(String text, {IconData? icon, bool dropdownIcon = false, bool enabled = false}) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: enabled ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: enabled ? Colors.white : Colors.white54,
            ),
          ),
          if (icon != null) Icon(icon, color: Colors.white54, size: 16),
          if (dropdownIcon) const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 20),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, {String? hint, int maxLines = 1, TextInputType? keyboardType, bool enabled = true}) {
    return Container(
      height: maxLines == 1 ? 44 : null,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: enabled ? Colors.white : Colors.white54,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdown({required String? value, required List<String> items, required ValueChanged<String?> onChanged, String? hint}) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          hint: hint != null ? Text(hint, style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 13)) : null,
          isExpanded: true,
          dropdownColor: const Color(0xFF2A2A3C),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 20),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          onChanged: onChanged,
          items: items.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e.toUpperCase().replaceAll('_', ' ')),
            );
          }).toList(),
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/rent/models/rent_model.dart';
import 'package:pgstay/features/rent/models/rent_model.dart';
import 'package:pgstay/features/rent/providers/rent_provider.dart';
import 'package:pgstay/core/utils/change_tracker.dart';

class EditPaymentScreen extends ConsumerStatefulWidget {
  final RentModel rent;
  const EditPaymentScreen({super.key, required this.rent});

  @override
  ConsumerState<EditPaymentScreen> createState() => _EditPaymentScreenState();
}

class _EditPaymentScreenState extends ConsumerState<EditPaymentScreen> {
  late String _status;
  late String? _paymentMode;
  late TextEditingController _amountPaidCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _referenceNoCtrl;
  DateTime? _paymentDate;

  bool _isSaving = false;
  late final ChangeTracker _tracker;

  bool get _hasChanges => _tracker.hasChanges;

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

    _tracker = ChangeTracker(onStateChanged: () {
      if (mounted) setState(() {});
    });

    _tracker.setOriginal('status', _status);
    _tracker.setOriginal('paymentMode', _paymentMode);
    _tracker.setOriginal('amountPaid', _amountPaidCtrl.text);
    _tracker.setOriginal('notes', _notesCtrl.text);
    _tracker.setOriginal('referenceNo', _referenceNoCtrl.text);
    _tracker.setOriginal('paymentDate', _paymentDate?.toIso8601String());

    void addTrackerListener(TextEditingController ctrl, String key) {
      ctrl.addListener(() {
        _tracker.updateValue(key, ctrl.text);
      });
    }

    addTrackerListener(_amountPaidCtrl, 'amountPaid');
    addTrackerListener(_notesCtrl, 'notes');
    addTrackerListener(_referenceNoCtrl, 'referenceNo');
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
      setState(() {
        _paymentDate = date;
        _tracker.updateValue('paymentDate', date.toIso8601String());
      });
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
            content: Text('Payment record updated!', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          'Edit Payment',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
                ),
                child: Text(
                  '${widget.rent.userName ?? 'Tenant'} · Bed ${widget.rent.bedNumber ?? 'N/A'} · ${widget.rent.month}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
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
                              if (val != null) {
                                setState(() {
                                  _status = val;
                                  _tracker.updateValue('status', val);
                                });
                              }
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
                                    if (val != null) {
                                      setState(() {
                                        _paymentMode = val;
                                        _tracker.updateValue('paymentMode', val);
                                      });
                                    }
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
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              color: AppTheme.textHint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_isSaving || !_hasChanges) ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(
                                  'Save Changes',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
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

  Widget _buildInputGroup({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textHint,
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
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: enabled ? AppTheme.textPrimary : AppTheme.textHint,
              ),
            ),
          ),
          if (icon != null) Icon(icon, color: AppTheme.textHint, size: 18),
          if (dropdownIcon) const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textHint, size: 20),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, {String? hint, int maxLines = 1, TextInputType? keyboardType, bool enabled = true}) {
    return Container(
      height: maxLines == 1 ? 48 : null,
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: enabled ? AppTheme.textPrimary : AppTheme.textHint,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppTheme.textHint, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdown({required String? value, required List<String> items, required ValueChanged<String?> onChanged, String? hint}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          hint: hint != null ? Text(hint, style: GoogleFonts.inter(color: AppTheme.textHint, fontSize: 14)) : null,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textHint, size: 20),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          onChanged: onChanged,
          items: items.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(
                e.toUpperCase().replaceAll('_', ' '),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

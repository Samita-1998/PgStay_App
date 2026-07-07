import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/features/rent/models/rent_model.dart';
import 'package:pgstay/features/rent/providers/rent_provider.dart';

class RecordPaymentScreen extends ConsumerStatefulWidget {
  const RecordPaymentScreen({super.key});

  @override
  ConsumerState<RecordPaymentScreen> createState() =>
      _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPgId;
  String? _selectedTenantBedId;
  String? _selectedRoomId;
  String? _selectedUserId;

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime? _joiningDate;
  DateTime? _paymentDate;

  final _rentAmountCtrl = TextEditingController();
  final _amountPaidCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _paymentStatus = 'paid';
  String _paymentMode = 'cash';

  bool _isLoadingTenants = false;
  bool _isSubmitting = false;

  // List of formatted strings or objects for the autocomplete
  List<Map<String, dynamic>> _eligibleTenants = [];
  Map<String, dynamic>? _selectedTenantObj;

  final _tenantSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default joining/payment dates
    _joiningDate = DateTime.now();
    _paymentDate = DateTime.now();
  }

  @override
  void dispose() {
    _rentAmountCtrl.dispose();
    _amountPaidCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    _tenantSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchEligibleTenants() async {
    if (_selectedPgId == null) return;
    setState(() {
      _isLoadingTenants = true;
      _eligibleTenants.clear();
      _selectedTenantObj = null;
      _selectedTenantBedId = null;
      _selectedRoomId = null;
      _selectedUserId = null;
      _tenantSearchCtrl.clear();
    });

    try {
      final pgRepo = ref.read(pgListingRepositoryProvider);
      final rentRepo = ref.read(rentRepositoryProvider);

      // 1. Fetch Rooms/Beds
      final rooms = await pgRepo.fetchRooms(_selectedPgId!);

      // 2. Fetch Existing Rents for this month
      final monthStr =
          '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
      final existingRents = await rentRepo.fetchRents(
        pgId: _selectedPgId,
        month: monthStr,
      );
      final existingUserIds = existingRents.map((r) => r.userId).toSet();

      final List<Map<String, dynamic>> tenants = [];

      for (var room in rooms) {
        final roomId = room['_id'];
        final roomNo = room['roomNumber'] ?? '';
        final beds = room['beds'] as List<dynamic>? ?? [];

        for (var bed in beds) {
          final isOccupied = bed['userId'] != null || bed['tenantName'] != null;
          if (isOccupied) {
            final userId =
                bed['userId']?['_id'] ?? bed['userId'] ?? 'unknown_user';

            // Filter out if already has rent
            if (!existingUserIds.contains(userId)) {
              final tenantName =
                  bed['tenantName'] ??
                  bed['userId']?['name'] ??
                  'Unknown Tenant';
              final bedId = bed['_id'];
              final bedNo = bed['bedNumber'] ?? '';

              tenants.add({
                'display': '$tenantName (Bed $bedNo, Room $roomNo)',
                'userId': userId,
                'roomId': roomId,
                'bedId': bedId,
                'tenantName': tenantName,
                'bedNo': bedNo,
                'roomNo': roomNo,
                'price': (bed['price'] ?? 0).toString(),
              });
            }
          }
        }
      }

      setState(() {
        _eligibleTenants = tenants;
      });
    } catch (e) {
      // Handle error gently
    } finally {
      if (mounted) setState(() => _isLoadingTenants = false);
    }
  }

  String _monthLabel(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]}, ${d.year}';
  }

  String _dateLabel(DateTime? d) {
    if (d == null) return 'Select date...';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, 1);
    final lastDate = DateTime(now.year + 1, 12);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accentColor,
            surface: AppTheme.surfaceWhite,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
      _fetchEligibleTenants();
    }
  }

  Future<void> _pickJoiningDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accentColor,
            surface: AppTheme.surfaceWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _joiningDate = picked);
    }
  }

  Future<void> _pickPaymentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accentColor,
            surface: AppTheme.surfaceWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPgId == null || _selectedTenantObj == null) {
      _showSnack('Please select PG and Tenant.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(rentRepositoryProvider);

      final monthStr =
          '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

      final payload = {
        'pgId': _selectedPgId,
        'userId': _selectedUserId,
        'roomId': _selectedRoomId,
        'bedId': _selectedTenantBedId,
        'rentMonth': monthStr,
        'dueDate':
            _joiningDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'amount': double.tryParse(_rentAmountCtrl.text) ?? 0,
        'status': _paymentStatus,
      };

      if (_paymentStatus == 'paid' || _paymentStatus == 'partial') {
        payload['paidAmount'] = double.tryParse(_amountPaidCtrl.text) ?? 0;
        payload['paymentMode'] = _paymentMode;
        payload['paidDate'] =
            _paymentDate?.toIso8601String() ?? DateTime.now().toIso8601String();

        if (_referenceCtrl.text.isNotEmpty) {
          payload['referenceNo'] = _referenceCtrl.text;
        }
      }

      if (_notesCtrl.text.isNotEmpty) {
        payload['notes'] = _notesCtrl.text;
      }

      await repo.createRent(payload);

      if (mounted) {
        ref.invalidate(pgRentsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment recorded successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg.replaceAll('Exception: ', '')),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── UI BUILDERS ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pgsAsync = ref.watch(ownerPgsProvider);
    final isPaidOrPartial =
        _paymentStatus == 'paid' || _paymentStatus == 'partial';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          'Record Payment',
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                      // Select PG
                      _buildLabel('SELECT PG', required: true),
                      const SizedBox(height: 8),
                      pgsAsync.when(
                        data: (pgs) => DropdownButtonFormField<String>(
                          value: _selectedPgId,
                          hint: Text(
                            '-- Select PG --',
                            style: TextStyle(color: AppTheme.textHint),
                          ),
                          dropdownColor: Colors.white,
                          items: pgs
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedPgId = v;
                            });
                            _fetchEligibleTenants();
                          },
                          decoration: _inputDeco(),
                          validator: (v) => v == null ? 'Select PG' : null,
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Text(
                          'Error loading PGs',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Select Tenant Bed
                      _buildLabel('SELECT TENANT BED', required: true),
                      const SizedBox(height: 8),
                      Autocomplete<Map<String, dynamic>>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty)
                            return _eligibleTenants;
                          return _eligibleTenants.where(
                            (t) => t['display'].toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            ),
                          );
                        },
                        displayStringForOption: (option) => option['display'],
                        onSelected: (option) {
                          setState(() {
                            _selectedTenantObj = option;
                            _selectedTenantBedId = option['bedId'];
                            _selectedRoomId = option['roomId'];
                            _selectedUserId = option['userId'];

                            if (_rentAmountCtrl.text.isEmpty) {
                              _rentAmountCtrl.text = option['price'].toString();
                            }
                            if (_amountPaidCtrl.text.isEmpty &&
                                _paymentStatus == 'paid') {
                              _amountPaidCtrl.text = option['price'].toString();
                            }
                          });
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textEditingController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              return TextFormField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                ),
                                decoration: _inputDeco().copyWith(
                                  hintText:
                                      'Type tenant name, bed no, or room no...',
                                  hintStyle: TextStyle(
                                    color: AppTheme.textHint,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: Colors.cyanAccent,
                                    size: 18,
                                  ),
                                  suffixIcon: _isLoadingTenants
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                validator: (v) => _selectedTenantObj == null
                                    ? 'Select tenant'
                                    : null,
                              );
                            },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                width:
                                    MediaQuery.of(context).size.width - 88 > 400
                                    ? 400
                                    : MediaQuery.of(context).size.width - 88,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.surfaceBorder,
                                  ),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      title: Text(
                                        option['display'],
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_rounded,
                            color: Colors.blueAccent,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Only displaying occupied beds that do not have an existing rent record for the selected month.',
                              style: TextStyle(
                                color: AppTheme.textHint,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Rent Month', required: true),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _pickMonth,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.surfaceBorder,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _monthLabel(_selectedMonth),
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Icon(
                                          Icons.calendar_month_rounded,
                                          color: AppTheme.textHint,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(
                                  'Check-in / Joining Date',
                                  required: true,
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _pickJoiningDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.surfaceBorder,
                                      ),
                                    ),
                                    child: Text(
                                      _dateLabel(_joiningDate),
                                      style: TextStyle(
                                        color: _joiningDate == null
                                            ? AppTheme.textHint
                                            : AppTheme.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Rent Amount (₹)', required: true),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _rentAmountCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                  ),
                                  decoration: _inputDeco(),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('PAYMENT STATUS'),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _paymentStatus,
                                  dropdownColor: Colors.white,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'paid',
                                      child: Text(
                                        'Paid (Full)',
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'partial',
                                      child: Text(
                                        'Partial',
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'pending',
                                      child: Text(
                                        'Pending',
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      _paymentStatus = v!;
                                      if (v == 'paid') {
                                        _amountPaidCtrl.text =
                                            _rentAmountCtrl.text;
                                      }
                                    });
                                  },
                                  decoration: _inputDeco(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(
                                  'Amount Paid (₹)',
                                  required: isPaidOrPartial,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _amountPaidCtrl,
                                  enabled: isPaidOrPartial,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: isPaidOrPartial
                                        ? AppTheme.textPrimary
                                        : AppTheme.textHint,
                                  ),
                                  decoration: _inputDeco(
                                    enabled: isPaidOrPartial,
                                  ),
                                  validator: (v) =>
                                      isPaidOrPartial && v!.isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('PAYMENT MODE'),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _paymentMode,
                                  dropdownColor: Colors.white,
                                  isExpanded: true,
                                  items:
                                      [
                                            'cash',
                                            'upi',
                                            'bank_transfer',
                                            'cheque',
                                            'online',
                                          ]
                                          .map(
                                            (m) => DropdownMenuItem(
                                              value: m,
                                              child: Text(
                                                m.toUpperCase().replaceAll(
                                                  '_',
                                                  ' ',
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isPaidOrPartial
                                                      ? AppTheme.textPrimary
                                                      : AppTheme.textHint,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: isPaidOrPartial
                                      ? (v) => setState(() => _paymentMode = v!)
                                      : null,
                                  decoration: _inputDeco(
                                    enabled: isPaidOrPartial,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Payment Date'),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: isPaidOrPartial
                                      ? _pickPaymentDate
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPaidOrPartial
                                          ? AppTheme.backgroundLight
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.surfaceBorder,
                                      ),
                                    ),
                                    child: Text(
                                      _dateLabel(_paymentDate),
                                      style: TextStyle(
                                        color: isPaidOrPartial
                                            ? AppTheme.textPrimary
                                            : AppTheme.textHint,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Reference / Txn ID'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _referenceCtrl,
                                  enabled: isPaidOrPartial,
                                  style: TextStyle(
                                    color: isPaidOrPartial
                                        ? AppTheme.textPrimary
                                        : AppTheme.textHint,
                                  ),
                                  decoration: _inputDeco(
                                    enabled: isPaidOrPartial,
                                  ).copyWith(hintText: 'UPI ID, cheque no...'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Notes'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco().copyWith(
                          hintText: 'Any remarks...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Footer
                      Container(
                        padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.surfaceBorder)),
              ),
              child: Row(
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
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Record Payment',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppTheme.textHint,
          letterSpacing: 0.5,
        ),
        children: required
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppTheme.error),
                ),
              ]
            : [],
      ),
    );
  }

  InputDecoration _inputDeco({bool enabled = true}) {
    return InputDecoration(
      filled: true,
      fillColor: enabled ? AppTheme.backgroundLight : Colors.transparent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.surfaceBorder),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.surfaceBorder.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: AppTheme.textHint, fontSize: 14),
    );
  }
}

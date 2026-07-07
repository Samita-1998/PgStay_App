import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/features/staff/models/employee_model.dart';
import 'package:pgstay/features/staff/providers/staff_provider.dart';

class EditStaffBottomSheet extends ConsumerStatefulWidget {
  final EmployeeModel employee;

  const EditStaffBottomSheet({super.key, required this.employee});

  @override
  ConsumerState<EditStaffBottomSheet> createState() => _EditStaffBottomSheetState();
}

class _EditStaffBottomSheetState extends ConsumerState<EditStaffBottomSheet> {
  final TextEditingController _notesController = TextEditingController();
  
  late String _status;
  final Set<String> _selectedPgIds = {};
  final Map<String, TextEditingController> _salaryControllers = {};
  DateTime? _joinDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _status = widget.employee.status;
    _joinDate = widget.employee.joinedDate;
    if (widget.employee.notes != null) {
      _notesController.text = widget.employee.notes!;
    }
    
    for (var pg in widget.employee.assignedPgs) {
      _selectedPgIds.add(pg.id);
      final salary = widget.employee.pgSalaries[pg.id] ?? 0;
      _salaryControllers[pg.id] = TextEditingController(text: salary > 0 ? salary.toString() : '');
      _salaryControllers[pg.id]!.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (var controller in _salaryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _totalSalary {
    double total = 0;
    for (var id in _selectedPgIds) {
      final text = _salaryControllers[id]?.text ?? '';
      if (text.isNotEmpty) {
        total += double.tryParse(text) ?? 0;
      }
    }
    return total;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _joinDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
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
    if (picked != null && picked != _joinDate) {
      setState(() {
        _joinDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedPgIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one PG')),
      );
      return;
    }
    if (_joinDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a joining date')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Map<String, dynamic> pgSalaries = {};
      for (var id in _selectedPgIds) {
        final text = _salaryControllers[id]?.text ?? '0';
        pgSalaries[id] = double.tryParse(text) ?? 0;
      }

      final repository = ref.read(staffRepositoryProvider);
      await repository.updateEmployee(
        widget.employee.id,
        status: _status,
        pgIds: _selectedPgIds.toList(),
        pgSalaries: pgSalaries,
        monthlySalary: _totalSalary,
        joinedDate: DateFormat('yyyy-MM-dd').format(_joinDate!),
        notes: _notesController.text.trim(),
      );
      
      ref.invalidate(employeesProvider);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff member updated successfully'), backgroundColor: AppTheme.success),
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
    final ownerPgsAsync = ref.watch(ownerPgsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle for bottom sheet
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Edit — ${widget.employee.user.name}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textHint, size: 24),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, color: AppTheme.surfaceBorder),
            
            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status
                    Text(
                      'Status',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _status,
                          dropdownColor: AppTheme.surfaceWhite,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textHint),
                          style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'active', child: Text('Active')),
                            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _status = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Assign to PGs
                    RichText(
                      text: TextSpan(
                        text: 'Assign to PGs ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                        children: [
                          TextSpan(text: '*', style: GoogleFonts.inter(color: AppTheme.error)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: ownerPgsAsync.when(
                        data: (pgs) {
                          if (pgs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('No PGs available', style: GoogleFonts.inter(color: AppTheme.textHint)),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: pgs.length,
                            itemBuilder: (context, index) {
                              final pg = pgs[index];
                              final isSelected = _selectedPgIds.contains(pg.id);
                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedPgIds.add(pg.id);
                                      if (!_salaryControllers.containsKey(pg.id)) {
                                        _salaryControllers[pg.id] = TextEditingController();
                                        _salaryControllers[pg.id]!.addListener(() => setState(() {}));
                                      }
                                    } else {
                                      _selectedPgIds.remove(pg.id);
                                    }
                                  });
                                },
                                title: Text(
                                  pg.name,
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                activeColor: AppTheme.primary,
                                checkColor: Colors.white,
                                side: const BorderSide(color: AppTheme.textHint),
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                              );
                            },
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Failed to load PGs', style: GoogleFonts.inter(color: AppTheme.error)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Salary Per PG Section
                    if (_selectedPgIds.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'SALARY PER PG',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textHint,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ownerPgsAsync.maybeWhen(
                              data: (pgs) {
                                final selectedPgs = pgs.where((pg) => _selectedPgIds.contains(pg.id)).toList();
                                return Column(
                                  children: selectedPgs.map((pg) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              pg.name,
                                              style: GoogleFonts.inter(
                                                color: AppTheme.textPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Container(
                                            width: 100,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: AppTheme.backgroundLight,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppTheme.surfaceBorder),
                                            ),
                                            child: TextField(
                                              controller: _salaryControllers[pg.id],
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                                hintText: '0',
                                                hintStyle: GoogleFonts.inter(color: AppTheme.textHint, fontSize: 13),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                              orElse: () => const SizedBox.shrink(),
                            ),
                            const Divider(color: AppTheme.surfaceBorder, height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Monthly Salary:',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                Text(
                                  '₹${_totalSalary.toInt()}',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Joining Date
                    RichText(
                      text: TextSpan(
                        text: 'Joining Date ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                        children: [
                          TextSpan(text: '*', style: GoogleFonts.inter(color: AppTheme.error)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: Text(
                          _joinDate == null ? 'Select date...' : DateFormat('yyyy-MM-dd').format(_joinDate!),
                          style: GoogleFonts.inter(
                            color: _joinDate == null ? AppTheme.textHint : AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Notes
                    Text(
                      'Notes',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Any remarks...',
                          hintStyle: GoogleFonts.inter(color: AppTheme.textHint, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32), // bottom padding
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceWhite,
                border: Border(top: BorderSide(color: AppTheme.surfaceBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
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
                        disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            'Save Changes',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
    );
  }
}

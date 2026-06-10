import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/rent/models/rent_model.dart';
import 'package:pgstay/features/rent/providers/rent_provider.dart';

// ─── Date helpers (no intl dependency needed) ────────────────────────────────
String _fmtDate(DateTime d) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${d.day.toString().padLeft(2,'0')} ${months[d.month - 1]} ${d.year}';
}

String _monthLabel(String ym) {
  // "2025-06" → "June 2025"
  final parts = ym.split('-');
  if (parts.length != 2) return ym;
  const m = ['','January','February','March','April','May','June','July','August','September','October','November','December'];
  final idx = int.tryParse(parts[1]) ?? 0;
  return '${(idx > 0 && idx < 13) ? m[idx] : parts[1]} ${parts[0]}';
}

String _currentYM() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class RentTrackerScreen extends ConsumerStatefulWidget {
  const RentTrackerScreen({super.key});

  @override
  ConsumerState<RentTrackerScreen> createState() => _RentTrackerScreenState();
}

class _RentTrackerScreenState extends ConsumerState<RentTrackerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _selectedMonth = _currentYM();
  String? _selectedStatus; // null = all

  final _statusFilters = <String?, String>{
    null: 'All',
    'pending': 'Pending',
    'paid': 'Paid',
    'overdue': 'Overdue',
    'waived': 'Waived',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;
    final isOwnerOrManager = user?.role == 'owner' || user?.role == 'manager';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isOwnerOrManager),
          if (isOwnerOrManager) _buildTabBar(),
          SliverToBoxAdapter(child: _buildFilterBar()),
          isOwnerOrManager
              ? _buildOwnerRentList()
              : _buildTenantRentList(),
        ],
      ),
    );
  }

  // ── Sliver App Bar ──────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(bool isOwnerOrManager) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.backgroundLight,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💰 Rent Tracker',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOwnerOrManager
                        ? 'Manage monthly rent collection'
                        : 'Track your monthly payments',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        title: Text(
          'Rent Tracker',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        collapseMode: CollapseMode.parallax,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
    );
  }

  // ── Tab bar (owner only) ────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return SliverToBoxAdapter(
      child: Container(
        color: AppTheme.backgroundLight,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceBorder.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'All Records'),
          ],
        ),
      ),
    );
  }

  // ── Month + status filter bar ───────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month picker row
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.textHint),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _pickMonth,
                child: Row(
                  children: [
                    Text(
                      _monthLabel(_selectedMonth),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                  ],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() {
                  _selectedMonth = _currentYM();
                  _selectedStatus = null;
                }),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Reset'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.entries.map((e) {
                final isSelected = _selectedStatus == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedStatus = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : AppTheme.surfaceBorder,
                          width: 1.5,
                        ),
                        boxShadow: isSelected ? AppTheme.primaryGlow(opacity: 0.12) : [],
                      ),
                      child: Text(
                        e.value,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tenant view ─────────────────────────────────────────────────────────────
  Widget _buildTenantRentList() {
    final rentsAsync = ref.watch(myRentsProvider);

    return rentsAsync.when(
      data: (allRents) {
        final rents = _filterRents(allRents);
        return _buildRentListSliver(rents, isOwner: false);
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(80),
          child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(child: _buildErrorState(e.toString())),
    );
  }

  // ── Owner view ──────────────────────────────────────────────────────────────
  Widget _buildOwnerRentList() {
    final rentsAsync = ref.watch(pgRentsProvider(''));

    return rentsAsync.when(
      data: (allRents) {
        final rents = _filterRents(allRents);
        return SliverToBoxAdapter(
          child: Column(
            children: [
              _buildSummaryCards(allRents),
              ...rents.map((r) => Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: _buildRentCard(r, isOwner: true),
              )),
              if (rents.isEmpty) _buildEmptyState(),
              const SizedBox(height: 120),
            ],
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(80),
          child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(child: _buildErrorState(e.toString())),
    );
  }

  // ── Summary cards row ───────────────────────────────────────────────────────
  Widget _buildSummaryCards(List<RentModel> rents) {
    final total = rents.fold(0.0, (s, r) => s + r.amount);
    final collected = rents.where((r) => r.status == 'paid').fold(0.0, (s, r) => s + r.paidAmount);
    final pending = rents.where((r) => r.status == 'pending').fold(0.0, (s, r) => s + r.amount);
    final overdue = rents.where((r) => r.status == 'overdue').fold(0.0, (s, r) => s + r.amount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _summaryTile('Total', total, AppTheme.textSecondary, Icons.receipt_long_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _summaryTile('Collected', collected, AppTheme.success, Icons.check_circle_outline)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _summaryTile('Pending', pending, AppTheme.warning, Icons.schedule_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _summaryTile('Overdue', overdue, AppTheme.error, Icons.error_outline)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textHint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${amount.toInt()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Rent list as SliverList ─────────────────────────────────────────────────
  Widget _buildRentListSliver(List<RentModel> rents, {required bool isOwner}) {
    if (rents.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState());
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildRentCard(rents[i], isOwner: isOwner),
          ),
          childCount: rents.length,
        ),
      ),
    );
  }

  // ── Single rent card ────────────────────────────────────────────────────────
  Widget _buildRentCard(RentModel rent, {required bool isOwner}) {
    final statusMap = _statusMeta(rent.status);
    final Color sColor = statusMap['color'] as Color;
    final String sLabel = statusMap['label'] as String;
    final IconData sIcon = statusMap['icon'] as IconData;
    final isActionable = rent.status == 'pending' || rent.status == 'overdue';
    final daysLeft = rent.dueDate.difference(DateTime.now()).inDays;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActionable && !isOwner
              ? sColor.withValues(alpha: 0.3)
              : AppTheme.surfaceBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sIcon, size: 13, color: sColor),
                      const SizedBox(width: 4),
                      Text(
                        sLabel.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: sColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _monthLabel(rent.month),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Amount + due date ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount Due',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textHint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${rent.amount.toInt()}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Due Date',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textHint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fmtDate(rent.dueDate),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isActionable && rent.dueDate.isBefore(DateTime.now())
                            ? AppTheme.error
                            : AppTheme.textPrimary,
                      ),
                    ),
                    if (isActionable && daysLeft >= 0)
                      Text(
                        '$daysLeft days left',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: daysLeft <= 3 ? AppTheme.error : AppTheme.warning,
                        ),
                      ),
                    if (isActionable && daysLeft < 0)
                      Text(
                        '${daysLeft.abs()} days overdue',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.error,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── PG / Tenant info ──
          if (rent.pgName != null || rent.userName != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Divider(color: AppTheme.dividerColor, height: 1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  if (rent.userName != null) ...[
                    const Icon(Icons.person_outline, size: 15, color: AppTheme.textHint),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        rent.userName!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (rent.pgName != null) ...[
                    const Icon(Icons.apartment_rounded, size: 15, color: AppTheme.textHint),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        rent.pgName!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (rent.bedNumber != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.bed_outlined, size: 15, color: AppTheme.textHint),
                    const SizedBox(width: 4),
                    Text(
                      'Bed ${rent.bedNumber}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ── Paid info or receipt ──
          if (rent.status == 'paid' && rent.paidDate != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 15, color: AppTheme.success),
                    const SizedBox(width: 6),
                    Text(
                      'Paid on ${_fmtDate(rent.paidDate!)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                    const Spacer(),
                    if (rent.paymentMethod != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rent.paymentMethod!.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],

          // ── Action buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: isOwner
                ? _buildOwnerActions(rent)
                : isActionable
                    ? _buildTenantPayButton()
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerActions(RentModel rent) {
    if (rent.status == 'paid' || rent.status == 'waived') {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showMarkPaidSheet(rent),
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Mark Paid'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.success,
              side: const BorderSide(color: AppTheme.success),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showWaiveDialog(rent),
            icon: const Icon(Icons.remove_circle_outline, size: 16),
            label: const Text('Waive'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textHint,
              side: const BorderSide(color: AppTheme.surfaceBorder),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTenantPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Contact your PG Manager to record payment.',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        icon: const Icon(Icons.payment_rounded, size: 18),
        label: const Text('Pay Now'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── Mark Paid bottom sheet ──────────────────────────────────────────────────
  void _showMarkPaidSheet(RentModel rent) {
    String selectedMethod = 'cash';
    final remarksCtrl = TextEditingController();
    final receiptCtrl = TextEditingController();
    final methods = ['cash', 'upi', 'bank_transfer', 'cheque', 'online', 'other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  padding: EdgeInsets.only(
                    top: 28,
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Record Payment',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${rent.userName ?? 'Tenant'} · ₹${rent.amount.toInt()} · ${_monthLabel(rent.month)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Payment method
                      Text('Payment Method', style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                      )),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: methods.map((m) {
                          final sel = selectedMethod == m;
                          return GestureDetector(
                            onTap: () => setSheetState(() => selectedMethod = m),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? AppTheme.primary : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: sel ? AppTheme.primary : AppTheme.surfaceBorder,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                m.toUpperCase().replaceAll('_', ' '),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: sel ? Colors.white : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Receipt No
                      TextField(
                        controller: receiptCtrl,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-#]'))],
                        decoration: InputDecoration(
                          labelText: 'Receipt No. (optional)',
                          prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                          filled: true,
                          fillColor: AppTheme.backgroundLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Remarks
                      TextField(
                        controller: remarksCtrl,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Remarks (optional)',
                          prefixIcon: const Icon(Icons.comment_outlined, size: 18),
                          filled: true,
                          fillColor: AppTheme.backgroundLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Confirm
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _confirmMarkPaid(
                            ctx, rent.id, selectedMethod,
                            remarksCtrl.text, receiptCtrl.text,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'Confirm Payment — ₹${rent.amount.toInt()}',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmMarkPaid(BuildContext ctx, String rentId, String method, String remarks, String receipt) async {
    Navigator.of(ctx).pop();
    try {
      final repo = ref.read(rentRepositoryProvider);
      await repo.updateRent(rentId, {
        'status': 'paid',
        'paymentMode': method,
      });
      ref.invalidate(pgRentsProvider);
      ref.invalidate(myRentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rent marked as paid!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            backgroundColor: AppTheme.success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _showWaiveDialog(RentModel rent) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Waive Rent?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: Text(
          'Are you sure you want to waive ₹${rent.amount.toInt()} for ${_monthLabel(rent.month)}?',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppTheme.textHint)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(rentRepositoryProvider);
                await repo.updateRent(rent.id, {'status': 'waived'});
                ref.invalidate(pgRentsProvider);
              } catch (_) {}
            },
            child: Text('Waive', style: GoogleFonts.plusJakartaSans(color: AppTheme.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Month picker ────────────────────────────────────────────────────────────
  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final months = List.generate(12, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppTheme.surfaceBorder, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Text('Select Month', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          ...months.map((m) => ListTile(
            title: Text(_monthLabel(m), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            trailing: m == _selectedMonth ? const Icon(Icons.check_rounded, color: AppTheme.primary) : null,
            onTap: () {
              setState(() => _selectedMonth = m);
              Navigator.pop(ctx);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  List<RentModel> _filterRents(List<RentModel> all) {
    return all.where((r) {
      final monthMatch = r.month == _selectedMonth;
      final statusMatch = _selectedStatus == null || r.status == _selectedStatus;
      return monthMatch && statusMatch;
    }).toList()
      ..sort((a, b) {
        if (a.status == 'overdue' && b.status != 'overdue') return -1;
        if (a.status != 'overdue' && b.status == 'overdue') return 1;
        if (a.status == 'pending' && b.status == 'paid') return -1;
        if (a.status == 'paid' && b.status == 'pending') return 1;
        return b.dueDate.compareTo(a.dueDate);
      });
  }

  Map<String, dynamic> _statusMeta(String status) {
    switch (status) {
      case 'paid':
        return {'color': AppTheme.success, 'label': 'Paid', 'icon': Icons.check_circle_outline};
      case 'overdue':
        return {'color': AppTheme.error, 'label': 'Overdue', 'icon': Icons.error_outline};
      case 'waived':
        return {'color': AppTheme.textHint, 'label': 'Waived', 'icon': Icons.cancel_outlined};
      default:
        return {'color': AppTheme.warning, 'label': 'Pending', 'icon': Icons.schedule};
    }
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 36, color: AppTheme.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'No Rent Records',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No rent records found for ${_monthLabel(_selectedMonth)}${_selectedStatus != null ? ' with status "${_selectedStatus!}"' : ''}.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: AppTheme.textSecondary, height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(
            'Could not load rent records',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textHint),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(myRentsProvider);
              ref.invalidate(pgRentsProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

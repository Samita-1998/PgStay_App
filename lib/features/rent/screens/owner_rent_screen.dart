import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/pg_listing/repositories/pg_listing_repository.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/rent/models/rent_model.dart';
import 'package:pgstay/features/rent/providers/rent_provider.dart';
import 'package:pgstay/features/rent/widgets/edit_payment_dialog.dart';
import 'package:pgstay/features/rent/widgets/rent_breakdown_dialog.dart';
import 'package:pgstay/features/rent/widgets/record_payment_dialog.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';

// ─── Date helpers ─────────────────────────────────────────────────────────────
String _fmtDate(DateTime d) {
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
  return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
}

String _monthLabel(String ym) {
  final parts = ym.split('-');
  if (parts.length != 2) return ym;
  const m = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final idx = int.tryParse(parts[1]) ?? 0;
  return '${(idx > 0 && idx < 13) ? m[idx] : parts[1]} ${parts[0]}';
}

String _currentYM() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

// ─── PG List Provider ─────────────────────────────────────────────────────────
final _ownerPgsProvider = FutureProvider.autoDispose((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final repo = PgListingRepository(apiClient);
  return repo.fetchOwnerPGs();
});

// ─── Owner Rent Screen ────────────────────────────────────────────────────────
class OwnerRentScreen extends ConsumerStatefulWidget {
  const OwnerRentScreen({super.key});

  @override
  ConsumerState<OwnerRentScreen> createState() => _OwnerRentScreenState();
}

class _OwnerRentScreenState extends ConsumerState<OwnerRentScreen> {
  String? _selectedPgId;
  String? _selectedPgName;
  String _selectedMonth = _currentYM();
  String? _statusFilter;
  bool _isGenerating = false;

  final _statusFilters = <String?, String>{
    null: 'All',
    'pending': 'Pending',
    'paid': 'Paid',
    'overdue': 'Overdue',
    'waived': 'Waived',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Rent Hub',
        showBackButton: true,
        showLeading: true,
        pinnedSCurve: true,
        isCompact: true,
        backgroundColor: AppTheme.backgroundLight,
      ),
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildPgSelector()),
            if (_selectedPgId != null) ...[
              SliverToBoxAdapter(child: _buildMonthFilterBar()),
              SliverToBoxAdapter(child: _buildGenerateButton()),
              _buildRentList(),
            ] else
              SliverToBoxAdapter(child: _buildSelectPgPrompt()),
          ],
        ),
      ),
    );
  }

  // ── PG Selector ─────────────────────────────────────────────────────────────
  Widget _buildPgSelector() {
    final pgsAsync = ref.watch(_ownerPgsProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        100 + MediaQuery.of(context).padding.top + 32,
        24,
        4,
      ),
      child: pgsAsync.when(
        data: (pgs) {
          if (pgs.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You have no PGs yet. Create one to start managing rent.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Auto-select the first PG if none selected
          if (_selectedPgId == null && pgs.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedPgId = pgs.first.id;
                  _selectedPgName = pgs.first.name;
                });
              }
            });
          }

          return GestureDetector(
            onTap: () => _showPgPicker(pgs),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.textSecondary.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.domain_rounded,
                      size: 24,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Managing Property',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textHint,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedPgName ?? 'Select a PG',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
              color: AppTheme.primary,
              strokeWidth: 2,
            ),
          ),
        ),
        error: (e, _) => Text('Error loading PGs: $e'),
      ),
    );
  }

  void _showPgPicker(List pgs) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.surfaceBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select PG',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: pgs
                    .map(
                      (pg) => ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.apartment_rounded,
                            size: 20,
                            color: AppTheme.primary,
                          ),
                        ),
                        title: Text(
                          pg.name ?? 'PG',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${pg.totalBeds ?? 0} beds · ${pg.occupiedBeds ?? 0} occupied',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textHint,
                          ),
                        ),
                        trailing: _selectedPgId == pg.id
                            ? const Icon(
                                Icons.check_circle,
                                color: AppTheme.primary,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedPgId = pg.id;
                            _selectedPgName = pg.name;
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── Month + Status Filters ──────────────────────────────────────────────────
  Widget _buildMonthFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          // Month row
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: AppTheme.textHint,
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _pickMonth,
                child: Row(
                  children: [
                    Text(
                      _monthLabel(_selectedMonth),
                      style: GoogleFonts.inter(
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
                  _statusFilter = null;
                }),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Reset'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  textStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Status chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.entries.map((e) {
                final isSelected = _statusFilter == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _statusFilter = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.surfaceBorder,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? AppTheme.primaryGlow(opacity: 0.12)
                            : [],
                      ),
                      child: Text(
                        e.value,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
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

  // ── Generate Button ─────────────────────────────────────────────────────────
  Widget _buildGenerateButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateRent,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 20),
                label: Text(_isGenerating ? 'Generating...' : 'Auto-Generate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecordPaymentScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Record'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateRent() async {
    if (_selectedPgId == null) return;
    setState(() => _isGenerating = true);

    try {
      final repo = ref.read(rentRepositoryProvider);
      // Due date = 5th of the selected month
      final parts = _selectedMonth.split('-');
      final dueDate = '${parts[0]}-${parts[1]}-05T00:00:00.000Z';
      final result = await repo.generateRent(
        _selectedPgId!,
        _selectedMonth,
        dueDate,
      );

      // Refresh the list
      ref.invalidate(pgRentsProvider);

      if (mounted) {
        final message = result['message'] ?? 'Rent generated successfully!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppTheme.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // ── Rent List ───────────────────────────────────────────────────────────────
  Widget _buildRentList() {
    final rentsAsync = ref.watch(pgRentsProvider(_selectedPgId ?? ''));

    return rentsAsync.when(
      data: (allRents) {
        final rents = _filterRents(allRents);
        if (rents.isEmpty) return SliverToBoxAdapter(child: _buildEmptyState());

        return SliverToBoxAdapter(
          child: Column(
            children: [
              _buildSummaryRow(rents),
              ...rents.map(
                (r) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                  child: _buildRentCard(r),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppTheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Could not load rent records',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textHint,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(pgRentsProvider),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Summary Row ─────────────────────────────────────────────────────────────
  Widget _buildSummaryRow(List<RentModel> rents) {
    final total = rents.fold(0.0, (s, r) => s + r.amount);
    final collected = rents
        .where((r) => r.status == 'paid')
        .fold(0.0, (s, r) => s + r.paidAmount);

    final paidCount = rents.where((r) => r.status == 'paid').length;
    final totalCount = rents.length;
    final pendingCount = rents.where((r) => r.status == 'pending').length;
    final overdueCount = rents.where((r) => r.status == 'overdue').length;

    final collectedPercent = total > 0 ? (collected / total) * 100 : 0.0;
    final collectionRate = totalCount > 0
        ? (paidCount / totalCount) * 100
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF191924),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2C2D43)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatItem(
                icon: Icons.currency_rupee_rounded,
                iconColor: const Color(0xFF34D399),
                iconBgColor: const Color(0xFF34D399).withValues(alpha: 0.15),
                title: 'COLLECTED',
                value: '₹${collected.toInt()}',
                valueColor: const Color(0xFF34D399),
                subtitle: '${collectedPercent.toInt()}% of ₹${total.toInt()}',
              ),
              _buildDivider(),
              _buildStatItem(
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF818CF8),
                iconBgColor: const Color(0xFF818CF8).withValues(alpha: 0.15),
                title: 'COLLECTION RATE',
                value: '$paidCount / $totalCount',
                valueColor: const Color(0xFF818CF8),
                subtitle: '${collectionRate.toInt()}% tenants paid',
              ),
              _buildDivider(),
              _buildStatItem(
                icon: Icons.access_time_rounded,
                iconColor: const Color(0xFFFBBF24),
                iconBgColor: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                title: 'PENDING',
                value: '$pendingCount',
                valueColor: const Color(0xFFFBBF24),
                subtitle: 'payments due',
              ),
              _buildDivider(),
              _buildStatItem(
                icon: Icons.error_outline_rounded,
                iconColor: const Color(0xFFF87171),
                iconBgColor: const Color(0xFFF87171).withValues(alpha: 0.15),
                title: 'OVERDUE',
                value: '$overdueCount',
                valueColor: const Color(0xFFF87171),
                subtitle: 'past due date',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
    required Color valueColor,
    required String subtitle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Single Rent Card ────────────────────────────────────────────────────────
  Widget _buildRentCard(RentModel rent) {
    final meta = _statusMeta(rent.status);
    final Color sColor = meta['color'] as Color;
    final String sLabel = meta['label'] as String;
    final IconData sIcon = meta['icon'] as IconData;
    final isActionable = rent.status == 'pending' || rent.status == 'overdue';
    final daysLeft = rent.dueDate.difference(DateTime.now()).inDays;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: rent.status == 'overdue'
              ? AppTheme.error.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textSecondary.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
            child: Row(
              children: [
                // Tenant avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.15),
                        AppTheme.primary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      (rent.userName ?? 'T').substring(0, 1).toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rent.userName ?? 'Tenant',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (rent.bedNumber != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Bed ${rent.bedNumber}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sIcon, size: 12, color: sColor),
                      const SizedBox(width: 6),
                      Text(
                        sLabel.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: sColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppTheme.textHint,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  elevation: 8,
                  onSelected: (val) {
                    if (val == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPaymentScreen(rent: rent),
                        ),
                      );
                    } else if (val == 'breakdown') {
                      showDialog(
                        context: context,
                        builder: (_) => RentBreakdownDialog(rent: rent),
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Edit Payment',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'breakdown',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              size: 16,
                              color: AppTheme.accentColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Rent Breakdown',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              color: AppTheme.surfaceBorder.withValues(alpha: 0.5),
              height: 1,
            ),
          ),

          // Amount & due
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textHint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${rent.amount.toInt()}',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Due Date',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textHint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fmtDate(rent.dueDate),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isActionable && daysLeft < 0
                            ? AppTheme.error
                            : AppTheme.textPrimary,
                      ),
                    ),
                    if (isActionable && daysLeft < 0)
                      Text(
                        '${daysLeft.abs()} days overdue',
                        style: GoogleFonts.inter(
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

          // Paid receipt
          if (rent.status == 'paid' && rent.paidDate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Paid ${_fmtDate(rent.paidDate!)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.success,
                      ),
                    ),
                    const Spacer(),
                    if (rent.paymentMethod != null)
                      Text(
                        rent.paymentMethod!.toUpperCase().replaceAll('_', ' '),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.success,
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Action buttons
          if (isActionable)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _showMarkPaidSheet(rent),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Mark Paid'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _waiveRent(rent),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textHint,
                        side: BorderSide(
                          color: AppTheme.surfaceBorder,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Waive'),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Mark Paid Sheet ─────────────────────────────────────────────────────────
  void _showMarkPaidSheet(RentModel rent) {
    String selectedMethod = 'cash';
    final methods = [
      'cash',
      'upi',
      'bank_transfer',
      'cheque',
      'online',
      'other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  padding: EdgeInsets.only(
                    top: 24,
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Record Payment',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${rent.userName ?? 'Tenant'} · ₹${rent.amount.toInt()} · ${_monthLabel(rent.month)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Payment Method',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: methods.map((m) {
                          final sel = selectedMethod == m;
                          return GestureDetector(
                            onTap: () =>
                                setSheetState(() => selectedMethod = m),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: sel ? AppTheme.primary : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: sel
                                      ? AppTheme.primary
                                      : AppTheme.surfaceBorder,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                m.toUpperCase().replaceAll('_', ' '),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: sel
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await _markPaid(rent.id, selectedMethod);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Confirm Payment — ₹${rent.amount.toInt()}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
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

  Future<void> _markPaid(String rentId, String method) async {
    try {
      final repo = ref.read(rentRepositoryProvider);
      await repo.updateRent(rentId, {'status': 'paid', 'paymentMode': method});
      ref.invalidate(pgRentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rent marked as paid!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

  void _waiveRent(RentModel rent) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Waive Rent?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to waive ₹${rent.amount.toInt()} for ${rent.userName ?? 'this tenant'}?',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textHint),
            ),
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
            child: Text(
              'Waive',
              style: GoogleFonts.inter(
                color: AppTheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Month Picker ────────────────────────────────────────────────────────────
  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final months = List.generate(12, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.surfaceBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select Month',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: months
                    .map(
                      (m) => ListTile(
                        title: Text(
                          _monthLabel(m),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        trailing: m == _selectedMonth
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppTheme.primary,
                              )
                            : null,
                        onTap: () {
                          setState(() => _selectedMonth = m);
                          Navigator.pop(ctx);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  List<RentModel> _filterRents(List<RentModel> all) {
    return all.where((r) {
      final monthMatch = r.month == _selectedMonth;
      final statusMatch = _statusFilter == null || r.status == _statusFilter;
      return monthMatch && statusMatch;
    }).toList()..sort((a, b) {
      if (a.status == 'overdue' && b.status != 'overdue') return -1;
      if (a.status != 'overdue' && b.status == 'overdue') return 1;
      if (a.status == 'pending' && b.status == 'paid') return -1;
      if (a.status == 'paid' && b.status == 'pending') return 1;
      return (a.userName ?? '').compareTo(b.userName ?? '');
    });
  }

  Map<String, dynamic> _statusMeta(String status) {
    switch (status) {
      case 'paid':
        return {
          'color': AppTheme.success,
          'label': 'Paid',
          'icon': Icons.check_circle_outline,
        };
      case 'overdue':
        return {
          'color': AppTheme.error,
          'label': 'Overdue',
          'icon': Icons.error_outline,
        };
      case 'waived':
        return {
          'color': AppTheme.textHint,
          'label': 'Waived',
          'icon': Icons.cancel_outlined,
        };
      default:
        return {
          'color': AppTheme.warning,
          'label': 'Pending',
          'icon': Icons.schedule,
        };
    }
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Rent Records',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Auto-Generate Rent" to create rent records for all tenants in ${_monthLabel(_selectedMonth)}.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectPgPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              size: 36,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Select a PG',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a PG from the dropdown above to view and manage rent records.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

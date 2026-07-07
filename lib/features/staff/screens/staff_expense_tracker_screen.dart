import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/staff/models/employee_model.dart';
import 'package:pgstay/features/staff/providers/staff_provider.dart';
import 'package:pgstay/features/staff/widgets/edit_staff_bottom_sheet.dart';
import 'package:pgstay/features/staff/widgets/add_staff_bottom_sheet.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/auth/models/user_model.dart';
import 'package:pgstay/features/staff/providers/expense_provider.dart';
import 'package:pgstay/features/staff/models/expense_model.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:pgstay/features/staff/widgets/log_expense_dialog.dart';
import 'package:pgstay/features/staff/widgets/review_expense_dialog.dart';
import 'package:pgstay/features/staff/widgets/generate_payroll_dialog.dart';
import 'package:pgstay/features/staff/models/payment_model.dart';
import 'package:pgstay/features/staff/widgets/edit_salary_payout_dialog.dart';
import 'package:pgstay/features/staff/widgets/pay_salary_payout_dialog.dart';

class StaffExpenseTrackerScreen extends ConsumerStatefulWidget {
  const StaffExpenseTrackerScreen({super.key});

  @override
  ConsumerState<StaffExpenseTrackerScreen> createState() =>
      _StaffExpenseTrackerScreenState();
}

class _StaffExpenseTrackerScreenState
    extends ConsumerState<StaffExpenseTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Rebuild to update header button based on tab
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Staff & Expense Tracker',
        subtitle: 'Manage staff, track expense claims, and handle salary payouts',
        pinnedSCurve: true,
        actionWidget: _buildHeaderAction(),
      ),
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Padding(
          padding: EdgeInsets.only(top: 110 + MediaQuery.of(context).padding.top + 32),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(child: _buildFilterBar()),
                SliverToBoxAdapter(child: _buildSummaryCards()),
                SliverToBoxAdapter(child: _buildTabBar()),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildStaffListTab(),
                _buildExpenseClaimsTab(),
                _buildSalaryPayoutsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAction() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return Consumer(
            builder: (context, ref, child) {
              final userAsync = ref.watch(authProvider);
              final currentUser = userAsync.valueOrNull;
              if (currentUser?.role != 'manager' &&
                  currentUser?.role != 'owner') {
                return const SizedBox.shrink();
              }

              if (_tabController.index == 1) {
                // Expense Claims Tab
                return ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const LogExpenseDialog(),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Log Expense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              } else if (_tabController.index == 2) {
                // Salary Payouts Tab
                return ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const GeneratePayrollDialog(),
                    ).then((result) {
                      if (result == true) {
                        ref.invalidate(paymentsProvider);
                      }
                    });
                  },
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('Generate Payroll'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              // Default Staff List Tab
              return ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddStaffBottomSheet(),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Add Staff'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          );
      },
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'All PGs',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final employeesAsync = ref.watch(employeesProvider);
    final activeStaffCount =
        employeesAsync.valueOrNull?.where((e) => e.status == 'active').length ??
        0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final crossAxisCount = isWide ? 4 : 2;
          final cardWidth =
              (constraints.maxWidth - (16 * (crossAxisCount - 1))) /
              crossAxisCount;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: cardWidth,
                child: _buildSummaryCard(
                  title: 'ACTIVE STAFF',
                  value: activeStaffCount.toString(),
                  subtitle: 'members',
                  icon: Icons.people_outline_rounded,
                  color: AppTheme.primary,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: _buildSummaryCard(
                  title: 'PENDING CLAIMS',
                  value: '0',
                  subtitle: 'awaiting approval',
                  icon: Icons.access_time_rounded,
                  color: AppTheme.warning,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: _buildSummaryCard(
                  title: 'APPROVED',
                  value: '₹0',
                  subtitle: 'to reimburse',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppTheme.success,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: _buildSummaryCard(
                  title: 'PAYROLL DUE',
                  value: '0',
                  subtitle: '₹0 total',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppTheme.error,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: AppTheme.surfaceShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textHint,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textHint,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.people_alt_outlined, size: 18),
              text: 'Staff List',
            ),
            Tab(
              icon: Icon(Icons.receipt_long_outlined, size: 18),
              text: 'Expense Claims',
            ),
            Tab(
              icon: Icon(Icons.account_balance_wallet_outlined, size: 18),
              text: 'Salary Payouts',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffListTab() {
    final employeesAsync = ref.watch(employeesProvider);
    final userAsync = ref.watch(authProvider);
    final currentUser = userAsync.valueOrNull;

    return employeesAsync.when(
      data: (employees) {
        if (employees.isEmpty) {
          return const Center(child: Text("No staff found"));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final emp = employees[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildStaffCard(emp, currentUser),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (err, stack) => Center(child: Text("Error: $err")),
    );
  }

  Widget _buildStaffCard(EmployeeModel emp, User? currentUser) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: AppTheme.surfaceShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage:
                      (emp.user.picture != null && emp.user.picture!.isNotEmpty)
                      ? NetworkImage(emp.user.picture!)
                      : null,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: (emp.user.picture == null || emp.user.picture!.isEmpty)
                      ? Text(
                          emp.user.name[0].toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              emp.user.name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: emp.status == 'active'
                                  ? AppTheme.success.withValues(alpha: 0.1)
                                  : AppTheme.textHint.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: emp.status == 'active'
                                    ? AppTheme.success.withValues(alpha: 0.2)
                                    : AppTheme.surfaceBorder,
                              ),
                            ),
                            child: Text(
                              emp.status == 'active' ? 'Active' : 'Inactive',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: emp.status == 'active'
                                    ? AppTheme.success
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          emp.user.role.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (emp.user.mobNo1 != null &&
                          emp.user.mobNo1!.isNotEmpty)
                        Text(
                          emp.user.mobNo1!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textHint,
                          ),
                        ),
                      if (emp.user.email.isNotEmpty)
                        Text(
                          emp.user.email,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textHint,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Salary and Joined info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MONTHLY SALARY',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textHint,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${emp.monthlySalary.toInt()}',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'JOINED',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textHint,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          emp.joinedDate != null
                              ? DateFormat(
                                  'dd MMM yyyy',
                                ).format(emp.joinedDate!)
                              : 'N/A',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Assigned PGs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASSIGNED PGS & SALARIES (${emp.assignedPgs.length})',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textHint,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                ...emp.assignedPgs.map((pg) {
                  final salary = emp.pgSalaries[pg.id] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            pg.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '₹${salary is double ? salary.toInt() : salary}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          if (currentUser?.role == 'manager' ||
              currentUser?.role == 'owner') ...[
            Divider(color: AppTheme.surfaceBorder, height: 1),

            // Actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) =>
                              EditStaffBottomSheet(employee: emp),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        textStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: AppTheme.surfaceBorder,
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppTheme.surfaceWhite,
                            title: Text(
                              'Remove Staff',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to remove ${emp.user.name}?',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'Remove',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          try {
                            // Show loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primary,
                                ),
                              ),
                            );

                            await ref
                                .read(staffRepositoryProvider)
                                .removeEmployee(emp.id);

                            if (context.mounted) {
                              Navigator.pop(context); // close loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Staff member removed successfully',
                                  ),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                              ref.invalidate(employeesProvider);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context); // close loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: AppTheme.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        textStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_rounded, size: 48, color: AppTheme.textHint),
          const SizedBox(height: 16),
          Text(
            '$title module\ncoming soon',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseClaimsTab() {
    final expensesAsync = ref.watch(expensesProvider);

    return expensesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (e, st) => Center(
        child: Text(
          'Error loading expenses: $e',
          style: const TextStyle(color: AppTheme.error),
        ),
      ),
      data: (expenses) {
        if (expenses.isEmpty) {
          return Center(
            child: Text(
              'No expense claims found.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(expensesProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: expenses.length,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final exp = expenses[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildExpenseCard(exp),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildExpenseCard(ExpenseModel exp) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: AppTheme.surfaceShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    exp.spentBy.name.isNotEmpty
                        ? exp.spentBy.name[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              exp.spentBy.name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusBadge(exp.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _capitalize(exp.spentBy.role),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Expense Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      exp.category,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(exp.spentDate),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Amount and Reimbursement
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AMOUNT',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textHint,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${exp.amount.toInt()}',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REIMBURSEMENT',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textHint,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildReimbursementBadge(exp.reimbursementType),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          if (exp.status == 'pending') ...[
            Divider(color: AppTheme.surfaceBorder, height: 1),

            // Actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ReviewExpenseDialog(expense: exp),
                        );
                      },
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                      ),
                      label: const Text('Review'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.success,
                        textStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: AppTheme.surfaceBorder,
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppTheme.surfaceWhite,
                            title: Text('Delete Expense', style: GoogleFonts.inter(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                            content: Text('Are you sure you want to delete this expense claim?', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textHint)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Delete', style: GoogleFonts.inter(color: AppTheme.error, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          try {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                            );

                            await ref.read(expenseRepositoryProvider).deleteExpense(exp.id);

                            if (context.mounted) {
                              Navigator.pop(context); // close loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Expense claim deleted successfully', style: TextStyle(color: Colors.white)),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                              ref.invalidate(expensesProvider);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context); // close loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        textStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (exp.status == 'approved' && exp.reimbursementType == 'direct' && exp.payoutStatus == 'unpaid') ...[
            Divider(color: AppTheme.surfaceBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                        );

                        await ref.read(expenseRepositoryProvider).payExpense(exp.id);

                        if (context.mounted) {
                          Navigator.pop(context); // close loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment marked successfully', style: TextStyle(color: Colors.white)),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                          ref.invalidate(expensesProvider);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context); // close loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text(
                      'Pay',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSalaryPayoutsTab() {
    final paymentsAsync = ref.watch(paymentsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(paymentsProvider);
      },
      color: AppTheme.primary,
      child: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textHint),
                  const SizedBox(height: 16),
                  Text(
                    'No Payroll Records',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate a payroll record to see it here.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group by employeeId
          final groupedPayments = <String, List<PaymentModel>>{};
          for (final p in payments) {
            groupedPayments.putIfAbsent(p.employeeId, () => []).add(p);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: groupedPayments.length,
            itemBuilder: (context, index) {
              final employeeId = groupedPayments.keys.elementAt(index);
              final employeePayments = groupedPayments[employeeId]!;
              return _buildPaymentCard(employeePayments);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (error, _) => Center(child: Text(error.toString(), style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }

  Widget _buildPaymentCard(List<PaymentModel> payments) {
    if (payments.isEmpty) return const SizedBox.shrink();

    final user = payments.first.user;
    final bool anyPending = payments.any((p) => p.status == 'pending');
    
    double totalSalary = 0;
    double totalExpenses = 0;
    double totalAmount = 0;
    for (var p in payments) {
      totalSalary += p.salaryAmount;
      totalExpenses += p.reimbursedExpenses;
      totalAmount += p.totalAmount;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.backgroundLight,
                  backgroundImage: user.picture != null ? NetworkImage(user.picture!) : null,
                  child: user.picture == null
                      ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: GoogleFonts.inter(color: AppTheme.primary, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_capitalize(user.role)} - ${payments.length} PGs Assigned',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(anyPending ? 'Pending Payout' : 'All Paid'),
              ],
            ),
          ),
          
          // PG Breakdown
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PG BREAKDOWN',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textHint, letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
                ...payments.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.pgName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                            const SizedBox(height: 2),
                            Text('Salary: ₹${p.salaryAmount.toInt()} - Expenses: ₹${p.reimbursedExpenses.toInt()}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      _buildStatusBadge(p.status),
                      const SizedBox(width: 8),
                      if (p.status == 'pending') ...[
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => PaySalaryPayoutDialog(payment: p),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.success,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Pay', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => EditSalaryPayoutDialog(payment: p),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: Text('Edit', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ] else ...[
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          color: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          constraints: const BoxConstraints(),
                          splashRadius: 16,
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.file_download_outlined, size: 16),
                          color: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          constraints: const BoxConstraints(),
                          splashRadius: 16,
                        ),
                      ],
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Totals
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, anyPending ? 16 : 0),
            child: Row(
              children: [
                Expanded(child: _buildTotalBox('Salary', totalSalary, AppTheme.primary)),
                const SizedBox(width: 12),
                Expanded(child: _buildTotalBox('Expenses', totalExpenses, AppTheme.success)),
                const SizedBox(width: 12),
                Expanded(child: _buildTotalBox('Total', totalAmount, AppTheme.primary)),
              ],
            ),
          ),
          
          if (!anyPending) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View Combined Pay Slip'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: BorderSide(color: AppTheme.surfaceBorder, style: BorderStyle.solid), // Dashed borders need custom painters, solid used here for simplicity
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.file_download_outlined, size: 16),
                      label: const Text('Download Combined Pay Slip'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: BorderSide(color: AppTheme.surfaceBorder, style: BorderStyle.solid),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalBox(String label, double amount, Color amountColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: label == 'Total' ? Border.all(color: AppTheme.primary.withOpacity(0.3)) : null,
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text('₹${amount.toInt()}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: amountColor)),
        ],
      ),
    );
  }
}

Widget _buildStatusBadge(String status) {
  Color bgColor;
  Color textColor;

  switch (status.toLowerCase()) {
    case 'approved':
    case 'paid':
    case 'all paid':
      bgColor = AppTheme.success.withValues(alpha: 0.15);
      textColor = AppTheme.success;
      break;
    case 'rejected':
      bgColor = AppTheme.error.withValues(alpha: 0.15);
      textColor = AppTheme.error;
      break;
    case 'pending payout':
      bgColor = AppTheme.warning.withValues(alpha: 0.15);
      textColor = const Color(0xFFF57C00); // Darker orange
      break;
    case 'pending':
    default:
      bgColor = AppTheme.warning.withValues(alpha: 0.15);
      textColor = const Color(0xFFF57C00); // Darker orange
      break;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: textColor.withValues(alpha: 0.3)),
    ),
    child: Text(
      _capitalize(status),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    ),
  );
}

Widget _buildReimbursementBadge(String? type) {
  if (type == null || type.isEmpty) {
    return Text('—', style: GoogleFonts.inter(color: AppTheme.textHint));
  }

  Color bgColor;
  Color textColor;
  String label;

  if (type == 'add_to_salary') {
    bgColor = AppTheme.primary.withValues(alpha: 0.15);
    textColor = AppTheme.primary;
    label = 'Add To Salary';
  } else if (type == 'direct') {
    bgColor = AppTheme.success.withValues(alpha: 0.15);
    textColor = AppTheme.success;
    label = 'Direct Pay';
  } else {
    bgColor = AppTheme.textHint.withValues(alpha: 0.15);
    textColor = AppTheme.textSecondary;
    label = _capitalize(type);
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: textColor.withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    ),
  );
}

String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

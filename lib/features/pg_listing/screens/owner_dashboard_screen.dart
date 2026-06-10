import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/enquiries/providers/enquiries_provider.dart';
import 'package:pgstay/features/enquiries/models/enquiry_model.dart';
import 'package:pgstay/features/pg_listing/screens/add_pg_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  int _selectedPeriod = 0;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // Use the extension properties directly from context
    final ownerPgsAsync = ref.watch(ownerPgsProvider);
    final user = ref.watch(authProvider).valueOrNull;
    final enquiriesCountAsync = ref.watch(ownerEnquiriesCountProvider);
    final newEnquiriesCount = enquiriesCountAsync.valueOrNull ?? 0;
    final enquiriesListAsync = ref.watch(enquiriesListProvider);
    final recentEnquiries = (enquiriesListAsync.valueOrNull ?? [])
        .take(4)
        .toList();
    final postsAsync = ref.watch(pgListProvider);
    final vacancyPosts = (postsAsync.valueOrNull ?? []).take(6).toList();
    final totalPostsCount = postsAsync.valueOrNull?.length ?? 0;

    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.backgroundLight,
      drawer: _buildOwnerDrawer(context, user),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(ownerPgsProvider);
          ref.refresh(ownerEnquiriesCountProvider);
          ref.refresh(pgListProvider);
        },
        color: context.primaryColor,
        child: ownerPgsAsync.when(
          data: (pgs) {
            final totalPgsCount = pgs.length;
            final activePostsCount = pgs.where((pg) => pg.isActive).length;
            final occupiedBedsCount = pgs.fold<int>(
              0,
              (sum, pg) => sum + pg.occupiedBeds,
            );
            final emptyBedsCount = pgs.fold<int>(
              0,
              (sum, pg) => sum + pg.emptyBeds,
            );

            return CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Hero Header Sliver - Single Color
                SliverToBoxAdapter(
                  child: Container(
                    color: context.primaryColor,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        MediaQuery.of(context).padding.top + 16,
                        24,
                        40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'OWNER DASHBOARD',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Welcome back,',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.85),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${user?.name?.split(' ')[0] ?? 'Owner'}',
                                    style: GoogleFonts.inter(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.1,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () {
                                  _scaffoldKey.currentState?.openDrawer();
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.menu_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF34D399),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'All systems operational • ${DateTime.now().day} active users',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
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

                // Stats Grid
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                        ),
                    delegate: SliverChildListDelegate([
                      _buildFreshStatCard(
                        title: "Total Properties",
                        value: totalPgsCount.toString(),
                        icon: Icons.apartment_rounded,
                        color: context.primaryColor,
                        trend: "+2 this month",
                      ),
                      _buildFreshStatCard(
                        title: "Active Listings",
                        value: activePostsCount.toString(),
                        icon: Icons.check_circle_rounded,
                        color: context.successColor,
                        trend: "All active",
                      ),
                      _buildFreshStatCard(
                        title: "Occupied Beds",
                        value: occupiedBedsCount.toString(),
                        icon: Icons.bed_rounded,
                        color: context.accentColor,
                        trend:
                            "${((occupiedBedsCount / (occupiedBedsCount + emptyBedsCount)) * 100).toInt()}% full",
                      ),
                      _buildFreshStatCard(
                        title: "Available Beds",
                        value: emptyBedsCount.toString(),
                        icon: Icons.hotel_rounded,
                        color: context.warningColor,
                        trend: "${emptyBedsCount} vacancies",
                      ),
                    ]),
                  ),
                ),

                // Enquiries Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: _buildFreshEnquiryCard(newEnquiriesCount),
                  ),
                ),

                // Performance Chart - Responsive
                SliverToBoxAdapter(
                  child: StaggeredFadeIn(
                    delay: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: _buildResponsiveChart(screenWidth),
                    ),
                  ),
                ),

                // Recent Enquiries Section
                SliverToBoxAdapter(
                  child: StaggeredFadeIn(
                    delay: const Duration(milliseconds: 280),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: _buildFreshEnquiriesSection(
                        recentEnquiries,
                        newEnquiriesCount,
                      ),
                    ),
                  ),
                ),

                // PG Overview Section
                SliverToBoxAdapter(
                  child: StaggeredFadeIn(
                    delay: const Duration(milliseconds: 320),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: _buildFreshPgOverview(pgs),
                    ),
                  ),
                ),

                // Vacancy Posts Section
                SliverToBoxAdapter(
                  child: StaggeredFadeIn(
                    delay: const Duration(milliseconds: 360),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                      child: _buildFreshVacancySection(
                        vacancyPosts,
                        totalPostsCount,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.errorColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: context.errorColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Failed to Load Data',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    style: GoogleFonts.inter(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      ref.refresh(ownerPgsProvider);
                      ref.refresh(ownerEnquiriesCountProvider);
                      ref.refresh(pgListProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      'Try Again',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerDrawer(BuildContext context, dynamic user) {
    return Drawer(
      backgroundColor: context.surfaceWhite,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: context.primaryColor),
            accountName: Text(
              user?.name ?? 'Owner',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            accountEmail: Text(
              user?.email ?? 'owner@example.com',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.apartment_rounded,
                color: context.primaryColor,
                size: 36,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard_rounded, color: context.textPrimary),
            title: Text(
              'Dashboard',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.inbox_rounded, color: context.textPrimary),
            title: Text(
              'Enquiries',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'New',
                style: GoogleFonts.inter(
                  color: context.primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.push('/owner-enquiries');
            },
          ),
          ListTile(
            leading: Icon(Icons.receipt_long_rounded, color: context.textPrimary),
            title: Text(
              'Rent Management',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Track & collect rent',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: context.textHint,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.push('/owner-rent');
            },
          ),
          ListTile(
            leading: Icon(Icons.report_problem_outlined, color: context.textPrimary),
            title: Text(
              'Complaints',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context);
              context.push('/complaints');
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications_outlined, color: context.textPrimary),
            title: Text(
              'Notifications',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context);
              context.push('/notifications');
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.settings_rounded, color: context.textPrimary),
            title: Text(
              'Settings',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveChart(double screenWidth) {
    // Calculate chart height based on screen width
    final chartHeight = screenWidth > 600 ? 280.0 : 220.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ENQUIRY TRENDS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Weekly Performance',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: context.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: context.successColor,
                    ),
                    Text(
                      '+23% vs last week',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: chartHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: context.textHint.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ];
                            if (value.toInt() >= 0 &&
                                value.toInt() < days.length) {
                              // Responsive text size
                              final fontSize = constraints.maxWidth > 400
                                  ? 11
                                  : 9;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  days[value.toInt()],
                                  style: GoogleFonts.inter(
                                    fontSize: fontSize.toDouble(),
                                    color: context.textHint,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 35,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final fontSize = constraints.maxWidth > 400
                                ? 10
                                : 8;
                            return Text(
                              value.toInt().toString(),
                              style: GoogleFonts.inter(
                                fontSize: fontSize.toDouble(),
                                color: context.textHint,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                          reservedSize: 35,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 12),
                          FlSpot(1, 18),
                          FlSpot(2, 15),
                          FlSpot(3, 22),
                          FlSpot(4, 28),
                          FlSpot(5, 25),
                          FlSpot(6, 32),
                        ],
                        isCurved: true,
                        color: context.primaryColor,
                        barWidth: 3,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: context.primaryColor.withOpacity(0.08),
                        ),
                      ),
                    ],
                    // Add extra padding to prevent overflow
                    clipData: FlClipData.all(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreshStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreshEnquiryCard(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.primaryColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.mail_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Enquiries',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      count.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Requires action',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: context.errorColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: context.textHint,
          ),
        ],
      ),
    );
  }

  Widget _buildFreshEnquiriesSection(List<EnquiryModel> enquiries, int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: context.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Enquiries',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: context.primaryColor,
                ),
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (enquiries.isEmpty)
            _buildEmptyState(
              icon: Icons.inbox_rounded,
              message: 'No enquiries yet',
            )
          else
            ...enquiries.map((enquiry) => _buildFreshEnquiryItem(enquiry)),
        ],
      ),
    );
  }

  Widget _buildFreshEnquiryItem(EnquiryModel enquiry) {
    final statusColors = {
      'interested': context.accentColor,
      'visited': context.warningColor,
      'confirmed': context.successColor,
      'dealdone': context.primaryColor,
      'cancelled': context.errorColor,
    };
    final statusLabels = {
      'interested': 'Interested',
      'visited': 'Visited',
      'confirmed': 'Confirmed',
      'dealdone': 'Deal Done',
      'cancelled': 'Cancelled',
    };
    final statusKey = enquiry.status.toLowerCase().replaceAll(' ', '');
    final statusColor = statusColors[statusKey] ?? context.textHint;
    final statusLabel = statusLabels[statusKey] ?? enquiry.status;

    String timeAgo = '';
    try {
      final dt = DateTime.parse(enquiry.createdAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours}h ago';
      } else {
        timeAgo = '${diff.inDays}d ago';
      }
    } catch (_) {
      timeAgo = enquiry.createdAt;
    }

    final pgName = enquiry.pg?.name ?? 'Unknown PG';
    final postTitle = enquiry.post?.title ?? '';
    final userName = enquiry.user?.name ?? '';
    final userPic = enquiry.user?.picture ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.textHint.withOpacity(0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: statusColor, width: 2),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: statusColor.withOpacity(0.1),
                backgroundImage: userPic.isNotEmpty
                    ? NetworkImage(userPic)
                    : null,
                child: userPic.isEmpty
                    ? Icon(
                        Icons.person_outline_rounded,
                        size: 22,
                        color: statusColor,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (userName.isNotEmpty)
                    Text(
                      userName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    pgName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (postTitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      postTitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: context.textHint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: context.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: context.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusLabel,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreshPgOverview(List<PgModel> pgs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROPERTY PORTFOLIO',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your Properties',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: context.primaryColor,
                ),
                child: Text(
                  'Manage All',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (pgs.isEmpty)
            _buildEmptyState(
              icon: Icons.business_rounded,
              message: 'No properties found',
            )
          else
            ...pgs.map((pg) => _buildFreshPgCard(pg)).toList(),
        ],
      ),
    );
  }

  Widget _buildFreshPgCard(PgModel pg) {
    Color typeColor = context.primaryColor;
    String lowerType = pg.pgType.toLowerCase();
    if (lowerType.contains('female') || lowerType.contains('girls')) {
      typeColor = const Color(0xFFEC4899);
    } else if (lowerType.contains('male') || lowerType.contains('boys')) {
      typeColor = const Color(0xFF3B82F6);
    } else if (lowerType.contains('unisex')) {
      typeColor = const Color(0xFF14B8A6);
    } else if (lowerType.contains('co-living') ||
        lowerType.contains('coliving')) {
      typeColor = const Color(0xFFF97316);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.backgroundLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.textHint.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pg.name,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: context.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          [
                            pg.address.city,
                            pg.address.state,
                          ].where((e) => e.isNotEmpty).join(', '),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: context.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pg.pgType.isNotEmpty ? pg.pgType : 'N/A',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFreshMiniStat(
                'Rooms',
                pg.totalRooms.toString(),
                Icons.door_front_door_rounded,
              ),
              _buildFreshMiniStat(
                'Vacant Beds',
                pg.emptyBeds.toString(),
                Icons.hotel_rounded,
                valueColor: pg.emptyBeds > 0
                    ? context.successColor
                    : context.errorColor,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: context.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFBBF24),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      pg.rating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFreshMiniStat(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: context.textHint),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: context.textHint,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: valueColor ?? context.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFreshVacancySection(List<PgPost> posts, int totalCount) {
    String formatPrice(double price) {
      if (price % 1 == 0) {
        return '₹${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
      }
      return '₹${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTIVE LISTINGS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Vacancy Posts',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalCount total posts • ${DateTime.now().month}/${DateTime.now().year}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.textHint,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: context.primaryColor,
                ),
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (posts.isEmpty)
            _buildEmptyState(
              icon: Icons.post_add_rounded,
              message: 'No active listings',
            )
          else
            ...posts.map((post) {
              final priceRange =
                  (post.minPrice != null && post.maxPrice != null)
                  ? '${formatPrice(post.minPrice!)} - ${formatPrice(post.maxPrice!)}'
                  : formatPrice(post.minPrice ?? 0);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.textHint.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.primaryColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title.isNotEmpty ? post.title : 'New Listing',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${post.pg.name} • ${post.vacancyCount} beds available',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: context.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          priceRange,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: context.successColor,
                          ),
                        ),
                        Text(
                          '/month',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: context.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: context.textHint),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

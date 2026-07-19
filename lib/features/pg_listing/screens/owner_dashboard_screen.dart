import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/enquiries/providers/enquiries_provider.dart';
import 'package:pgstay/features/enquiries/models/enquiry_model.dart';
import 'package:pgstay/features/pg_listing/screens/add_pg_screen.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:pgstay/core/providers/theme_provider.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<QuickAction> _quickActions = [
    QuickAction(
      icon: Icons.add_business_rounded,
      label: 'Add PG',
      route: '/add-pg',
      color: const Color(0xFF6366F1),
    ),
    QuickAction(
      icon: Icons.mail_outline_rounded,
      label: 'Enquiries',
      route: '/owner-enquiries',
      color: const Color(0xFFF59E0B),
    ),
    QuickAction(
      icon: Icons.receipt_long_rounded,
      label: 'Rent',
      route: '/owner-rent',
      color: const Color(0xFF10B981),
    ),
    QuickAction(
      icon: Icons.people_outline_rounded,
      label: 'Staff',
      route: '/staff-tracker',
      color: const Color(0xFF8B5CF6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ownerPgsAsync = ref.watch(ownerPgsProvider);
    final user = ref.watch(authProvider).valueOrNull;
    final enquiriesCountAsync = ref.watch(ownerEnquiriesCountProvider);
    final newEnquiriesCount = enquiriesCountAsync.valueOrNull ?? 0;
    final enquiriesListAsync = ref.watch(enquiriesListProvider);
    final recentEnquiries = (enquiriesListAsync.valueOrNull ?? [])
        .take(3)
        .toList();
    final postsAsync = ref.watch(pgListProvider);
    final vacancyPosts = (postsAsync.valueOrNull ?? []).take(4).toList();
    final totalPostsCount = postsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: user?.name.split(' ')[0] ?? 'Owner',
        subtitle: 'Welcome back 👋',
        showBackButton: false,
        pinnedSCurve: true,
        backgroundColor: context.theme.scaffoldBackgroundColor,
        onLeadingPressed: () => _scaffoldKey.currentState?.openDrawer(),
        actionWidget: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 20,
              ),
              Positioned(
                right: 1,
                top: 1,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: context.errorColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: _buildOwnerDrawer(context, user),
      body: Builder(
        builder: (context) {
          final pgs = ownerPgsAsync.valueOrNull ?? [];
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

          return MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0.9 * MediaQuery.of(context).padding.top,
                      16,
                      0,
                    ),
                    child: Column(
                      children: [
                        // Property Overview Card - Compact
                        StaggeredFadeIn(
                          delay: const Duration(milliseconds: 100),
                          child: _buildPremiumOverviewCard(
                            totalPgsCount: totalPgsCount,
                            activePostsCount: activePostsCount,
                            occupiedBedsCount: occupiedBedsCount,
                            emptyBedsCount: emptyBedsCount,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Quick Actions - Compact Grid
                        StaggeredFadeIn(
                          delay: const Duration(milliseconds: 150),
                          child: _buildCompactQuickActions(),
                        ),

                        const SizedBox(height: 16),

                        // Recent Enquiries
                        StaggeredFadeIn(
                          delay: const Duration(milliseconds: 200),
                          child: _buildModernEnquiriesSection(
                            recentEnquiries,
                            newEnquiriesCount,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Property Portfolio
                        StaggeredFadeIn(
                          delay: const Duration(milliseconds: 250),
                          child: _buildModernPropertyPortfolio(pgs),
                        ),

                        const SizedBox(height: 16),

                        // Vacancy Listings
                        StaggeredFadeIn(
                          delay: const Duration(milliseconds: 300),
                          child: _buildModernVacancySection(
                            vacancyPosts,
                            totalPostsCount,
                          ),
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Compact Overview Card
  Widget _buildPremiumOverviewCard({
    required int totalPgsCount,
    required int activePostsCount,
    required int occupiedBedsCount,
    required int emptyBedsCount,
  }) {
    final totalBeds = occupiedBedsCount + emptyBedsCount;
    final occupancyRate = totalBeds > 0
        ? ((occupiedBedsCount / totalBeds) * 100).toInt()
        : 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFF8FAFF)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(3, 4, 94, 1.0).withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 8,
      ), // Reduced from 20,12 to 16,8
      child: Column(
        children: [
          // Header with gradient bar
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color.fromRGBO(3, 4, 94, 1.0), Color(0xFF303B87)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10), // Reduced from 12 to 10
              Text(
                'Property Overview',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, // Reduced from 12 to 10
                  vertical: 5, // Reduced from 6 to 5
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF059669).withOpacity(0.1),
                      const Color(0xFF059669).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF059669),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4), // Reduced from 6 to 4
                    Text(
                      'Active',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18), // Reduced from 24 to 18
          // Occupancy Rate - Premium Design
          Container(
            padding: const EdgeInsets.all(14), // Reduced from 20 to 14
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(3, 4, 94, 1.0).withOpacity(0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border(
                left: BorderSide(
                  color: Color.fromRGBO(3, 4, 94, 1.0),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64, // Reduced from 72 to 64
                      height: 64, // Reduced from 72 to 64
                      child: CircularProgressIndicator(
                        value: (occupiedBedsCount + emptyBedsCount) > 0
                            ? occupiedBedsCount /
                                  (occupiedBedsCount + emptyBedsCount)
                            : 0,
                        strokeWidth: 6, // Reduced from 7 to 6
                        backgroundColor: const Color(0xFFE8E5F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color.fromRGBO(3, 4, 94, 1.0),
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedFlipCounter(
                          value: occupancyRate,
                          duration: const Duration(milliseconds: 500),
                          suffix: '%',
                          textStyle: GoogleFonts.inter(
                            fontSize: 14, // Reduced from 16 to 14
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Occupied',
                          style: GoogleFonts.inter(
                            fontSize: 8, // Reduced from 9 to 8
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 14), // Reduced from 20 to 14
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Performance',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3), // Reduced from 4 to 3
                      Text(
                        '${totalPgsCount} properties • ${totalBeds} beds',
                        style: GoogleFonts.inter(
                          fontSize: 11, // Reduced from 12 to 11
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(64, 64, 96, 1),
                        ),
                      ),
                      const SizedBox(height: 6), // Reduced from 8 to 6
                      LinearProgressIndicator(
                        value: occupancyRate / 100,
                        backgroundColor: Color.fromRGBO(
                          3,
                          4,
                          94,
                          1.0,
                        ).withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color.fromRGBO(3, 4, 94, 1.0),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        minHeight: 3, // Reduced from 4 to 3
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14), // Reduced from 20 to 14
          // Stats Grid - Premium 3 Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _buildPremiumStatCard(
                  label: 'Active',
                  value: activePostsCount,
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF059669),
                ),
                const SizedBox(width: 10), // Reduced from 10 to 8
                _buildPremiumStatCard(
                  label: 'Occupied',
                  value: occupiedBedsCount,
                  icon: Icons.bed_rounded,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 10), // Reduced from 10 to 8
                _buildPremiumStatCard(
                  label: 'Available',
                  value: emptyBedsCount,
                  icon: Icons.hotel_rounded,
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStatCard({
    required String label,
    required num value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 6,
        ), // Reduced from 14,8 to 10,6
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(0, 3),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6), // Reduced from 8 to 6
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  10,
                ), // Reduced from 12 to 10
              ),
              child: Icon(
                icon,
                color: color,
                size: 16,
              ), // Reduced from 18 to 16
            ),
            const SizedBox(height: 4), // Reduced from 6 to 4
            AnimatedFlipCounter(
              value: value,
              duration: const Duration(milliseconds: 500),
              textStyle: GoogleFonts.inter(
                fontSize: 16, // Reduced from 18 to 16
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9, // Reduced from 10 to 9
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compact Quick Actions
  Widget _buildCompactQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _quickActions.map((action) {
          return GestureDetector(
            onTap: () => context.push(action.route),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        action.color.withOpacity(0.15),
                        action.color.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(action.icon, color: action.color, size: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  action.label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Modern Enquiries Section
  Widget _buildModernEnquiriesSection(List<EnquiryModel> enquiries, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Recent Enquiries',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (count > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/owner-enquiries'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (enquiries.isEmpty)
            _buildModernEmptyState(
              icon: Icons.inbox_rounded,
              message: 'No enquiries yet',
            )
          else
            ...enquiries.map((enquiry) => _buildCompactEnquiryItem(enquiry)),
        ],
      ),
    );
  }

  // Compact Enquiry Item
  Widget _buildCompactEnquiryItem(EnquiryModel enquiry) {
    final statusColors = {
      'interested': const Color(0xFFF59E0B),
      'visited': const Color(0xFFEF4444),
      'confirmed': const Color(0xFF10B981),
      'dealdone': const Color(0xFF6366F1),
      'cancelled': const Color(0xFF64748B),
    };

    final statusLabels = {
      'interested': 'Interested',
      'visited': 'Visited',
      'confirmed': 'Confirmed',
      'dealdone': 'Deal Done',
      'cancelled': 'Cancelled',
    };

    final statusKey = enquiry.status.toLowerCase().replaceAll(' ', '');
    final statusColor = statusColors[statusKey] ?? const Color(0xFFF59E0B);
    final statusLabel = statusLabels[statusKey] ?? enquiry.status;

    int days = 0;
    try {
      final dt = DateTime.parse(enquiry.createdAt).toLocal();
      days = DateTime.now().difference(dt).inDays;
    } catch (_) {}

    final userName = enquiry.user?.name ?? 'Guest';
    final pgName = enquiry.pg?.name ?? 'Unknown PG';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    pgName,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  days == 0 ? 'Today' : '$days${days == 1 ? 'd' : 'd'}',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Modern Property Portfolio
  Widget _buildModernPropertyPortfolio(List<PgModel> pgs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Your Properties',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/my-pgs'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Manage',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pgs.isEmpty)
            _buildModernEmptyState(
              icon: Icons.business_rounded,
              message: 'No properties found',
            )
          else
            ...pgs.take(3).map((pg) => _buildCompactPropertyCard(pg)).toList(),
        ],
      ),
    );
  }

  // Compact Property Card
  Widget _buildCompactPropertyCard(PgModel pg) {
    Color typeColor = const Color(0xFF6366F1);
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

    return GestureDetector(
      onTap: () => context.push('/owner/pg-details', extra: pg),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: typeColor.withOpacity(0.08), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [typeColor, typeColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.apartment_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pg.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 10,
                        color: const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        [
                          pg.address.city,
                          pg.address.state,
                        ].where((e) => e.isNotEmpty).join(', '),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pg.pgType.isNotEmpty ? pg.pgType : 'N/A',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: typeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pg.emptyBeds} beds',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Modern Vacancy Section
  Widget _buildModernVacancySection(List<PgPost> posts, int totalCount) {
    String formatPrice(double price) {
      if (price % 1 == 0) {
        return '₹${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
      }
      return '₹${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Active Listings',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalCount',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => context.push('/vacancies'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (posts.isEmpty)
            _buildModernEmptyState(
              icon: Icons.post_add_rounded,
              message: 'No active listings',
            )
          else
            ...posts.take(3).map((post) {
              final priceRange =
                  (post.minPrice != null && post.maxPrice != null)
                  ? '${formatPrice(post.minPrice!)} - ${formatPrice(post.maxPrice!)}'
                  : formatPrice(post.minPrice ?? 0);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.06),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.post_add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title.isNotEmpty ? post.title : 'New Listing',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${post.pg.name} • ${post.vacancyCount} beds',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF94A3B8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF10B981).withOpacity(0.1),
                            const Color(0xFF10B981).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        priceRange,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  // Modern Empty State
  Widget _buildModernEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Drawer with Premium Styling
  Widget _buildOwnerDrawer(BuildContext context, dynamic user) {
    return Drawer(
      backgroundColor: context.surfaceWhite,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Icon(
                      Icons.apartment_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? 'Owner',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  user?.email ?? 'owner@example.com',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                _buildModernDrawerTile(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  isActive: true,
                  onTap: () => Navigator.pop(context),
                ),
                _buildModernDrawerTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Enquiries',
                  badge: 'New',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/owner-enquiries');
                  },
                ),
                _buildModernDrawerTile(
                  icon: Icons.receipt_long_rounded,
                  title: 'Rent Management',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/owner-rent');
                  },
                ),
                _buildModernDrawerTile(
                  icon: Icons.people_outline_rounded,
                  title: 'Staff & Expense',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/staff-tracker');
                  },
                ),
                _buildModernDrawerTile(
                  icon: Icons.report_problem_outlined,
                  title: 'Complaints',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/complaints');
                  },
                ),
                _buildModernDrawerTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/notifications');
                  },
                ),
                const Divider(height: 1),
                _buildModernDrawerTile(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  onTap: () => Navigator.pop(context),
                ),
                _buildModernDrawerTile(
                  icon: ref.watch(themeProvider) == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  title: 'Dark Mode',
                  trailingWidget: Switch(
                    value:
                        ref.watch(themeProvider) == ThemeMode.dark ||
                        (ref.watch(themeProvider) == ThemeMode.system &&
                            MediaQuery.of(context).platformBrightness ==
                                Brightness.dark),
                    onChanged: (value) {
                      ref.read(themeProvider.notifier).state = value
                          ? ThemeMode.dark
                          : ThemeMode.light;
                    },
                    activeColor: const Color(0xFF6366F1),
                  ),
                  onTap: () {
                    final isCurrentlyDark =
                        ref.read(themeProvider) == ThemeMode.dark ||
                        (ref.read(themeProvider) == ThemeMode.system &&
                            MediaQuery.of(context).platformBrightness ==
                                Brightness.dark);
                    ref.read(themeProvider.notifier).state = !isCurrentlyDark
                        ? ThemeMode.dark
                        : ThemeMode.light;
                  },
                ),
                const SizedBox(height: 16),
                _buildModernDrawerTile(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          'Logout',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                        ),
                        content: Text(
                          'Are you sure you want to logout?',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ref.read(authProvider.notifier).logout();
                            },
                            child: Text(
                              'Logout',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFEF4444),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modern Drawer Tile
  Widget _buildModernDrawerTile({
    required IconData icon,
    required String title,
    bool isActive = false,
    String? badge,
    Widget? trailingWidget,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF6366F1).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFF6366F1) : const Color(0xFF64748B),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
        ),
      ),
      trailing:
          trailingWidget ??
          (badge != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: isActive ? const Color(0xFF6366F1).withOpacity(0.05) : null,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

// Quick Action Model
class QuickAction {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  QuickAction({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}

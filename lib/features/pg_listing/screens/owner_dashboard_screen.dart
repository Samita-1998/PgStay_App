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

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Quick action items
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
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: user?.name.split(' ')[0] ?? 'Owner',
        subtitle: 'Welcome back 👋',
        showBackButton: false,
        pinnedSCurve: true,
        backgroundColor: const Color(0xFFF8FAFC),
        onLeadingPressed: () => _scaffoldKey.currentState?.openDrawer(),
        actionWidget: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 22,
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
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
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      0.9 * MediaQuery.of(context).padding.top,
                      20,
                      0,
                    ),
                    child: Column(
                      children: [
                        // Property Overview Card
                        StaggeredFadeIn(
                          delay: const Duration(milliseconds: 100),
                          child: _buildPremiumOverviewCard(
                            totalPgsCount: totalPgsCount,
                            activePostsCount: activePostsCount,
                            occupiedBedsCount: occupiedBedsCount,
                            emptyBedsCount: emptyBedsCount,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Quick Actions
                        StaggeredFadeIn(
                          delay: const Duration(milliseconds: 150),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white, const Color(0xFFF8FAFC)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.08),
                                  blurRadius: 30,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    12,
                                    0,
                                    18,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color.fromRGBO(3, 4, 94, 1.0),
                                              Color(0xFF303B87),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Quick Actions',
                                        style: GoogleFonts.inter(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: _quickActions.map((action) {
                                    return _buildModernQuickAction(action);
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Divider
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.grey.withOpacity(0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Recent Enquiries
                        StaggeredFadeIn(
                          delay: const Duration(milliseconds: 250),
                          child: _buildModernEnquiriesSection(
                            recentEnquiries,
                            newEnquiriesCount,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Property Portfolio
                        StaggeredFadeIn(
                          delay: const Duration(milliseconds: 300),
                          child: _buildModernPropertyPortfolio(pgs),
                        ),

                        const SizedBox(height: 20),

                        // Vacancy Listings
                        StaggeredFadeIn(
                          delay: const Duration(milliseconds: 350),
                          child: _buildModernVacancySection(
                            vacancyPosts,
                            totalPostsCount,
                          ),
                        ),

                        const SizedBox(height: 100),
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

  // Property Overview Card with Stats in Single Row
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(3, 4, 94, 1.0).withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      padding: const EdgeInsets.all(24),
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
              const SizedBox(width: 12),
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
                  horizontal: 12,
                  vertical: 6,
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
                    const SizedBox(width: 6),
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

          const SizedBox(height: 24),

          // Occupancy Rate - Premium Design
          Container(
            padding: const EdgeInsets.all(20),
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
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: (occupiedBedsCount + emptyBedsCount) > 0
                            ? occupiedBedsCount /
                                  (occupiedBedsCount + emptyBedsCount)
                            : 0,
                        strokeWidth: 7,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Occupied',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
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
                      const SizedBox(height: 4),
                      Text(
                        '${totalPgsCount} properties • ${totalBeds} beds',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(64, 64, 96, 1),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                        minHeight: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stats Grid - Premium 3 Cards
          Row(
            children: [
              _buildPremiumStatCard(
                label: 'Active',
                value: activePostsCount,
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF059669),
              ),
              const SizedBox(width: 10),
              _buildPremiumStatCard(
                label: 'Occupied',
                value: occupiedBedsCount,
                icon: Icons.bed_rounded,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 10),
              _buildPremiumStatCard(
                label: 'Available',
                value: emptyBedsCount,
                icon: Icons.hotel_rounded,
                color: const Color(0xFFEF4444),
              ),
            ],
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            AnimatedFlipCounter(
              value: value,
              duration: const Duration(milliseconds: 500),
              textStyle: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern Quick Action Button
  Widget _buildModernQuickAction(QuickAction action) {
    return GestureDetector(
      onTap: () => context.push(action.route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: action.color.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [BoxShadow(color: action.color.withOpacity(0.15))],
            ),
            child: Icon(action.icon, color: action.color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            action.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  // Modern Enquiry Banner
  Widget _buildModernEnquiryBanner(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1),
            const Color(0xFF8B5CF6),
            const Color(0xFFA78BFA),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.mail_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Enquiries',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  '$count enquiries waiting',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              count > 0 ? 'View All' : 'No new',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modern Enquiries Section
  Widget _buildModernEnquiriesSection(List<EnquiryModel> enquiries, int count) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.06), width: 1),
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
                  gradient: const LinearGradient(
                    colors: [Color.fromRGBO(3, 4, 94, 1.0), Color(0xFF303B87)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Enquiries',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/owner-enquiries'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (enquiries.isEmpty)
            _buildModernEmptyState(
              icon: Icons.inbox_rounded,
              message: 'No enquiries yet',
            )
          else
            ...enquiries.map((enquiry) => _buildModernEnquiryItem(enquiry)),
        ],
      ),
    );
  }

  // Modern Enquiry Item (Infographic Step Design)
  Widget _buildModernEnquiryItem(EnquiryModel enquiry) {
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

    final pgName = enquiry.pg?.name ?? 'Unknown PG';
    final userName = enquiry.user?.name ?? 'Guest';
    final userPic = enquiry.user?.picture ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // border: Border(right: BorderSide(color: statusColor, width: 4)),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.2),
              blurRadius: 2,
              offset: Offset(0, 2),
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor.withOpacity(0.1),
                    ),
                    child: userPic.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              userPic,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildInitials(userName, statusColor),
                            ),
                          )
                        : _buildInitials(userName, statusColor),
                  ),

                  const SizedBox(width: 14),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(statusLabel, statusColor),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.home_outlined,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                pgName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w400,
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
                              Icons.access_time_rounded,
                              size: 13,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              days == 0
                                  ? 'Today'
                                  : '$days ${days == 1 ? 'day' : 'days'} ago',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildInitials(String name, Color color) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // Modern Property Portfolio
  Widget _buildModernPropertyPortfolio(List<PgModel> pgs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.06), width: 1),
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
                  gradient: const LinearGradient(
                    colors: [Color.fromRGBO(3, 4, 94, 1.0), Color(0xFF303B87)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Your Properties',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/my-pgs'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Manage',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (pgs.isEmpty)
            _buildModernEmptyState(
              icon: Icons.business_rounded,
              message: 'No properties found',
            )
          else
            ...pgs.take(3).map((pg) => _buildModernPropertyCard(pg)).toList(),
        ],
      ),
    );
  }

  // Modern Property Card
  Widget _buildModernPropertyCard(PgModel pg) {
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFF8FAFC), Colors.white],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: typeColor.withOpacity(0.08), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [typeColor, typeColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: typeColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.apartment_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pg.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
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
                        size: 12,
                        color: const Color(0xFF94A3B8),
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
                          color: const Color(0xFF64748B),
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
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        typeColor.withOpacity(0.1),
                        typeColor.withOpacity(0.05),
                      ],
                    ),
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
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.1),
                        const Color(0xFF10B981).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pg.emptyBeds} beds',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
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

  // Modern Vacancy Section
  Widget _buildModernVacancySection(List<PgPost> posts, int totalCount) {
    String formatPrice(double price) {
      if (price % 1 == 0) {
        return '₹${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
      }
      return '₹${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.06), width: 1),
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
                  gradient: const LinearGradient(
                    colors: [Color.fromRGBO(3, 4, 94, 1.0), Color(0xFF303B87)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Active Listings',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/vacancies'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$totalCount total posts',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
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
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFFF8FAFC), Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.06),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.post_add_rounded,
                        color: Colors.white,
                        size: 22,
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
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${post.pg.name} • ${post.vacancyCount} beds',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF10B981).withOpacity(0.1),
                            const Color(0xFF10B981).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        priceRange,
                        style: GoogleFonts.inter(
                          fontSize: 13,
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
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 32, color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
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
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6),
                  const Color(0xFFA78BFA),
                ],
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
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Icon(
                      Icons.apartment_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'Owner',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  user?.email ?? 'owner@example.com',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                  subtitle: 'Track & collect rent',
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
    String? subtitle,
    bool isActive = false,
    String? badge,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF6366F1).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFF6366F1) : const Color(0xFF64748B),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
              ),
            )
          : null,
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFEF4444), const Color(0xFFF87171)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isActive ? const Color(0xFF6366F1).withOpacity(0.05) : null,
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

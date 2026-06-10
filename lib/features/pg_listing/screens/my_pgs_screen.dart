import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/features/pg_listing/screens/add_pg_screen.dart';
import 'package:pgstay/features/pg_listing/screens/inventory_management_screen.dart';
import 'package:pgstay/features/pg_listing/screens/owner_pg_details_screen.dart';

class MyPgsScreen extends ConsumerStatefulWidget {
  const MyPgsScreen({super.key});

  @override
  ConsumerState<MyPgsScreen> createState() => _MyPgsScreenState();
}

class _MyPgsScreenState extends ConsumerState<MyPgsScreen> {
  String _selectedTab = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Custom color palette matching the dashboard
  static const Color primaryColor = Color.fromRGBO(3, 4, 94, 1.0);
  static const Color secondaryColor = Color.fromRGBO(58, 63, 150, 1.0);
  static const Color accentColor = Color.fromRGBO(96, 102, 208, 1.0);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color textPrimaryColor = Color.fromRGBO(3, 4, 94, 1.0);
  static const Color textSecondaryColor = Color.fromRGBO(58, 63, 150, 1.0);
  static const Color textHintColor = Color(0xFF9CA3AF);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownerPgsAsync = ref.watch(ownerPgsProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(ownerPgsProvider),
          color: primaryColor,
          child: ownerPgsAsync.when(
            data: (pgs) {
              var filteredPgs = pgs.where((pg) {
                final q = _searchQuery.toLowerCase();
                return pg.name.toLowerCase().contains(q) ||
                    pg.address.city.toLowerCase().contains(q) ||
                    pg.address.landmark.toLowerCase().contains(q);
              }).toList();

              if (_selectedTab == 'active') {
                filteredPgs = filteredPgs
                    .where((pg) => pg.isActive == true)
                    .toList();
              } else if (_selectedTab == 'pending') {
                filteredPgs = filteredPgs
                    .where((pg) => pg.isActive == false)
                    .toList();
              }

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header Section
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "My Properties",
                                      style: GoogleFonts.inter(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimaryColor,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${pgs.length} propert${pgs.length == 1 ? 'y' : 'ies'} registered',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Add Property Button
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primaryColor, secondaryColor],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AddPgScreen(),
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Search Bar
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: textHintColor.withOpacity(0.15),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: textHintColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: textPrimaryColor,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search by name, city or landmark...',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: textHintColor,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (val) => setState(
                                      () => _searchQuery = val.trim(),
                                    ),
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: textHintColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: textHintColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Filter Tabs
                          SizedBox(
                            height: 42,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildTabChip(
                                  'All Properties',
                                  'all',
                                  pgs.length,
                                ),
                                const SizedBox(width: 10),
                                _buildTabChip(
                                  'Active',
                                  'active',
                                  pgs.where((p) => p.isActive).length,
                                ),
                                const SizedBox(width: 10),
                                _buildTabChip(
                                  'Inactive',
                                  'pending',
                                  pgs.where((p) => !p.isActive).length,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // PG Cards List
                  if (filteredPgs.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.08),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.apartment_outlined,
                                size: 64,
                                color: textHintColor.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No results found for "$_searchQuery"'
                                  : 'No properties in this category',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textSecondaryColor,
                              ),
                            ),
                            if (pgs.isEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Get started by adding your first property',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: textHintColor,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddPgScreen(),
                                  ),
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(
                                  'Add Property',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final pg = filteredPgs[index];
                          return StaggeredFadeIn(
                            delay: Duration(milliseconds: 60 * index),
                            child: _PgCard(pg: pg),
                          );
                        }, childCount: filteredPgs.length),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: errorColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 56,
                        color: errorColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Unable to Load Properties',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimaryColor,
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
                      onPressed: () => ref.refresh(ownerPgsProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
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
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, String tabKey, int count) {
    final isSelected = _selectedTab == tabKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tabKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [primaryColor, secondaryColor])
              : null,
          color: isSelected ? null : surfaceColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : textHintColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : textSecondaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PgCard extends StatelessWidget {
  final PgModel pg;
  const _PgCard({required this.pg});

  @override
  Widget build(BuildContext context) {
    final occupancyPercent = pg.totalBeds > 0
        ? pg.occupiedBeds / pg.totalBeds
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OwnerPgDetailsScreen(pg: pg),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color.fromRGBO(3, 4, 94, 1.0),
                              const Color.fromRGBO(58, 63, 150, 1.0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pg.name,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color.fromRGBO(3, 4, 94, 1.0),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    [
                                      if (pg.address.landmark.isNotEmpty)
                                        pg.address.landmark,
                                      pg.address.city,
                                    ].join(', '),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF6B7280),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: pg.isActive
                              ? const Color(0xFF10B981).withOpacity(0.1)
                              : const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: pg.isActive
                                ? const Color(0xFF10B981).withOpacity(0.3)
                                : const Color(0xFFEF4444).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: pg.isActive
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              pg.isActive ? 'Active' : 'Inactive',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: pg.isActive
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFE5E7EB)),

                // Stats Grid
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _buildMiniStat(
                        'Total Beds',
                        pg.totalBeds.toString(),
                        Icons.bed_rounded,
                        const Color.fromRGBO(3, 4, 94, 1.0),
                      ),
                      _buildMiniStat(
                        'Occupied',
                        pg.occupiedBeds.toString(),
                        Icons.people_rounded,
                        const Color.fromRGBO(96, 102, 208, 1.0),
                      ),
                      _buildMiniStat(
                        'Available',
                        pg.emptyBeds.toString(),
                        Icons.hotel_rounded,
                        const Color(0xFFF59E0B),
                      ),
                      _buildMiniStat(
                        'Rooms',
                        pg.totalRooms.toString(),
                        Icons.door_front_door_outlined,
                        const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),

                // Occupancy Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Occupancy Rate',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            '${(occupancyPercent * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: occupancyPercent >= 0.8
                                  ? const Color(0xFFEF4444)
                                  : occupancyPercent >= 0.5
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: occupancyPercent.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            occupancyPercent >= 0.8
                                ? const Color(0xFFEF4444)
                                : occupancyPercent >= 0.5
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Facilities
                if (pg.facilities.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: pg.facilities.take(4).map((f) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(
                              3,
                              4,
                              94,
                              1.0,
                            ).withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            f,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color.fromRGBO(3, 4, 94, 1.0),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // Footer
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(
                            96,
                            102,
                            208,
                            1.0,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          pg.pgType.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromRGBO(96, 102, 208, 1.0),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFBBF24),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pg.rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromRGBO(3, 4, 94, 1.0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Check-in ${pg.checkInTime}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    border: Border(
                      top: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(
                                96,
                                102,
                                208,
                                1.0,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Color.fromRGBO(96, 102, 208, 1.0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mgr: Sagar Thakare',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildActionButton(
                            icon: Icons.inventory_2_outlined,
                            color: const Color(0xFF9E77ED),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      InventoryManagementScreen(pg: pg),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.edit_outlined,
                            color: const Color.fromRGBO(96, 102, 208, 1.0),
                            onTap: () {
                              // TODO: Edit action
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.delete_outline,
                            color: const Color(0xFFEF4444),
                            onTap: () {
                              // TODO: Delete action
                            },
                          ),
                        ],
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color.fromRGBO(3, 4, 94, 1.0),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

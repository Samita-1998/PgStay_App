import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/features/pg_listing/screens/owner_dashboard_screen.dart';
import 'package:pgstay/features/pg_listing/widgets/property_details_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(pgListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FilterBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;

    // Route owner immediately
    if (user != null && user.role.toLowerCase() == 'owner') {
      return const OwnerDashboardScreen();
    }

    final pgListAsync = ref.watch(pgListProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(pgListProvider),
          color: AppTheme.primary,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CustomSliverAppBar(
                title: 'Find Your Next Home',
                subtitle: 'Browse available PG rooms based on your preferences',
                showBackButton: false,
                onLeadingPressed: () {
                  // Scaffold.of(context).openDrawer(); // If drawer exists
                },
                actionWidget: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                  ),
                ),
              ),
              // ─── Header Section ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [


                      // Search Input
                      Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLG,
                          ),
                          border: Border.all(color: AppTheme.surfaceBorder),
                          boxShadow: AppTheme.softShadow(opacity: 0.03),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: AppTheme.textSecondary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: AppTheme.textTheme.bodyMedium,
                                decoration: InputDecoration(
                                  hintText:
                                      'Search by city, area, or PG name...',
                                  hintStyle: AppTheme.textTheme.bodySmall,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  setState(() => _searchQuery = value.trim());
                                },
                                onSubmitted: (value) {
                                  ref
                                      .read(pgSearchCityProvider.notifier)
                                      .state = value
                                      .trim();
                                  ref
                                      .read(pgListProvider.notifier)
                                      .fetchInitial();
                                },
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  ref
                                          .read(pgSearchCityProvider.notifier)
                                          .state =
                                      '';
                                  ref
                                      .read(pgListProvider.notifier)
                                      .fetchInitial();
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Filter Chips Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // PG Type
                            _buildDropdownChip(
                              ref.watch(pgTypeFilterProvider),
                              [
                                'Any Type',
                                'male',
                                'female',
                                'unisex',
                                'co-living',
                              ],
                              (val) {
                                ref.read(pgTypeFilterProvider.notifier).state =
                                    val;
                                ref
                                    .read(pgListProvider.notifier)
                                    .fetchInitial();
                              },
                            ),
                            const SizedBox(width: 12),
                            // Occupancy
                            _buildDropdownChip(
                              ref.watch(pgOccupancyFilterProvider),
                              ['Sharing', 'single', 'double', 'triple'],
                              (val) {
                                ref
                                        .read(
                                          pgOccupancyFilterProvider.notifier,
                                        )
                                        .state =
                                    val;
                                ref
                                    .read(pgListProvider.notifier)
                                    .fetchInitial();
                              },
                            ),
                            const SizedBox(width: 12),
                            // Filter Button
                            GestureDetector(
                              onTap: _showFilterBottomSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.filter_list_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Filters',
                                      style: AppTheme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
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

              // ─── Stay List Section ───────────────────────────
              pgListAsync.when(
                data: (posts) {
                  final activeVacancies = ref.watch(pgActiveVacanciesProvider);
                  final facilities = ref.watch(pgFacilitiesFilterProvider);

                  // Filter posts based on search query ONLY, other filters applied in Provider
                  var filteredPosts = posts.where((post) {
                    if (activeVacancies && post.vacancyCount <= 0) return false;

                    if (facilities.isNotEmpty) {
                      final hasAllFacilities = facilities.every(
                        (f) => post.pg.facilities.any(
                          (fac) => fac.toLowerCase() == f.toLowerCase(),
                        ),
                      );
                      if (!hasAllFacilities) return false;
                    }

                    final matchesSearch =
                        _searchQuery.isEmpty ||
                        post.title.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        post.pg.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        post.pg.address.city.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        post.pg.address.landmark.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        );

                    return matchesSearch;
                  }).toList();

                  if (filteredPosts.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.home_work_outlined,
                              size: 64,
                              color: AppTheme.textHint.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Stays Found',
                              style: AppTheme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try adjusting your search filters.',
                              style: AppTheme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == filteredPosts.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.accentColor,
                                ),
                              ),
                            );
                          }
                          final post = filteredPosts[index];
                          return StaggeredFadeIn(
                            delay: Duration(milliseconds: (index % 10) * 60),
                            child: _buildStayCard(post),
                          );
                        },
                        childCount:
                            filteredPosts.length + (posts.length >= 10 ? 1 : 0),
                      ), // Show loader if more might come
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
                error: (err, stack) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: AppTheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load stays',
                            style: AppTheme.textTheme.headlineSmall?.copyWith(
                              color: AppTheme.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            err.toString(),
                            style: AppTheme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => ref.refresh(pgListProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMD,
                                ),
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    return GestureDetector(
      onTap: _showFilterBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownChip(
    String label,
    List<String> items,
    Function(String) onSelected,
  ) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) {
        return items.map((item) {
          final isSelected = label == item;
          return PopupMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStayCard(PgPost post) {
    Color typeColor = AppTheme.accentColor;
    if (post.pgType.toLowerCase() == 'female') typeColor = Colors.pink;
    if (post.pgType.toLowerCase() == 'male') typeColor = Colors.blue;
    if (post.pgType.toLowerCase() == 'unisex' ||
        post.pgType.toLowerCase() == 'coliving')
      typeColor = Colors.teal;

    final isEnquired = post.enquiryData != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => PropertyDetailsBottomSheet(post: post),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Stack
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(23),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: AppTheme.primary.withOpacity(0.03),
                      child: post.images.isNotEmpty
                          ? Image.network(post.images.first, fit: BoxFit.cover)
                          : const Icon(
                              Icons.apartment_rounded,
                              size: 48,
                              color: AppTheme.textHint,
                            ),
                    ),
                  ),
                ),
                // Price Badge (Top Right)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '₹${post.minPrice?.toStringAsFixed(0) ?? 0} - ₹${post.maxPrice?.toStringAsFixed(0) ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Type Badge (Bottom Left)
                Positioned(
                  bottom: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: typeColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      post.pgType,
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.pg.name.toUpperCase(),
                    style: AppTheme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.title,
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.pg.address.city,
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Vacancy Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                      color: Colors.orange.withOpacity(0.05),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bed_rounded,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.vacancyCount} Left',
                          style: AppTheme.textTheme.labelSmall?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.description.isNotEmpty
                        ? post.description
                        : 'No description available',
                    style: AppTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Action Button
                  if (isEnquired)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.success),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppTheme.success,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'REQUESTED',
                            style: TextStyle(
                              color: AppTheme.success,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Show Interest',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
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

class _FilterBottomSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<_FilterBottomSheet> {
  late double _minPrice;
  late double _maxPrice;
  late bool _activeVacancies;
  late List<String> _selectedFacilities;
  String _facilitySearchQuery = '';

  final List<String> _allFacilities = [
    'WiFi',
    'AC',
    'Food',
    'Laundry',
    'Cleaning',
    'TV',
    'Gym',
    'Parking',
    'CCTV',
    'Power Backup',
    'Geyser',
    'Attached Washroom',
    'Washing Machine',
    'Refrigerator',
    'Water Purifier',
  ];

  @override
  void initState() {
    super.initState();
    _minPrice = ref.read(pgMinPriceFilterProvider);
    _maxPrice = ref.read(pgMaxPriceFilterProvider);
    _activeVacancies = ref.read(pgActiveVacanciesProvider);
    _selectedFacilities = List.from(ref.read(pgFacilitiesFilterProvider));
  }

  void _applyFilters() {
    ref.read(pgMinPriceFilterProvider.notifier).state = _minPrice;
    ref.read(pgMaxPriceFilterProvider.notifier).state = _maxPrice;
    ref.read(pgActiveVacanciesProvider.notifier).state = _activeVacancies;
    ref.read(pgFacilitiesFilterProvider.notifier).state = _selectedFacilities;

    // Refresh the list with new filters
    ref.read(pgListProvider.notifier).fetchInitial(); // Re-trigger initial load
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final filteredFacilities = _allFacilities
        .where(
          (f) => f.toLowerCase().contains(_facilitySearchQuery.toLowerCase()),
        )
        .toList();

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 100,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: AppTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Vacancies Checkbox
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Only show stays with active vacancies (beds left > 0)',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              activeColor: AppTheme.primary,
              value: _activeVacancies,
              onChanged: (val) {
                if (val != null) setState(() => _activeVacancies = val);
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),

            Text(
              'Budget Range: ₹${_minPrice.toInt()} - ₹${_maxPrice == 0 ? 'Any' : _maxPrice.toInt()}',
              style: AppTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            RangeSlider(
              values: RangeValues(
                _minPrice,
                _maxPrice == 0 ? 50000 : _maxPrice,
              ),
              min: 0,
              max: 50000,
              divisions: 50,
              activeColor: AppTheme.primary,
              labels: RangeLabels(
                '₹${_minPrice.toInt()}',
                _maxPrice == 0 || _maxPrice == 50000
                    ? 'Any'
                    : '₹${_maxPrice.toInt()}',
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _minPrice = values.start;
                  _maxPrice = values.end == 50000 ? 0 : values.end;
                });
              },
            ),
            const SizedBox(height: 24),

            // Facilities
            Text(
              'Facilities & Amenities',
              style: AppTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search facilities...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppTheme.surfaceWhite,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (val) => setState(() => _facilitySearchQuery = val),
            ),
            const SizedBox(height: 12),
            if (filteredFacilities.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No facilities found matching your search.'),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filteredFacilities.map((facility) {
                  final isSelected = _selectedFacilities.contains(facility);
                  return FilterChip(
                    label: Text(facility),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFacilities.add(facility);
                        } else {
                          _selectedFacilities.remove(facility);
                        }
                      });
                    },
                    selectedColor: AppTheme.primary.withOpacity(0.1),
                    checkmarkColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Apply Filters',
                  style: AppTheme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

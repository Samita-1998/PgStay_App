import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/features/pg_listing/screens/home_screen.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';

class BrowsePostsScreen extends ConsumerStatefulWidget {
  const BrowsePostsScreen({super.key});

  @override
  ConsumerState<BrowsePostsScreen> createState() => _BrowsePostsScreenState();
}

class _BrowsePostsScreenState extends ConsumerState<BrowsePostsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(browsePostTitleProvider);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(browsePostProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _search() {
    ref.read(browsePostTitleProvider.notifier).state = _searchController.text
        .trim();
    ref.read(browsePostProvider.notifier).fetchInitial();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BrowseFilterSheet(),
    );
  }

  String _ratingLabel(double r) {
    if (r == 0) return 'Any Rating';
    return '${r.toStringAsFixed(1)}+ ⭐';
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(browsePostProvider);
    final onlyVacancy = ref.watch(browsePostOnlyVacancyProvider);
    final city = ref.watch(browsePostCityProvider);
    final pgType = ref.watch(browsePostTypeProvider);
    final occupancy = ref.watch(browsePostOccupancyProvider);
    final minRating = ref.watch(browsePostMinRatingProvider);

    // Active filter count badge
    int activeFilters = 0;
    if (city.isNotEmpty) activeFilters++;
    if (pgType != 'Any Type') activeFilters++;
    if (occupancy != 'Sharing') activeFilters++;
    if (onlyVacancy) activeFilters++;
    if (ref.watch(browsePostMinPriceProvider) > 0) activeFilters++;
    if (ref.watch(browsePostMaxPriceProvider) > 0) activeFilters++;
    if (minRating > 0) activeFilters++;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: "Browse PG's",
        showBackButton: true,
        actionWidget: Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
              ),
              onPressed: _showFilterSheet,
            ),
            if (activeFilters > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    activeFilters.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Search + quick filter bar ────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                // Search box
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: AppTheme.textHint,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: AppTheme.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Search by title, city, PG name...',
                            hintStyle: AppTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textHint,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) => _search(),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppTheme.textHint,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(browsePostTitleProvider.notifier).state =
                                '';
                            ref
                                .read(browsePostProvider.notifier)
                                .fetchInitial();
                          },
                        ),
                      const SizedBox(width: 4),
                      Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextButton(
                          onPressed: _search,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Search',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Quick filter chips row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QuickDropdown(
                        label: pgType,
                        items: const [
                          'Any Type',
                          'male',
                          'female',
                          'unisex',
                          'co-living',
                        ],
                        isActive: pgType != 'Any Type',
                        onSelected: (val) {
                          ref.read(browsePostTypeProvider.notifier).state = val;
                          ref.read(browsePostProvider.notifier).fetchInitial();
                        },
                      ),
                      const SizedBox(width: 8),
                      _QuickDropdown(
                        label: occupancy,
                        items: const ['Sharing', 'single', 'double', 'triple'],
                        isActive: occupancy != 'Sharing',
                        onSelected: (val) {
                          ref.read(browsePostOccupancyProvider.notifier).state =
                              val;
                          ref.read(browsePostProvider.notifier).fetchInitial();
                        },
                      ),
                      const SizedBox(width: 8),
                      _QuickDropdown(
                        label: _ratingLabel(minRating),
                        items: const [
                          'Any Rating',
                          '1.0+ ⭐',
                          '2.0+ ⭐',
                          '3.0+ ⭐',
                          '4.0+ ⭐',
                          '4.5+ ⭐',
                        ],
                        isActive: minRating > 0,
                        onSelected: (val) {
                          double r = 0;
                          if (val != 'Any Rating') {
                            r =
                                double.tryParse(
                                  val
                                      .replaceAll('+', '')
                                      .replaceAll('⭐', '')
                                      .trim(),
                                ) ??
                                0;
                          }
                          ref.read(browsePostMinRatingProvider.notifier).state =
                              r;
                          ref.read(browsePostProvider.notifier).fetchInitial();
                        },
                      ),
                      const SizedBox(width: 8),
                      _QuickChip(
                        label: 'Vacant Only',
                        isActive: onlyVacancy,
                        icon: onlyVacancy
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        onTap: () {
                          ref
                                  .read(browsePostOnlyVacancyProvider.notifier)
                                  .state =
                              !onlyVacancy;
                          ref.read(browsePostProvider.notifier).fetchInitial();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Post list ────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.read(browsePostProvider.notifier).fetchInitial(),
              color: AppTheme.primary,
              child: postsAsync.when(
                data: (posts) {
                  if (posts.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.apartment_rounded,
                                size: 72,
                                color: AppTheme.textHint.withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No stays found',
                                style: AppTheme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search or filters',
                                style: AppTheme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    itemCount: posts.length + (posts.length >= 12 ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == posts.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                            ),
                          ),
                        );
                      }
                      return StaggeredFadeIn(
                        delay: Duration(milliseconds: (index % 10) * 60),
                        child: _PostCard(post: posts[index]),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 56,
                        color: AppTheme.textHint,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Something went wrong',
                        style: AppTheme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(browsePostProvider.notifier)
                            .fetchInitial(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
    );
  }
}

// ─── Post Card ──────────────────────────────────────────────────────────────
class _PostCard extends ConsumerStatefulWidget {
  final PgPost post;
  const _PostCard({required this.post});

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard> {
  bool _loading = false;

  Color get _typeColor {
    switch (widget.post.pgType.toLowerCase()) {
      case 'female':
      case 'girls':
        return Colors.pinkAccent;
      case 'male':
      case 'boys':
        return Colors.blueAccent;
      case 'co-living':
      case 'coliving':
        return Colors.deepPurpleAccent;
      default:
        return Colors.teal;
    }
  }

  Future<void> _viewDetails() async {
    final pgId = widget.post.pg.id;
    if (pgId.isEmpty) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(pgListingRepositoryProvider);
      final pg = await repo.fetchPgById(pgId);
      if (mounted) {
        context.push('/property-details/$pgId', extra: pg);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load details: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.post.images.isNotEmpty;
    final hasVacancy = widget.post.vacancyCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: InkWell(
        onTap: _loading ? null : _viewDetails,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image / placeholder header
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: SizedBox(
                height: 180,
                child: hasImages
                    ? Image.network(
                        widget.post.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge + vacancy badge row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _typeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.post.pgType.toUpperCase(),
                          style: TextStyle(
                            color: _typeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: hasVacancy
                              ? AppTheme.success.withOpacity(0.12)
                              : AppTheme.error.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          hasVacancy
                              ? '${widget.post.vacancyCount} Vacant'
                              : 'Full',
                          style: TextStyle(
                            color: hasVacancy
                                ? AppTheme.success
                                : AppTheme.error,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Rating
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.post.pg.rating.toStringAsFixed(1),
                            style: AppTheme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    widget.post.title,
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // PG name
                  Text(
                    widget.post.pg.name,
                    style: AppTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: AppTheme.textHint,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${widget.post.pg.address.city}, ${widget.post.pg.address.state}',
                          style: AppTheme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: AppTheme.dividerColor, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.post.minPrice != null ||
                          widget.post.maxPrice != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price Range',
                              style: AppTheme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.textHint,
                              ),
                            ),
                            Text(
                              _priceText(),
                              style: AppTheme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        )
                      else
                        const SizedBox.shrink(),
                      GestureDetector(
                        onTap: _loading ? null : _viewDetails,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _loading
                                ? AppTheme.primary.withOpacity(0.6)
                                : AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'View Details',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
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
    );
  }

  String _priceText() {
    if (widget.post.minPrice != null && widget.post.maxPrice != null) {
      return '₹${widget.post.minPrice!.toInt()} – ₹${widget.post.maxPrice!.toInt()}/mo';
    } else if (widget.post.minPrice != null) {
      return 'From ₹${widget.post.minPrice!.toInt()}/mo';
    } else if (widget.post.maxPrice != null) {
      return 'Up to ₹${widget.post.maxPrice!.toInt()}/mo';
    }
    return '';
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppTheme.primary.withOpacity(0.06),
      child: Center(
        child: Icon(
          Icons.apartment_rounded,
          size: 64,
          color: AppTheme.primary.withOpacity(0.25),
        ),
      ),
    );
  }
}

// ─── Quick Chip ─────────────────────────────────────────────────────────────
class _QuickChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final IconData? icon;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.isActive,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.surfaceBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.primary : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Dropdown ─────────────────────────────────────────────────────────
class _QuickDropdown extends StatelessWidget {
  final String label;
  final List<String> items;
  final bool isActive;
  final Function(String) onSelected;

  const _QuickDropdown({
    required this.label,
    required this.items,
    required this.isActive,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (ctx) => items
          .map(
            (item) => PopupMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  color: label == item
                      ? AppTheme.primary
                      : AppTheme.textPrimary,
                  fontWeight: label == item
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.surfaceBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.primary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Bottom Sheet ────────────────────────────────────────────────────
class _BrowseFilterSheet extends ConsumerStatefulWidget {
  const _BrowseFilterSheet();

  @override
  ConsumerState<_BrowseFilterSheet> createState() => _BrowseFilterSheetState();
}

class _BrowseFilterSheetState extends ConsumerState<_BrowseFilterSheet> {
  late bool _onlyVacancy;
  late List<String> _selectedFacilities;
  String _facilitySearch = '';

  final List<String> _allFacilities = [
    'Guest living',
    'Secured rooms',
    'CCTV',
    'Indian & Western toilet',
    'Iron',
    'Protein meal',
    '1 parking per bed',
    'Stay',
    '1/2/3 sharing',
    'Lunch & Dinner',
    'Breakfast & Lunch & Dinner',
    'Only veg food',
    'Veg-nonveg food',
    'Washing machine',
    'Wi-Fi service',
    'Study table',
    'Separate bed',
    'AC',
    'Gym',
    'Power Backup',
    'Geyser',
    'Refrigerator',
  ];

  @override
  void initState() {
    super.initState();
    _onlyVacancy = ref.read(browsePostOnlyVacancyProvider);
    _selectedFacilities = List.from(ref.read(browsePostFacilitiesProvider));
  }

  void _apply() {
    ref.read(browsePostOnlyVacancyProvider.notifier).state = _onlyVacancy;
    ref.read(browsePostFacilitiesProvider.notifier).state = _selectedFacilities;
    ref.read(browsePostProvider.notifier).fetchInitial();
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _onlyVacancy = false;
      _selectedFacilities = [];
      _facilitySearch = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allFacilities
        .where((f) => f.toLowerCase().contains(_facilitySearch.toLowerCase()))
        .toList();

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Advanced Filters',
                  style: AppTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Availability ──────────────────────────────────────────────
            Text(
              'Availability',
              style: AppTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Only show properties with vacant beds (beds left > 0)',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              activeColor: AppTheme.primary,
              value: _onlyVacancy,
              onChanged: (v) {
                if (v != null) setState(() => _onlyVacancy = v);
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 24),

            // ── Amenities & Facilities ────────────────────────────────────
            Text(
              'Amenities & Facilities',
              style: AppTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search amenities...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: AppTheme.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (v) => setState(() => _facilitySearch = v),
            ),
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No amenities found.',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textHint,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filtered.map((fac) {
                    final isSelected = _selectedFacilities.contains(fac);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedFacilities.remove(fac);
                          } else {
                            _selectedFacilities.add(fac);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withOpacity(0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.surfaceBorder,
                          ),
                        ),
                        child: Text(
                          fac,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 32),

            // ── Bottom buttons ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Reset All',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
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
}

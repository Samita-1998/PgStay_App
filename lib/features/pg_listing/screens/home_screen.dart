import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/features/pg_listing/screens/owner_dashboard_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(pgListProvider),
          color: AppTheme.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ─── Header Section ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
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
                                'Find Your Stay',
                                style: AppTheme.textTheme.displayMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Premium hostel & PG accommodations',
                                style: AppTheme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceWhite,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.surfaceBorder),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                color: AppTheme.textPrimary,
                              ),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

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
                                      'Search by city, landmark, or PG name...',
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
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Category Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterChip('All'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Coliving'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Male'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Female'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Unisex'),
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
                  // Filter posts based on search query & category selection
                  var filteredPosts = posts.where((post) {
                    final matchesSearch =
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

                    final matchesCat =
                        _selectedCategory == 'All' ||
                        post.pgType.toLowerCase() ==
                            _selectedCategory.toLowerCase() ||
                        post.occupancyType.toLowerCase() ==
                            _selectedCategory.toLowerCase();

                    return matchesSearch && matchesCat;
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
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = filteredPosts[index];
                        return StaggeredFadeIn(
                          delay: Duration(milliseconds: index * 60),
                          child: _buildStayCard(post),
                        );
                      }, childCount: filteredPosts.length),
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

  Widget _buildFilterChip(String category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.surfaceBorder,
            width: 1,
          ),
          boxShadow: isSelected
              ? AppTheme.primaryGlow(opacity: 0.1, blur: 10)
              : AppTheme.softShadow(opacity: 0.02),
        ),
        child: Text(
          category,
          style: AppTheme.textTheme.labelMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStayCard(PgPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: InkWell(
        onTap: () => context.push('/pg-details/${post.id}'),
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
                      child: Image.network(
                        'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=600&q=80',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.apartment_rounded,
                              size: 48,
                              color: AppTheme.textHint,
                            ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      border: Border.all(
                        color: AppTheme.accentColor.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      post.pgType,
                      style: AppTheme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content Details
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(post.pg.name, style: AppTheme.textTheme.titleSmall),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            post.pg.rating.toStringAsFixed(1),
                            style: AppTheme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.title,
                    style: AppTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppTheme.textHint,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.pg.address.toString(),
                          style: AppTheme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textHint,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(color: AppTheme.dividerColor),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vacancy Left',
                            style: AppTheme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textHint,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${post.vacancyCount} beds available',
                            style: AppTheme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: post.vacancyCount > 0
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Monthly Price',
                            style: AppTheme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textHint,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (post.minPrice != null && post.maxPrice != null)
                                ? '₹${post.minPrice!.toInt()} - ₹${post.maxPrice!.toInt()}'
                                : '₹${post.minPrice?.toInt() ?? 0}',
                            style: AppTheme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
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
}

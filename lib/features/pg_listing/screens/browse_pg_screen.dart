import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';

class BrowsePgScreen extends ConsumerStatefulWidget {
  const BrowsePgScreen({super.key});

  @override
  ConsumerState<BrowsePgScreen> createState() => _BrowsePgScreenState();
}

class _BrowsePgScreenState extends ConsumerState<BrowsePgScreen> {
  final TextEditingController _cityController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cityController.text = ref.read(discoverPgCityProvider);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(discoverPgProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _applyCityFilter() {
    ref.read(discoverPgCityProvider.notifier).state = _cityController.text
        .trim();
    ref.read(discoverPgProvider.notifier).fetchInitial();
  }

  @override
  Widget build(BuildContext context) {
    final pgAsync = ref.watch(discoverPgProvider);
    final selectedPgType = ref.watch(discoverPgTypeProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: 'Browse Properties',
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(discoverPgProvider.notifier).fetchInitial(),
        color: AppTheme.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMD,
                              ),
                              border: Border.all(color: AppTheme.surfaceBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_city_rounded,
                                  color: AppTheme.textHint,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _cityController,
                                    decoration: InputDecoration(
                                      hintText: 'Search by City...',
                                      hintStyle: AppTheme.textTheme.bodyMedium
                                          ?.copyWith(color: AppTheme.textHint),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                    ),
                                    onSubmitted: (_) => _applyCityFilter(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMD,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.search_rounded,
                              color: Colors.white,
                            ),
                            onPressed: _applyCityFilter,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // PG Type Filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Boys', 'Girls', 'Coliving'].map((
                          type,
                        ) {
                          final isSelected = selectedPgType == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(type),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  ref
                                          .read(discoverPgTypeProvider.notifier)
                                          .state =
                                      type;
                                  ref
                                      .read(discoverPgProvider.notifier)
                                      .fetchInitial();
                                }
                              },
                              selectedColor: AppTheme.primary.withOpacity(0.1),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pgAsync.when(
              data: (pgs) {
                if (pgs.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.business_rounded,
                            size: 64,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Properties Found',
                            style: AppTheme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
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
                      if (index == pgs.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.accentColor,
                            ),
                          ),
                        );
                      }
                      final pg = pgs[index];
                      return StaggeredFadeIn(
                        delay: Duration(milliseconds: (index % 10) * 60),
                        child: _buildPropertyCard(pg),
                      );
                    }, childCount: pgs.length + (ref.read(discoverPgProvider.notifier).hasMore ? 1 : 0)),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.accentColor),
                ),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(child: Text('Error: ${err.toString()}')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(PgModel pg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: InkWell(
        onTap: () => context.push('/property-details/${pg.id}', extra: pg),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(23),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: AppTheme.primary.withOpacity(0.05),
                      child: const Icon(
                        Icons.apartment_rounded,
                        size: 64,
                        color: AppTheme.textHint,
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
                      color: AppTheme.accentColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: Text(
                      pg.pgType,
                      style: AppTheme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pg.name,
                          style: AppTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            pg.rating.toStringAsFixed(1),
                            style: AppTheme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: AppTheme.textHint,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${pg.address.city}, ${pg.address.state}',
                          style: AppTheme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: AppTheme.dividerColor),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoColumn('Rooms', '${pg.totalRooms}'),
                      _buildInfoColumn('Beds', '${pg.totalBeds}'),
                      _buildInfoColumn(
                        'Available',
                        '${pg.emptyBeds}',
                        isHighlight: pg.emptyBeds > 0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () =>
                          context.push('/property-details/${pg.id}', extra: pg),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primary),
                        foregroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMD,
                          ),
                        ),
                      ),
                      child: const Text('View Property'),
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

  Widget _buildInfoColumn(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: AppTheme.textTheme.labelSmall?.copyWith(
            color: AppTheme.textHint,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: isHighlight ? AppTheme.success : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

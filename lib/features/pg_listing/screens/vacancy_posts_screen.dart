import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pgstay/features/pg_listing/widgets/pg_image_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/features/pg_listing/screens/create_vacancy_post_screen.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';

class VacancyPostsScreen extends ConsumerStatefulWidget {
  const VacancyPostsScreen({super.key});

  @override
  ConsumerState<VacancyPostsScreen> createState() => _VacancyPostsScreenState();
}

class _VacancyPostsScreenState extends ConsumerState<VacancyPostsScreen> {
  String formatPrice(double price) {
    if (price % 1 == 0) {
      return '₹${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
    return '₹${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(pgListProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Vacancy Posts',
        showBackButton: false,
        pinnedSCurve: true,
        isCompact: true,
        actionWidget: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateVacancyPostScreen(),
                ),
              ).then((_) => ref.refresh(pgListProvider));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 8 : 12,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              Icons.add,
              size: isSmallScreen ? 16 : 18,
              color: Colors.white,
            ),
            label: Text(
              'New Post',
              style: AppTheme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ),
        ),
      ),
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.refresh(pgListProvider);
          },
          color: AppTheme.accentColor,
          backgroundColor: AppTheme.surfaceWhite,
          child: postsAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.post_add_rounded,
                        size: 64,
                        color: AppTheme.textHint.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No vacancy posts found',
                        style: AppTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    isSmallScreen ? AppTheme.spacingLG : AppTheme.spacingXL,
                    120 + MediaQuery.of(context).padding.top + 32,
                    isSmallScreen ? AppTheme.spacingLG : AppTheme.spacingXL,
                    isSmallScreen ? AppTheme.spacingLG : AppTheme.spacingXL,
                  ),
                  itemCount: posts.length,
                  separatorBuilder: (context, index) => SizedBox(
                    height: isSmallScreen
                        ? AppTheme.spacingLG
                        : AppTheme.spacingXL,
                  ),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildPostCard(post, isSmallScreen);
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Error: $err',
                style: const TextStyle(color: AppTheme.error),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(PgPost post, bool isSmallScreen) {
    String formattedDate = '';
    try {
      final dt = DateTime.parse(post.createdAt).toLocal();
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
      formattedDate = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      formattedDate = post.createdAt;
    }

    final priceText =
        '${formatPrice(post.minPrice ?? 0)} - ${formatPrice(post.maxPrice ?? 0)}';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compact Image Section
          if (post.images.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXL),
              ),
              child: SizedBox(
                height: isSmallScreen ? 140 : 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _AutoPlayImageCarousel(
                      images: post.images,
                      isSmallScreen: isSmallScreen,
                    ),
                    // Image Count Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMD,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: isSmallScreen ? 10 : 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${post.images.length}',
                              style: AppTheme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: isSmallScreen ? 10 : 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: isSmallScreen ? 140 : 160,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBorder,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusXL),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppTheme.textHint,
                  size: 40,
                ),
              ),
            ),

          // Content Section with proper constraints
          Padding(
            padding: EdgeInsets.all(
              isSmallScreen ? AppTheme.spacingMD : AppTheme.spacingLG,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and Date Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMD,
                          ),
                          border: Border.all(
                            color: AppTheme.success.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          post.isActive ? 'Active' : 'Inactive',
                          style: AppTheme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.success,
                            fontSize: isSmallScreen ? 10 : 11,
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        formattedDate,
                        style: AppTheme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: isSmallScreen ? 10 : 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSM),

                // Title
                Text(
                  post.title,
                  style: AppTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: isSmallScreen ? 16 : 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // PG Name
                Text(
                  post.pg.name,
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingSM),

                // Compact Tags Wrap
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...post.occupancyTypes
                        .take(2)
                        .map(
                          (type) => _buildCompactTag(
                            _capitalize(type),
                            AppTheme.success,
                            isSmallScreen,
                          ),
                        ),
                    if (post.pgType.isNotEmpty)
                      _buildCompactTag(
                        _capitalize(post.pgType),
                        AppTheme.success,
                        isSmallScreen,
                      ),
                    _buildCompactTag(
                      '${post.vacancyCount} Left',
                      AppTheme.primary,
                      isSmallScreen,
                      icon: Icons.bed_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSM),

                // Compact Description
                Text(
                  post.description,
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    fontSize: isSmallScreen ? 11 : 12,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingSM),

                // Divider
                Divider(color: AppTheme.dividerColor, height: 1),
                const SizedBox(height: AppTheme.spacingSM),

                // Price and Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: priceText,
                              style: AppTheme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.success,
                                fontSize: isSmallScreen ? 16 : 18,
                              ),
                            ),
                            TextSpan(
                              text: '/mo',
                              style: AppTheme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: isSmallScreen ? 10 : 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCompactIconButton(
                          icon: Icons.edit_outlined,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CreateVacancyPostScreen(existingPost: post),
                              ),
                            ).then((_) => ref.invalidate(pgListProvider));
                          },
                          isSmallScreen: isSmallScreen,
                        ),
                        _buildCompactIconButton(
                          icon: Icons.delete_outline,
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppTheme.surfaceWhite,
                                title: Text(
                                  'Delete Post',
                                  style: AppTheme.textTheme.titleMedium
                                      ?.copyWith(
                                        fontSize: isSmallScreen ? 16 : 18,
                                      ),
                                ),
                                content: Text(
                                  'Are you sure you want to delete this vacancy post?',
                                  style: AppTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                        fontSize: isSmallScreen ? 13 : 14,
                                      ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(
                                      'Cancel',
                                      style: AppTheme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontSize: isSmallScreen ? 13 : 14,
                                          ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(
                                      'Delete',
                                      style: AppTheme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.error,
                                            fontSize: isSmallScreen ? 13 : 14,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              try {
                                final repo = ref.read(
                                  pgListingRepositoryProvider,
                                );
                                await repo.deletePost(post.id);
                                ref.invalidate(pgListProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Post deleted successfully',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 13,
                                        ),
                                      ),
                                      backgroundColor: AppTheme.error,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceAll(
                                          'Exception: ',
                                          '',
                                        ),
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 13,
                                        ),
                                      ),
                                      backgroundColor: AppTheme.error,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          isSmallScreen: isSmallScreen,
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
    );
  }

  Widget _buildCompactTag(
    String text,
    Color baseColor,
    bool isSmallScreen, {
    IconData? icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: baseColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isSmallScreen ? 10 : 12, color: baseColor),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: AppTheme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: baseColor,
              fontSize: isSmallScreen ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isSmallScreen,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
        child: Icon(
          icon,
          size: isSmallScreen ? 18 : 20,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _AutoPlayImageCarousel extends StatefulWidget {
  final List<String> images;
  final bool isSmallScreen;

  const _AutoPlayImageCarousel({
    required this.images,
    required this.isSmallScreen,
  });

  @override
  State<_AutoPlayImageCarousel> createState() => _AutoPlayImageCarouselState();
}

class _AutoPlayImageCarouselState extends State<_AutoPlayImageCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
        if (_currentPage < widget.images.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }

        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeIn,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.images.length,
      onPageChanged: (int page) {
        _currentPage = page;
      },
      itemBuilder: (context, index) {
        return PgImageWidget(
          imageUrl: widget.images[index],
          fit: BoxFit.cover,
          fallbackWidget: Container(
            color: AppTheme.surfaceBorder,
            child: const Icon(Icons.image, color: AppTheme.textHint),
          ),
        );
      },
    );
  }
}

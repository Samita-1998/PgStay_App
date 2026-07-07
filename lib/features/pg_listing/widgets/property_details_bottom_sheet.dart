import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/features/enquiries/providers/enquiries_provider.dart';

class PropertyDetailsBottomSheet extends ConsumerStatefulWidget {
  final PgPost post;

  const PropertyDetailsBottomSheet({super.key, required this.post});

  @override
  ConsumerState<PropertyDetailsBottomSheet> createState() =>
      _PropertyDetailsBottomSheetState();
}

class _PropertyDetailsBottomSheetState
    extends ConsumerState<PropertyDetailsBottomSheet> {
  bool _isSubmitting = false;
  bool _isPhoneRevealed = false;

  Future<void> _submitEnquiry() async {
    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(pgListingRepositoryProvider);
      await repo.submitEnquiry(widget.post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enquiry submitted successfully!')),
        );
        // Refresh the list to update the enquiry status on the card
        ref.read(pgListProvider.notifier).fetchInitial();
        // Refresh user's enquiries so the new enquiry shows up immediately in their tab
        ref.read(userEnquiriesProvider.notifier).fetchInitial();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: AppTheme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isEnquired = post.enquiryData != null;

    Color typeColor = AppTheme.accentColor; // Default
    if (post.pgType.toLowerCase() == 'female') typeColor = Colors.pink;
    if (post.pgType.toLowerCase() == 'male') typeColor = Colors.blue;
    if (post.pgType.toLowerCase() == 'unisex' ||
        post.pgType.toLowerCase() == 'coliving') {
      typeColor = Colors.teal;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color:
            AppTheme.surfaceWhite, // Adjust based on your theme implementation
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    style: AppTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Thumbnail
                      Container(
                        width: 120,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          image: post.images.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(post.images.first),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: Stack(
                          children: [
                            if (post.images.isEmpty)
                              const Center(
                                child: Icon(
                                  Icons.business_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 32,
                                ),
                              ),
                            Positioned(
                              bottom: 6,
                              left: 6,
                              child: _buildBadge(post.pgType, typeColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details Right
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.title,
                              style: AppTheme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
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
                                    '${post.pg.name}, ${post.pg.address.city}',
                                    style: AppTheme.textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '₹${post.minPrice?.toStringAsFixed(0) ?? 0} - ₹${post.maxPrice?.toStringAsFixed(0) ?? 0}',
                                    style: AppTheme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  TextSpan(
                                    text: ' / month',
                                    style: AppTheme.textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.5),
                                ),
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
                                    '${post.vacancyCount} Beds Remaining',
                                    style: AppTheme.textTheme.labelSmall
                                        ?.copyWith(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (post.pgType.toLowerCase() == 'coliving' ||
                                post.pgType.toLowerCase() == 'unisex') ...[
                              const SizedBox(height: 4),
                              Text(
                                '(${post.maleVacancyCount ?? 0} Male · ${post.femaleVacancyCount ?? 0} Female)',
                                style: AppTheme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // About this Property
                  Text(
                    'About this Property',
                    style: AppTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.description.isNotEmpty
                        ? post.description
                        : 'No description available.',
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Details Grid
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 80) / 2,
                        child: _buildDetailItem(
                          'Exact Location',
                          '${post.pg.address.landmark.isNotEmpty ? "${post.pg.address.landmark}, " : ""}${post.pg.address.city}, ${post.pg.address.state}',
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 80) / 2,
                        child: _buildDetailItem(
                          'Available From',
                          post.availableFrom ?? 'Anytime',
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 80) / 2,
                        child: _buildDetailItem(
                          'Check-In Time',
                          post.pg.checkInTime,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 80) / 2,
                        child: _buildDetailItem(
                          'Check-Out Time',
                          post.pg.checkOutTime,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 80) / 2,
                        child: _buildDetailItem(
                          'Property Rating',
                          '★ ${post.pg.rating.toStringAsFixed(1)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Vacancy Gallery
                  if (post.images.isNotEmpty) ...[
                    Text(
                      'Vacancy Gallery',
                      style: AppTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: post.images.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              post.images[index],
                              width: 120,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ] else ...[
                    const SizedBox(height: 16),
                  ],

                  // Bottom Action Area
                  if (isEnquired)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.success.withOpacity(0.3),
                        ),
                        boxShadow: AppTheme.softShadow(opacity: 0.05),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppTheme.success,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Enquiry Active!',
                                style: AppTheme.textTheme.titleSmall?.copyWith(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PROPERTY OWNER',
                                style: AppTheme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                post.enquiryData?.owner?.name ?? 'Owner',
                                style: AppTheme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _isPhoneRevealed
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(
                                          0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.phone_rounded,
                                            size: 16,
                                            color: AppTheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            post.enquiryData?.owner?.mobNo1 ??
                                                'N/A',
                                            style: const TextStyle(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: () {
                                        setState(() => _isPhoneRevealed = true);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: const Text(
                                        'Reveal Phone Number',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitEnquiry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Show Interest & Connect',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
  }
}

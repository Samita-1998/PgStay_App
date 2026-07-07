import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';

class PgDetailsScreen extends ConsumerStatefulWidget {
  final String postId;
  const PgDetailsScreen({super.key, required this.postId});

  @override
  ConsumerState<PgDetailsScreen> createState() => _PgDetailsScreenState();
}

class _PgDetailsScreenState extends ConsumerState<PgDetailsScreen> {
  bool _isSubmitting = false;

  Future<void> _submitEnquiry() async {
    setState(() => _isSubmitting = true);
    try {
      final repository = ref.read(pgListingRepositoryProvider);
      await repository.submitEnquiry(widget.postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enquiry submitted successfully! The owner will contact you soon.',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        ref.invalidate(pgDetailsProvider(widget.postId));
        ref.invalidate(pgListProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  IconData _getFacilityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wifi') || lower.contains('internet')) return Icons.wifi;
    if (lower.contains('ac') || lower.contains('air conditioning'))
      return Icons.ac_unit;
    if (lower.contains('food') ||
        lower.contains('mess') ||
        lower.contains('meal'))
      return Icons.restaurant;
    if (lower.contains('laundry') || lower.contains('washing'))
      return Icons.local_laundry_service;
    if (lower.contains('cleaning') || lower.contains('housekeeping'))
      return Icons.cleaning_services;
    if (lower.contains('tv') || lower.contains('television')) return Icons.tv;
    if (lower.contains('gym') || lower.contains('fitness'))
      return Icons.fitness_center;
    if (lower.contains('parking')) return Icons.local_parking;
    if (lower.contains('cctv') || lower.contains('security'))
      return Icons.security;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    final pgDetailsAsync = ref.watch(pgDetailsProvider(widget.postId));
    final facilitiesList = ref.watch(facilitiesListProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: 'Stay Details',
        showBackButton: true,
      ),
      body: SafeArea(
        child: pgDetailsAsync.when(
          data: (post) {
            final isEnquired = post.enquiryData != null;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Top Banner/Details Card ─────────────────────
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
                        border: Border.all(color: AppTheme.surfaceBorder),
                        boxShadow: AppTheme.surfaceShadow,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary.withOpacity(0.06),
                            ),
                            child: const Icon(
                              Icons.home_work_rounded,
                              size: 48,
                              color: AppTheme.accentColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            post.title,
                            style: AppTheme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            post.pg.name,
                            style: AppTheme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSM,
                                  ),
                                  border: Border.all(
                                    color: AppTheme.accentColor.withOpacity(
                                      0.15,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  post.pgType.toUpperCase(),
                                  style: AppTheme.textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppTheme.accentColor,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    post.pg.rating.toStringAsFixed(1),
                                    style: AppTheme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ─── Price & Vacancy Panel ────────────────────────
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 200),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMetricPanel(
                            label: 'STARTING AT',
                            value: '₹${post.minPrice?.toStringAsFixed(0) ?? 0}',
                            subtitle: post.occupancyType.toUpperCase(),
                            valueColor: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildMetricPanel(
                            label: 'VACANT BEDS',
                            value: '${post.vacancyCount}',
                            subtitle: post.vacancyCount > 0
                                ? 'AVAILABLE'
                                : 'FULL',
                            valueColor: post.vacancyCount > 0
                                ? AppTheme.success
                                : AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ─── About Section ────────────────────────────────
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 300),
                    child: _buildSection(
                      title: 'About this Stay',
                      icon: Icons.notes_rounded,
                      child: Text(
                        post.description.isNotEmpty
                            ? post.description
                            : 'A comfortable and secure PG stay with all essential amenities.',
                        style: AppTheme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ─── Location & Rules Section ─────────────────────
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 380),
                    child: _buildSection(
                      title: 'Location & Details',
                      icon: Icons.location_on_rounded,
                      child: Column(
                        children: [
                          if (post.pg.address.landmark.isNotEmpty)
                            _buildDetailRow(
                              'Landmark',
                              post.pg.address.landmark,
                            ),
                          _buildDetailRow('City', post.pg.address.city),
                          if (post.pg.address.state.isNotEmpty)
                            _buildDetailRow('State', post.pg.address.state),
                          if (post.pg.address.pincode > 0)
                            _buildDetailRow(
                              'Pincode',
                              post.pg.address.pincode.toString(),
                            ),
                          _buildDetailRow(
                            'Check Timing',
                            'Check-in: ${post.pg.checkInTime} • Check-out: ${post.pg.checkOutTime}',
                          ),
                          if (post.pg.dueDayOfMonth != null)
                            _buildDetailRow('Rent Due', 'By ${post.pg.dueDayOfMonth}th of month'),
                          if (post.pg.lateFee != null && post.pg.lateFee! > 0)
                            _buildDetailRow('Late Fee', '₹${post.pg.lateFee!.toStringAsFixed(0)}'),
                          if (post.pg.location != null)
                            _buildDetailRow('Coordinates', '${post.pg.location!.coordinates[1].toStringAsFixed(4)}° N, ${post.pg.location!.coordinates[0].toStringAsFixed(4)}° E'),
                          if (post.pg.locationLink != null && post.pg.locationLink!.isNotEmpty)
                            _buildDetailRow('Maps Link', post.pg.locationLink!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ─── Amenities Section ────────────────────────────
                  if (post.pg.facilities.isNotEmpty) ...[
                    StaggeredFadeIn(
                      delay: const Duration(milliseconds: 460),
                      child: _buildSection(
                        title: 'Facilities',
                        icon: Icons.grid_view_rounded,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: post.pg.facilities.map((f) {
                            final facName = facilitiesList.firstWhere((fac) => fac['id'] == f, orElse: () => {'name': f})['name']!;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSM,
                                ),
                                border: Border.all(
                                  color: AppTheme.surfaceBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getFacilityIcon(facName),
                                    size: 16,
                                    color: AppTheme.accentColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    facName,
                                    style: AppTheme.textTheme.labelSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ─── CTA Action Button ────────────────────────────
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 540),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBookNowButton(post),
                        const SizedBox(height: 12),
                        isEnquired
                            ? _buildEnquiryStatus(post)
                            : _buildEnquiryButton(post),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.accentColor),
          ),
          error: (err, stack) => Center(
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
                    'Failed to load details',
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
                    onPressed: () =>
                        ref.refresh(pgDetailsProvider(widget.postId)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
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
    );
  }

  Widget _buildMetricPanel({
    required String label,
    required String value,
    required String subtitle,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: AppTheme.softShadow(opacity: 0.03),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTheme.textTheme.labelSmall?.copyWith(
              color: AppTheme.textHint,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.textTheme.displaySmall?.copyWith(color: valueColor),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTheme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: AppTheme.surfaceShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppTheme.dividerColor, height: 1),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTheme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnquiryStatus(dynamic post) {
    return Container(
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.success.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.success,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Enquiry Registered',
                style: AppTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppTheme.dividerColor, height: 1),
          const SizedBox(height: 14),
          _buildStatusRow(
            'Status',
            post.enquiryData!.status.toUpperCase(),
            AppTheme.success,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Contact',
            post.enquiryData!.owner?.name ?? 'Owner',
            AppTheme.textPrimary,
          ),
          if (post.enquiryData!.owner?.mobNo1 != null) ...[
            const SizedBox(height: 8),
            _buildStatusRow(
              'Owner Phone',
              post.enquiryData!.owner!.mobNo1,
              AppTheme.primary,
            ),
          ],
          if (post.enquiryData!.manager != null) ...[
            const SizedBox(height: 14),
            Divider(color: AppTheme.dividerColor, height: 1),
            const SizedBox(height: 14),
            _buildStatusRow(
              'Manager',
              post.enquiryData!.manager!.name,
              AppTheme.textPrimary,
            ),
            if (post.enquiryData!.manager!.mobNo1.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildStatusRow(
                'Manager Phone',
                post.enquiryData!.manager!.mobNo1,
                AppTheme.primary,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: AppTheme.textTheme.labelSmall?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildEnquiryButton(dynamic post) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting || post.vacancyCount <= 0
            ? null
            : _submitEnquiry,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          shadowColor: AppTheme.primary.withOpacity(0.2),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    post.vacancyCount > 0 ? 'Submit Enquiry' : 'Stay is Full',
                    style: AppTheme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBookNowButton(dynamic post) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: post.vacancyCount <= 0
            ? null
            : () {
                context.push(
                  '/booking-flow',
                  extra: {
                    'pgId': post.pg.id,
                    'pgName': post.pg.name,
                    'roomId': post.id,
                    'roomType': post.title,
                    'pricePerMonth': post.minPrice?.toDouble() ?? 0.0,
                  },
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentColor,
          shadowColor: AppTheme.accentColor.withOpacity(0.3),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              post.vacancyCount > 0 ? 'Book Now' : 'Sold Out',
              style: AppTheme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

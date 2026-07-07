import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/features/pg_listing/screens/add_pg_screen.dart';
import 'package:pgstay/features/pg_listing/screens/inventory_management_screen.dart';
import 'package:pgstay/features/pg_listing/widgets/pg_image_widget.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';

class OwnerPgDetailsScreen extends ConsumerWidget {
  final PgModel pg;

  const OwnerPgDetailsScreen({super.key, required this.pg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.backgroundLight,
      appBar: CustomAppBar(
        title: 'Property Details',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacingLG,
          vertical: context.spacingXS,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(height: context.spacingXL),
            if (pg.images.isNotEmpty) ...[
              _buildImageGallery(context),
              SizedBox(height: context.spacingXL),
            ],
            _buildStatsRow(context),
            SizedBox(height: context.spacingXL),
            _buildOccupancyCard(context),
            SizedBox(height: context.spacingXL),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                      return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildAboutCard(context),
                            SizedBox(height: context.spacingLG),
                            _buildFacilitiesCard(context, ref),
                            if (pg.upiId != null || pg.paymentQrImage != null) ...[
                              SizedBox(height: context.spacingLG),
                              _buildPaymentCard(context),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: context.spacingLG),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildOperationalDetailsCard(context),
                            SizedBox(height: context.spacingLG),
                            _buildManagementCard(context),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildAboutCard(context),
                      SizedBox(height: context.spacingLG),
                      _buildFacilitiesCard(context, ref),
                      if (pg.upiId != null || pg.paymentQrImage != null) ...[
                        SizedBox(height: context.spacingLG),
                        _buildPaymentCard(context),
                      ],
                      SizedBox(height: context.spacingLG),
                      _buildOperationalDetailsCard(context),
                      SizedBox(height: context.spacingLG),
                      _buildManagementCard(context),
                      SizedBox(height: 100),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    return _PgImageCarousel(images: pg.images);
  }

  Widget _buildHeader(BuildContext context) {
    Color typeColor = context.warningColor;
    String lowerType = pg.pgType.toLowerCase();
    if (lowerType.contains('female') || lowerType.contains('girls')) {
      typeColor = context.accentColor;
    } else if (lowerType.contains('male') || lowerType.contains('boys')) {
      typeColor = context.primaryColor;
    } else if (lowerType.contains('unisex')) {
      typeColor = context.successColor;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 600;

        Widget titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pg.name,
                        style: isWide
                            ? context.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              )
                            : context.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                      ),
                      if (pg.pgDisplayId != null) ...[
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ID: ${pg.pgDisplayId}',
                            style: context.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: context.spacingSM),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacingSM,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(context.radiusXL),
                    border: Border.all(color: typeColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    pg.pgType,
                    style: context.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.spacingXS),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: context.textHint,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${pg.address.landmark.isNotEmpty ? pg.address.landmark + ', ' : ''}${pg.address.city}, ${pg.address.state}',
                    style: context.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        );

        Widget buttonsSection = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(
              context,
              'Manage Inventory',
              Icons.domain,
              context.accentColor,
              () {
                context.push('/inventory', extra: pg);
              },
            ),
            SizedBox(width: context.spacingSM),
            _buildButton(
              context,
              'Create Post',
              Icons.post_add_outlined,
              context.primaryColor,
              () {
                context.push('/create-post');
              },
            ),
            SizedBox(width: context.spacingSM),
            _buildButton(
              context,
              'Edit PG',
              Icons.edit_outlined,
              context.successColor,
              () {
                context.push('/add-pg', extra: pg);
              },
            ),
          ],
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: titleSection),
              SizedBox(width: context.spacingLG),
              buttonsSection,
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              SizedBox(height: context.spacingXL),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: buttonsSection,
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.radiusSM),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacingMD,
          vertical: context.spacingXS,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(context.radiusSM),
          boxShadow: context.primaryGlow(opacity: 0.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            SizedBox(width: context.spacingXS),
            Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 600;
        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'TOTAL ROOMS',
                  pg.totalRooms.toString(),
                  Icons.door_front_door_outlined,
                  context.primaryColor,
                ),
              ),
              SizedBox(width: context.spacingMD),
              Expanded(
                child: _buildStatCard(
                  context,
                  'OCCUPIED BEDS',
                  pg.occupiedBeds.toString(),
                  Icons.people_outline,
                  context.warningColor,
                ),
              ),
              SizedBox(width: context.spacingMD),
              Expanded(
                child: _buildStatCard(
                  context,
                  'EMPTY BEDS',
                  pg.emptyBeds.toString(),
                  Icons.check_circle_outline,
                  context.successColor,
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildStatCard(
                context,
                'TOTAL ROOMS',
                pg.totalRooms.toString(),
                Icons.door_front_door_outlined,
                context.primaryColor,
              ),
              SizedBox(height: context.spacingMD),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'OCCUPIED BEDS',
                      pg.occupiedBeds.toString(),
                      Icons.people_outline,
                      context.warningColor,
                    ),
                  ),
                  SizedBox(width: context.spacingMD),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'EMPTY BEDS',
                      pg.emptyBeds.toString(),
                      Icons.check_circle_outline,
                      context.successColor,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color highlightColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceWhite,
        borderRadius: BorderRadius.circular(context.radiusLG),
        border: Border.all(color: context.surfaceBorder, width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.radiusLG - 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 2, color: highlightColor),
            Padding(
              padding: EdgeInsets.all(context.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.textHint,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Icon(
                        icon,
                        size: 20,
                        color: context.textHint.withOpacity(0.5),
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacingSM),
                  Text(
                    value,
                    style: context.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: highlightColor,
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

  Widget _buildOccupancyCard(BuildContext context) {
    final occupancyPercent = pg.totalBeds > 0
        ? pg.occupiedBeds / pg.totalBeds
        : 0.0;
        
    return _buildSectionCard(
      context: context,
      title: 'Occupancy Rate',
      icon: Icons.pie_chart_outline,
      iconColor: context.primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Occupancy',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.textHint,
                ),
              ),
              Text(
                '${(occupancyPercent * 100).toStringAsFixed(0)}%',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: occupancyPercent >= 0.8
                      ? context.errorColor
                      : occupancyPercent >= 0.5
                      ? context.warningColor
                      : context.successColor,
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacingSM),
          ClipRRect(
            borderRadius: BorderRadius.circular(context.radiusSM),
            child: LinearProgressIndicator(
              value: occupancyPercent.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: context.surfaceBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                occupancyPercent >= 0.8
                    ? context.errorColor
                    : occupancyPercent >= 0.5
                    ? context.warningColor
                    : context.successColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'About PG',
      icon: Icons.description_outlined,
      iconColor: context.accentColor,
      child: Text(
        pg.description ?? 'No description available.',
        style: context.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
    );
  }

  Widget _buildFacilitiesCard(BuildContext context, WidgetRef ref) {
    final facilitiesList = ref.watch(facilitiesListProvider).valueOrNull ?? [];
    return _buildSectionCard(
      context: context,
      title: 'Facilities',
      icon: Icons.business_rounded,
      iconColor: context.primaryColor,
      child: pg.facilities.isEmpty
          ? Text('No facilities listed.', style: context.textTheme.bodyMedium)
          : Wrap(
              spacing: context.spacingXS,
              runSpacing: context.spacingXS,
              children: pg.facilities.map((f) {
                final facName = facilitiesList.firstWhere((fac) => fac['id'] == f, orElse: () => {'name': f})['name']!;
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacingSM,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.radiusXS),
                    border: Border.all(
                      color: context.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    facName,
                    style: context.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.primaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildOperationalDetailsCard(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Operational Details',
      icon: null,
      child: Column(
        children: [
          _buildDetailRow(
            context,
            'Check In',
            pg.checkInTime,
            Icons.access_time,
          ),
          Divider(color: AppTheme.dividerColor, height: context.spacingLG),
          _buildDetailRow(
            context,
            'Check Out',
            pg.checkOutTime,
            Icons.access_time,
          ),
          Divider(color: AppTheme.dividerColor, height: context.spacingLG),
          _buildDetailRow(
            context,
            'Rent Due Day',
            'Day ${pg.dueDayOfMonth ?? 10}',
            null,
            valueColor: context.textPrimary,
          ),
          Divider(color: AppTheme.dividerColor, height: context.spacingLG),
          _buildDetailRow(
            context,
            'Late Penalty',
            '₹${pg.lateFee?.toStringAsFixed(0) ?? '0'}',
            null,
            valueColor: context.textPrimary,
          ),
          Divider(color: AppTheme.dividerColor, height: context.spacingLG),
          _buildDetailRow(context, 'Contact No', pg.landline ?? '—', null),
          Divider(color: AppTheme.dividerColor, height: context.spacingLG),
          _buildDetailRow(
            context, 
            'Started Date', 
            (pg.pgStartedDate != null && DateTime.tryParse(pg.pgStartedDate!) != null)
                ? DateFormat('dd MMM yyyy').format(DateTime.parse(pg.pgStartedDate!)) 
                : '—', 
            null,
          ),
          Divider(color: AppTheme.dividerColor, height: context.spacingLG),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rating', style: context.textTheme.bodyMedium),
              Row(
                children: [
                  Icon(Icons.star, color: context.warningColor, size: 16),
                  SizedBox(width: context.spacingXXS),
                  Text(
                    pg.rating.toStringAsFixed(1),
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Management',
      icon: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OWNER',
            style: context.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.textHint,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: context.spacingXS),
          Text(
            pg.ownerName ?? 'Owner',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2),
          Text(pg.ownerMobNo1 ?? '—', style: context.textTheme.bodySmall),
          SizedBox(height: context.spacingXL),
          Text(
            'MANAGER',
            style: context.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.textHint,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: context.spacingXS),
          Text(
            pg.managerName ?? 'Manager',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2),
          Text(pg.managerMobNo1 ?? '—', style: context.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Payment Details',
      icon: Icons.payments_outlined,
      iconColor: context.successColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pg.upiId != null) ...[
            Text(
              'UPI ID',
              style: context.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textHint,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: context.spacingXS),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.surfaceWhite,
                borderRadius: BorderRadius.circular(context.radiusSM),
                border: Border.all(color: context.surfaceBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_scanner_outlined, size: 16, color: context.primaryColor),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pg.upiId!,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (pg.paymentQrImage != null) ...[
            if (pg.upiId != null) SizedBox(height: context.spacingLG),
            Text(
              'QR CODE',
              style: context.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textHint,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: context.spacingXS),
            ClipRRect(
              borderRadius: BorderRadius.circular(context.radiusMD),
              child: Image.network(
                pg.paymentQrImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  color: context.surfaceWhite,
                  child: Center(
                    child: Icon(Icons.broken_image_outlined, color: context.textHint),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData? icon, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: context.textHint),
              SizedBox(width: context.spacingXS),
            ],
            Text(label, style: context.textTheme.bodyMedium),
          ],
        ),
        Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? context.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required Widget child,
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(context.spacingXL),
      decoration: BoxDecoration(
        color: context.surfaceWhite,
        borderRadius: BorderRadius.circular(context.radiusLG),
        border: Border.all(color: context.surfaceBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor ?? context.textPrimary, size: 20),
                SizedBox(width: context.spacingXS),
              ],
              Text(
                title,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacingMD),
          child,
        ],
      ),
    );
  }
}

class _PgImageCarousel extends StatefulWidget {
  final List<String> images;

  const _PgImageCarousel({required this.images});

  @override
  State<_PgImageCarousel> createState() => _PgImageCarouselState();
}

class _PgImageCarouselState extends State<_PgImageCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(context.radiusLG),
                  child: PgImageWidget(
                    imageUrl: widget.images[index],
                    fallbackWidget: Container(
                      color: context.primaryColor.withOpacity(0.1),
                      child: Icon(Icons.apartment_rounded, size: 64, color: context.primaryColor),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.images.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? context.primaryColor
                      : context.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:pgstay/core/widgets/custom_app_bar.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/features/pg_listing/screens/add_pg_screen.dart';
import 'package:pgstay/features/pg_listing/screens/inventory_management_screen.dart';
import 'package:pgstay/features/pg_listing/widgets/pg_image_widget.dart';

class OwnerPgDetailsScreen extends ConsumerStatefulWidget {
  final PgModel pg;

  const OwnerPgDetailsScreen({super.key, required this.pg});

  @override
  ConsumerState<OwnerPgDetailsScreen> createState() =>
      _OwnerPgDetailsScreenState();
}

class _OwnerPgDetailsScreenState extends ConsumerState<OwnerPgDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.pg.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
        if (_currentImageIndex < widget.pg.images.length - 1) {
          _currentImageIndex++;
        } else {
          _currentImageIndex = 0;
        }

        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentImageIndex,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Property Details',
        showBackButton: true,
        showLeading: true,
        pinnedSCurve: true,
        isCompact: true,
        backgroundColor: const Color(0xFFF0F4F8),
        actionWidget: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/add-pg', extra: widget.pg),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: 100 + MediaQuery.of(context).padding.top,
              ),
              child: Column(
                children: [
                  // Image Carousel
                  _buildImageCarousel(),

                  // Content Container
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Action Buttons
                          _buildActionButtons(),
                          const SizedBox(height: 24),

                          // Stats Cards
                          _buildStatsCards(),
                          const SizedBox(height: 24),

                          // Occupancy Section
                          _buildOccupancyCard(),
                          const SizedBox(height: 24),

                          // Two Column Layout for Desktop
                          _buildTwoColumnLayout(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (widget.pg.images.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.apartment_rounded,
                size: 72,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                widget.pg.name,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            SizedBox(
              height: 220,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                },
                children: widget.pg.images.map((url) {
                  return PgImageWidget(imageUrl: url, fit: BoxFit.cover);
                }).toList(),
              ),
            ),

            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                  ),
                ),
              ),
            ),

            // Title and Location overlay
            Positioned(
              bottom: 20,
              left: 20,
              right: 120, // leave space for dots
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.pg.name,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${widget.pg.address.city}, ${widget.pg.address.state}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.95),
                            fontWeight: FontWeight.w500,
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

            // Image Counter
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.image_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_currentImageIndex + 1} / ${widget.pg.images.length}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Dot Indicators
            Positioned(
              bottom: 20,
              right: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  widget.pg.images.length > 6 ? 6 : widget.pg.images.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentImageIndex == index ? 28 : 8,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.pg.name,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildTypeBadge(),
                  const SizedBox(width: 10),
                  if (widget.pg.pgDisplayId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${widget.pg.pgDisplayId}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF667EEA),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
            icon: Icon(
              _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _isFavorite
                  ? const Color(0xFFFF6B6B)
                  : Colors.grey.shade400,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    String type = widget.pg.pgType.toLowerCase();
    Color color;
    if (type.contains('female') || type.contains('girls')) {
      color = const Color(0xFFFF6B6B);
    } else if (type.contains('male') || type.contains('boys')) {
      color = const Color(0xFF4A9EFF);
    } else {
      color = const Color(0xFF4CAF50);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        widget.pg.pgType,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        Icon(
          Icons.location_on_rounded,
          size: 18,
          color: const Color(0xFF667EEA),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${widget.pg.address.city}, ${widget.pg.address.state}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFA94D).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFA94D),
                size: 14,
              ),
              const SizedBox(width: 2),
              Text(
                widget.pg.rating.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFFA94D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildGlassButton(
            'Inventory',
            Icons.inventory_2_outlined,
            const Color(0xFF667EEA),
            () => context.push('/inventory', extra: widget.pg),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildGlassButton(
            'Create Post',
            Icons.post_add_outlined,
            const Color(0xFFFF6B6B),
            () => context.push('/create-post'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildGlassButton(
            'Edit PG',
            Icons.edit_outlined,
            const Color(0xFF4CAF50),
            () => context.push('/add-pg', extra: widget.pg),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final stats = [
      {
        'label': 'Total Rooms',
        'value': widget.pg.totalRooms.toString(),
        'icon': Icons.door_front_door_outlined,
      },
      {
        'label': 'Occupied',
        'value': widget.pg.occupiedBeds.toString(),
        'icon': Icons.people_outline,
      },
      {
        'label': 'Available',
        'value': widget.pg.emptyBeds.toString(),
        'icon': Icons.check_circle_outline,
      },
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: stats.indexOf(stat) < stats.length - 1 ? 10 : 0,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  stat['icon'] as IconData,
                  color: const Color(0xFF667EEA),
                  size: 20,
                ),
                const SizedBox(height: 6),
                Text(
                  stat['value'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  stat['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOccupancyCard() {
    final occupancyPercent = widget.pg.totalBeds > 0
        ? widget.pg.occupiedBeds / widget.pg.totalBeds
        : 0.0;

    Color color = occupancyPercent >= 0.8
        ? const Color(0xFFFF6B6B)
        : occupancyPercent >= 0.5
        ? const Color(0xFFFFA94D)
        : const Color(0xFF4CAF50);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.pie_chart_outline,
                      size: 18,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Occupancy Rate',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(occupancyPercent * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: occupancyPercent.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat(
                'Occupied',
                widget.pg.occupiedBeds.toString(),
                const Color(0xFFFF6B6B),
              ),
              _buildMiniStat(
                'Available',
                widget.pg.emptyBeds.toString(),
                const Color(0xFF4CAF50),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTwoColumnLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildAboutCard(),
                    const SizedBox(height: 16),
                    _buildFacilitiesCard(),
                    if (widget.pg.upiId != null ||
                        widget.pg.paymentQrImage != null) ...[
                      const SizedBox(height: 16),
                      _buildPaymentCard(),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildDetailsCard(),
                    const SizedBox(height: 16),
                    _buildManagementCard(),
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            _buildAboutCard(),
            const SizedBox(height: 16),
            _buildFacilitiesCard(),
            if (widget.pg.upiId != null ||
                widget.pg.paymentQrImage != null) ...[
              const SizedBox(height: 16),
              _buildPaymentCard(),
            ],
            const SizedBox(height: 16),
            _buildDetailsCard(),
            const SizedBox(height: 16),
            _buildManagementCard(),
          ],
        );
      },
    );
  }

  Widget _buildAboutCard() {
    return _buildModernCard(
      icon: Icons.description_outlined,
      title: 'About',
      iconColor: const Color(0xFF667EEA),
      child: Text(
        widget.pg.description ?? 'No description available.',
        style: GoogleFonts.inter(
          fontSize: 14,
          height: 1.8,
          color: Colors.grey.shade700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildFacilitiesCard() {
    final facilitiesList = ref.watch(facilitiesListProvider).valueOrNull ?? [];
    return _buildModernCard(
      icon: Icons.business_rounded,
      title: 'Facilities',
      iconColor: const Color(0xFF667EEA),
      child: widget.pg.facilities.isEmpty
          ? Text(
              'No facilities listed.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.pg.facilities.map((f) {
                final facName = facilitiesList.firstWhere(
                  (fac) => fac['id'] == f,
                  orElse: () => {'name': f},
                )['name']!;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    facName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF667EEA),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildDetailsCard() {
    final details = [
      {
        'label': 'Check In',
        'value': widget.pg.checkInTime,
        'icon': Icons.access_time_outlined,
      },
      {
        'label': 'Check Out',
        'value': widget.pg.checkOutTime,
        'icon': Icons.access_time_outlined,
      },
      {
        'label': 'Rent Due',
        'value': 'Day ${widget.pg.dueDayOfMonth ?? 10}',
        'icon': Icons.calendar_month_outlined,
      },
      {
        'label': 'Late Fee',
        'value': '₹${widget.pg.lateFee?.toStringAsFixed(0) ?? '0'}',
        'icon': Icons.currency_rupee_outlined,
      },
      {
        'label': 'Contact',
        'value': widget.pg.landline ?? '—',
        'icon': Icons.phone_outlined,
      },
      {
        'label': 'Started',
        'value':
            widget.pg.pgStartedDate != null &&
                DateTime.tryParse(widget.pg.pgStartedDate!) != null
            ? DateFormat(
                'dd MMM yyyy',
              ).format(DateTime.parse(widget.pg.pgStartedDate!))
            : '—',
        'icon': Icons.event_outlined,
      },
    ];

    return _buildModernCard(
      icon: Icons.settings_outlined,
      title: 'Details',
      iconColor: const Color(0xFFFF6B6B),
      child: Column(
        children: details.map((detail) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  detail['icon'] as IconData,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Text(
                    detail['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    detail['value'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildManagementCard() {
    return _buildModernCard(
      icon: Icons.people_outline,
      title: 'Management',
      iconColor: const Color(0xFF4CAF50),
      child: Column(
        children: [
          _buildPersonCard(
            'Owner',
            widget.pg.ownerName ?? 'Owner',
            widget.pg.ownerMobNo1 ?? '—',
            const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 12),
          _buildPersonCard(
            'Manager',
            widget.pg.managerName ?? 'Manager',
            widget.pg.managerMobNo1 ?? '—',
            const Color(0xFFFF6B6B),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonCard(String role, String name, String phone, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  phone,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_outlined,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    if (widget.pg.upiId == null && widget.pg.paymentQrImage == null) {
      return const SizedBox.shrink();
    }

    return _buildModernCard(
      icon: Icons.payments_outlined,
      title: 'Payment',
      iconColor: const Color(0xFF4CAF50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.pg.upiId != null) ...[
            Text(
              'UPI ID',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner_outlined,
                    size: 18,
                    color: const Color(0xFF667EEA),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.pg.upiId!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.copy_outlined,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ],
          if (widget.pg.paymentQrImage != null) ...[
            if (widget.pg.upiId != null) const SizedBox(height: 12),
            Text(
              'QR Code',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: PgImageWidget(
                    imageUrl: widget.pg.paymentQrImage!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ] else ...[
            if (widget.pg.upiId != null) const SizedBox(height: 12),
            Text(
              'QR Code',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner_outlined,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No QR code available',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernCard({
    required IconData icon,
    required String title,
    required Widget child,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

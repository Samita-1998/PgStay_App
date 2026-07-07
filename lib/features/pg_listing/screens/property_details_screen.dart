import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final PgModel pg;
  const PropertyDetailsScreen({super.key, required this.pg});

  Color get _typeColor {
    switch (pg.pgType.toLowerCase()) {
      case 'female':
      case 'girls':
        return Colors.pinkAccent;
      case 'male':
      case 'boys':
        return Colors.blueAccent;
      case 'co-living':
      case 'coliving':
        return Colors.deepPurpleAccent;
      case 'unisex':
        return Colors.teal;
      default:
        return AppTheme.accentColor;
    }
  }

  IconData _getFacilityIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('wifi') || lower.contains('internet')) return Icons.wifi;
    if (lower.contains('ac') || lower.contains('air')) return Icons.ac_unit;
    if (lower.contains('food') || lower.contains('mess') || lower.contains('meal')) return Icons.restaurant;
    if (lower.contains('laundry') || lower.contains('washing')) return Icons.local_laundry_service;
    if (lower.contains('cleaning') || lower.contains('housekeeping')) return Icons.cleaning_services;
    if (lower.contains('tv') || lower.contains('television')) return Icons.tv;
    if (lower.contains('gym') || lower.contains('fitness')) return Icons.fitness_center;
    if (lower.contains('parking')) return Icons.local_parking;
    if (lower.contains('cctv') || lower.contains('security')) return Icons.security;
    if (lower.contains('geyser') || lower.contains('hot water')) return Icons.hot_tub;
    if (lower.contains('power') || lower.contains('backup')) return Icons.electrical_services;
    if (lower.contains('fridge') || lower.contains('refrigerator')) return Icons.kitchen;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = pg.images.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── Collapsible Header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppTheme.textPrimary),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: hasImages
                  ? Image.network(pg.images.first, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderHeader())
                  : _buildPlaceholderHeader(),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Title card ────────────────────────────────────────────
                StaggeredFadeIn(
                  delay: const Duration(milliseconds: 60),
                  child: _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: _typeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                pg.pgType.toUpperCase(),
                                style: TextStyle(
                                  color: _typeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              pg.rating.toStringAsFixed(1),
                              style: AppTheme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          pg.name,
                          style: AppTheme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: AppTheme.textHint, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${pg.address.landmark}, ${pg.address.city}, '
                                '${pg.address.state} - ${pg.address.pincode}',
                                style: AppTheme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                        if (pg.isActive) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Active & Accepting Tenants',
                                style: AppTheme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Inventory Stats ────────────────────────────────────────
                StaggeredFadeIn(
                  delay: const Duration(milliseconds: 120),
                  child: _SectionHeader(
                      icon: Icons.bed_rounded, label: 'Property Inventory'),
                ),
                const SizedBox(height: 10),
                StaggeredFadeIn(
                  delay: const Duration(milliseconds: 140),
                  child: Row(
                    children: [
                      Expanded(
                          child: _StatTile(
                              label: 'Rooms',
                              value: '${pg.totalRooms}',
                              color: AppTheme.primary)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatTile(
                              label: 'Total Beds',
                              value: '${pg.totalBeds}',
                              color: AppTheme.accentColor)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatTile(
                              label: 'Occupied',
                              value: '${pg.occupiedBeds}',
                              color: AppTheme.error)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatTile(
                              label: 'Vacant',
                              value: '${pg.emptyBeds}',
                              color: pg.emptyBeds > 0
                                  ? AppTheme.success
                                  : AppTheme.error)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Owner Info ─────────────────────────────────────────────
                if (pg.ownerName != null || pg.ownerMobNo1 != null) ...[
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 180),
                    child: _SectionHeader(
                        icon: Icons.person_rounded, label: 'Owner Details'),
                  ),
                  const SizedBox(height: 10),
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 200),
                    child: _Card(
                      child: _ContactRow(
                        name: pg.ownerName ?? 'Owner',
                        role: 'OWNER',
                        roleColor: AppTheme.primary,
                        phone: pg.ownerMobNo1,
                        email: pg.ownerEmail,
                        icon: Icons.person_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Manager Info ───────────────────────────────────────────
                if (pg.managerName != null || pg.managerMobNo1 != null) ...[
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 240),
                    child: _SectionHeader(
                        icon: Icons.manage_accounts_rounded,
                        label: 'Manager Details'),
                  ),
                  const SizedBox(height: 10),
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 260),
                    child: _Card(
                      child: _ContactRow(
                        name: pg.managerName ?? 'Manager',
                        role: 'MANAGER',
                        roleColor: Colors.deepOrangeAccent,
                        phone: pg.managerMobNo1,
                        phone2: (pg.managerMobNo2 != null &&
                                pg.managerMobNo2!.isNotEmpty &&
                                pg.managerMobNo2 != 'null')
                            ? pg.managerMobNo2
                            : null,
                        email: pg.managerEmail,
                        icon: Icons.manage_accounts_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Description ────────────────────────────────────────────
                if (pg.description != null && pg.description!.isNotEmpty) ...[
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 300),
                    child: _SectionHeader(
                        icon: Icons.notes_rounded,
                        label: 'About this Property'),
                  ),
                  const SizedBox(height: 10),
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 320),
                    child: _Card(
                      child: Text(
                        pg.description!,
                        style: AppTheme.textTheme.bodyMedium
                            ?.copyWith(height: 1.65),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Location Details ───────────────────────────────────────
                StaggeredFadeIn(
                  delay: const Duration(milliseconds: 360),
                  child: _SectionHeader(
                      icon: Icons.location_city_rounded,
                      label: 'Location Details'),
                ),
                const SizedBox(height: 10),
                StaggeredFadeIn(
                  delay: const Duration(milliseconds: 380),
                  child: _Card(
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.location_on_rounded,
                          label: 'Address',
                          value:
                              '${pg.address.city}, ${pg.address.state}, ${pg.address.country}',
                        ),
                        if (pg.address.landmark.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.place_rounded,
                            label: 'Landmark',
                            value: pg.address.landmark,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.pin_drop_rounded,
                          label: 'Pincode',
                          value: '${pg.address.pincode}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Facilities ─────────────────────────────────────────────
                if (pg.facilities.isNotEmpty) ...[
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 420),
                    child: _SectionHeader(
                        icon: Icons.grid_view_rounded,
                        label: 'Facilities & Amenities'),
                  ),
                  const SizedBox(height: 10),
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 440),
                    child: _Card(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: pg.facilities.map((fac) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppTheme.primary.withOpacity(0.15)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getFacilityIcon(fac),
                                    size: 15, color: AppTheme.primary),
                                const SizedBox(width: 7),
                                Text(
                                  fac,
                                  style: AppTheme.textTheme.labelMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primary),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Additional Info ────────────────────────────────────────
                StaggeredFadeIn(
                  delay: const Duration(milliseconds: 480),
                  child: _SectionHeader(
                      icon: Icons.info_outline_rounded,
                      label: 'Additional Information'),
                ),
                const SizedBox(height: 10),
                StaggeredFadeIn(
                  delay: const Duration(milliseconds: 500),
                  child: _Card(
                    child: Column(
                      children: [
                        if (pg.dueDayOfMonth != null)
                          _InfoRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Rent Due Date',
                            value: '${pg.dueDayOfMonth}${_ordinal(pg.dueDayOfMonth!)} of every month',
                          ),
                        if (pg.checkInTime.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.login_rounded,
                            label: 'Check-in Time',
                            value: pg.checkInTime,
                          ),
                        ],
                        if (pg.checkOutTime.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.logout_rounded,
                            label: 'Check-out Time',
                            value: pg.checkOutTime,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Widget _buildPlaceholderHeader() {
    return Container(
      color: AppTheme.primary.withOpacity(0.08),
      child: Center(
        child: Icon(
          Icons.apartment_rounded,
          size: 100,
          color: AppTheme.primary.withOpacity(0.25),
        ),
      ),
    );
  }
}

// ── Reusable widgets ─────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: AppTheme.surfaceShadow,
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTheme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatTile(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.textTheme.titleLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final String name;
  final String role;
  final Color roleColor;
  final String? phone;
  final String? phone2;
  final String? email;
  final IconData icon;
  const _ContactRow({
    required this.name,
    required this.role,
    required this.roleColor,
    this.phone,
    this.phone2,
    this.email,
    required this.icon,
  });

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: roleColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: roleColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: AppTheme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              if (phone != null && phone!.isNotEmpty) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _copyToClipboard(context, phone!),
                  child: Row(
                    children: [
                      Icon(Icons.phone_rounded,
                          size: 13, color: AppTheme.textHint),
                      const SizedBox(width: 6),
                      Text(
                        phone!,
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.copy_rounded,
                          size: 12, color: AppTheme.textHint),
                    ],
                  ),
                ),
              ],
              if (phone2 != null && phone2!.isNotEmpty) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _copyToClipboard(context, phone2!),
                  child: Row(
                    children: [
                      Icon(Icons.phone_rounded,
                          size: 13, color: AppTheme.textHint),
                      const SizedBox(width: 6),
                      Text(
                        phone2!,
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.copy_rounded,
                          size: 12, color: AppTheme.textHint),
                    ],
                  ),
                ),
              ],
              if (email != null && email!.isNotEmpty) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _copyToClipboard(context, email!),
                  child: Row(
                    children: [
                      Icon(Icons.email_outlined,
                          size: 13, color: AppTheme.textHint),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          email!,
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.copy_rounded,
                          size: 12, color: AppTheme.textHint),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.textTheme.labelSmall
                    ?.copyWith(color: AppTheme.textHint, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

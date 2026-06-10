import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/screens/add_pg_screen.dart';
import 'package:pgstay/features/pg_listing/screens/inventory_management_screen.dart';

class OwnerPgDetailsScreen extends StatelessWidget {
  final PgModel pg;

  const OwnerPgDetailsScreen({super.key, required this.pg});

  // Dark Theme Colors based on the UI
  static const Color bgColor = Color(0xFF0F111A);
  static const Color cardColor = Color(0xFF1A1D2B);
  static const Color borderColor = Color(0xFF2A2E3D);
  static const Color textWhite = Colors.white;
  static const Color textGray = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textGray),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildStatsRow(context),
            const SizedBox(height: 32),
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildAboutCard(),
                          const SizedBox(height: 24),
                          _buildFacilitiesCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildOperationalDetailsCard(),
                          const SizedBox(height: 24),
                          _buildManagementCard(),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildAboutCard(),
                    const SizedBox(height: 24),
                    _buildFacilitiesCard(),
                    const SizedBox(height: 24),
                    _buildOperationalDetailsCard(),
                    const SizedBox(height: 24),
                    _buildManagementCard(),
                    const SizedBox(height: 40),
                  ],
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    Color typeColor = Colors.orange;
    String lowerType = pg.pgType.toLowerCase();
    if (lowerType.contains('female') || lowerType.contains('girls')) {
      typeColor = Colors.purple.shade400;
    } else if (lowerType.contains('male') || lowerType.contains('boys')) {
      typeColor = Colors.indigo.shade400;
    } else if (lowerType.contains('unisex')) {
      typeColor = Colors.teal;
    }

    return LayoutBuilder(builder: (context, constraints) {
      bool isWide = constraints.maxWidth > 600;

      Widget titleSection = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pg.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isWide ? 28 : 24,
                    fontWeight: FontWeight.w800,
                    color: textWhite,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: typeColor.withOpacity(0.3)),
                ),
                child: Text(
                  pg.pgType,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: textGray),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${pg.address.landmark.isNotEmpty ? pg.address.landmark + ', ' : ''}${pg.address.city}, ${pg.address.state}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: textGray,
                  ),
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
            'Manage Inventory',
            Icons.domain,
            const Color(0xFF9E77ED),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InventoryManagementScreen(pg: pg),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          _buildButton(
            'Edit PG',
            Icons.edit_outlined,
            const Color(0xFF10B981),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddPgScreen(pgToEdit: pg),
                ),
              );
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
            const SizedBox(width: 24),
            buttonsSection,
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleSection,
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: buttonsSection,
            ),
          ],
        );
      }
    });
  }

  Widget _buildButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
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
    return LayoutBuilder(builder: (context, constraints) {
      bool isWide = constraints.maxWidth > 600;
      if (isWide) {
        return Row(
          children: [
            Expanded(
                child: _buildStatCard('TOTAL ROOMS', pg.totalRooms.toString(),
                    Icons.door_front_door_outlined, const Color(0xFF6366F1))),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard('OCCUPIED BEDS',
                    pg.occupiedBeds.toString(), Icons.people_outline,
                    const Color(0xFFF59E0B))),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard('EMPTY BEDS', pg.emptyBeds.toString(),
                    Icons.check_circle_outline, const Color(0xFF10B981))),
          ],
        );
      } else {
        return Column(
          children: [
            _buildStatCard('TOTAL ROOMS', pg.totalRooms.toString(),
                Icons.door_front_door_outlined, const Color(0xFF6366F1)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildStatCard('OCCUPIED BEDS',
                        pg.occupiedBeds.toString(), Icons.people_outline,
                        const Color(0xFFF59E0B))),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildStatCard('EMPTY BEDS', pg.emptyBeds.toString(),
                        Icons.check_circle_outline, const Color(0xFF10B981))),
              ],
            ),
          ],
        );
      }
    });
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color highlightColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 2, color: highlightColor),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textGray,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Icon(icon, size: 20, color: textGray.withOpacity(0.5)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
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

  Widget _buildAboutCard() {
    return _buildSectionCard(
      title: 'About PG',
      icon: Icons.description_outlined,
      iconColor: const Color(0xFF9E77ED),
      child: Text(
        'Quiet and peaceful environment perfect for students.',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: textGray,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildFacilitiesCard() {
    return _buildSectionCard(
      title: 'Facilities',
      icon: Icons.business_rounded,
      iconColor: const Color(0xFF6366F1),
      child: pg.facilities.isEmpty
          ? Text(
              'No facilities listed.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: textGray,
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pg.facilities.map((f) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.2)),
                  ),
                  child: Text(
                    f,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildOperationalDetailsCard() {
    return _buildSectionCard(
      title: 'Operational Details',
      icon: null,
      child: Column(
        children: [
          _buildDetailRow('Check In', pg.checkInTime, Icons.access_time),
          const Divider(color: borderColor, height: 24),
          _buildDetailRow('Check Out', pg.checkOutTime, Icons.access_time),
          const Divider(color: borderColor, height: 24),
          _buildDetailRow('Rent Due Day', 'Day 10', null,
              valueColor: textWhite),
          const Divider(color: borderColor, height: 24),
          _buildDetailRow('Late Penalty', '₹0', null, valueColor: textWhite),
          const Divider(color: borderColor, height: 24),
          _buildDetailRow('Contact No', '—', null),
          const Divider(color: borderColor, height: 24),
          _buildDetailRow('Started Date', '—', null),
          const Divider(color: borderColor, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rating',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: textGray,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    pg.rating.toStringAsFixed(1),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textWhite,
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

  Widget _buildManagementCard() {
    return _buildSectionCard(
      title: 'Management',
      icon: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OWNER',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textGray,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'sagar thakare', // Hardcoded as per the image for now
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textWhite,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '9123456789',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: textGray,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'MANAGER',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textGray,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pg.managerName ?? 'Manager',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textWhite,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '9876543210',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData? icon,
      {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: textGray),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: textGray,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? textWhite,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
      {required String title,
      required Widget child,
      IconData? icon,
      Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor ?? textWhite, size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

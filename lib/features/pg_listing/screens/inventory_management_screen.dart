import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class BedData {
  final String id;
  final String bedNumber;
  final String position;
  final double price;
  final String status;
  final String? tenantName;
  final String? tenantMobile;
  final String? vehicleType;
  final String? vehicleNumber;

  BedData({
    required this.id,
    required this.bedNumber,
    required this.position,
    required this.price,
    required this.status,
    this.tenantName,
    this.tenantMobile,
    this.vehicleType,
    this.vehicleNumber,
  });

  factory BedData.fromJson(Map<String, dynamic> json) {
    final user = json['userId'];
    final tName =
        json['tenantName'] ??
        (user is Map ? (user['name'] ?? user['fullName']) : null)?.toString() ??
        (user != null ? 'Occupied' : null);

    final tMobile =
        json['tenantMobile'] ??
        (user is Map
                ? (user['mobNo1'] ?? user['mobileNumber'] ?? user['phone'])
                : null)
            ?.toString();

    final vType = (user is Map) ? user['vehicleType']?.toString() : null;
    final vNum = (user is Map) ? user['vehicleNumber']?.toString() : null;

    return BedData(
      id: json['_id'] ?? '',
      bedNumber: json['bedNumber'] ?? '',
      position: json['position'] ?? 'Standard',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'available',
      tenantName: tName,
      tenantMobile: tMobile,
      vehicleType: vType,
      vehicleNumber: vNum,
    );
  }
}

class RoomData {
  final String id;
  final String roomNumber;
  final String floor;
  final String roomType;
  final int sharingType;
  final String pgId;
  final List<BedData> beds;

  RoomData({
    required this.id,
    required this.roomNumber,
    required this.floor,
    required this.roomType,
    required this.sharingType,
    required this.pgId,
    required this.beds,
  });

  factory RoomData.fromJson(Map<String, dynamic> json) {
    List<BedData> parsedBeds = [];
    if (json['beds'] != null) {
      parsedBeds = (json['beds'] as List)
          .map((b) => BedData.fromJson(b))
          .toList();
    }
    return RoomData(
      id: json['_id'] ?? '',
      roomNumber: json['roomNumber']?.toString() ?? '',
      floor: json['floor']?.toString() ?? '1',
      roomType: json['roomType'] ?? 'Non-AC',
      sharingType: json['sharingType'] ?? parsedBeds.length,
      pgId: json['pgId'] ?? '',
      beds: parsedBeds,
    );
  }
}

class InventoryManagementScreen extends ConsumerStatefulWidget {
  final PgModel pg;

  const InventoryManagementScreen({super.key, required this.pg});

  @override
  ConsumerState<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState
    extends ConsumerState<InventoryManagementScreen> {
  String _searchQuery = '';
  String _selectedType = 'All Types';
  String _selectedStatus = 'All Status';

  @override
  Widget build(BuildContext context) {
    final roomsAsyncValue = ref.watch(pgRoomsProvider(widget.pg.id));

    return Scaffold(
      backgroundColor: context.backgroundLight,
      appBar: CustomAppBar(
        title: 'Inventory',
        showBackButton: true,
        pinnedSCurve: true,
        isCompact: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) =>
                _AddRoomDialog(pgId: widget.pg.id, pgName: widget.pg.name),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Room'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndFilterPanel(context),
            Expanded(
              child: roomsAsyncValue.when(
                data: (data) {
                  List<RoomData> rooms = data
                      .map((json) => RoomData.fromJson(json))
                      .where((room) {
                        if (_selectedType != 'All Types' &&
                            room.roomType != _selectedType) {
                          return false;
                        }
                        if (_selectedStatus == 'Occupancy') {
                          if (!room.beds.any((b) => b.status == 'occupied'))
                            return false;
                        } else if (_selectedStatus == 'Vacancy') {
                          if (!room.beds.any((b) => b.status == 'available'))
                            return false;
                        }
                        if (_searchQuery.isNotEmpty) {
                          final q = _searchQuery.toLowerCase();
                          final matchRoom = room.roomNumber
                              .toLowerCase()
                              .contains(q);
                          final matchBed = room.beds.any(
                            (b) =>
                                b.bedNumber.toLowerCase().contains(q) ||
                                (b.tenantName?.toLowerCase().contains(q) ??
                                    false),
                          );
                          if (!matchRoom && !matchBed) return false;
                        }
                        return true;
                      })
                      .toList();

                  rooms.sort((a, b) {
                    final aNum =
                        int.tryParse(
                          a.roomNumber.replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
                        0;
                    final bNum =
                        int.tryParse(
                          b.roomNumber.replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
                        0;
                    if (aNum != bNum) return aNum.compareTo(bNum);
                    return a.roomNumber.compareTo(b.roomNumber);
                  });

                  if (rooms.isEmpty) {
                    return Center(
                      child: Text(
                        'No rooms found.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.textHint,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.only(
                      left: context.spacingMD,
                      right: context.spacingMD,
                      top: context.spacingMD,
                      bottom: 100,
                    ),
                    itemCount: rooms.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: context.spacingMD),
                    itemBuilder: (context, index) {
                      return _buildRoomCard(context, rooms[index]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'Failed to load inventory.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.errorColor,
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

  Widget _buildSearchAndFilterPanel(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacingMD),
      child: Container(
        padding: EdgeInsets.all(context.spacingSM),
        decoration: BoxDecoration(
          color: context.surfaceWhite,
          borderRadius: BorderRadius.circular(context.radiusLG),
          border: Border.all(color: context.surfaceBorder),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: context.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search Room, Bed, Tenant...',
                hintStyle: context.textTheme.bodySmall,
                prefixIcon: Icon(
                  Icons.search,
                  color: context.textHint,
                  size: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.radiusSM),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: context.backgroundLight,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.spacingSM,
                  vertical: 0,
                ),
              ),
            ),
            SizedBox(height: context.spacingSM),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    context,
                    _selectedType,
                    ['All Types', 'AC', 'Non-AC'],
                    (val) => setState(() => _selectedType = val!),
                  ),
                ),
                SizedBox(width: context.spacingSM),
                Expanded(
                  child: _buildDropdown(
                    context,
                    _selectedStatus,
                    ['All Status', 'Occupancy', 'Vacancy'],
                    (val) => setState(() => _selectedStatus = val!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.spacingSM),
      decoration: BoxDecoration(
        color: context.backgroundLight,
        borderRadius: BorderRadius.circular(context.radiusSM),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: context.textHint,
            size: 16,
          ),
          dropdownColor: context.surfaceWhite,
          style: context.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
          onChanged: onChanged,
          items: items.map((e) {
            return DropdownMenuItem(value: e, child: Text(e));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, RoomData room) {
    int availableBeds = room.beds.where((b) => b.status == 'available').length;
    bool isFull = availableBeds == 0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isFull
              ? context.warningColor.withOpacity(0.2)
              : context.primaryColor.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Room Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacingMD,
              vertical: context.spacingMD,
            ),
            decoration: BoxDecoration(
              color: isFull
                  ? context.warningColor.withOpacity(0.05)
                  : context.primaryColor.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: context.surfaceBorder, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.meeting_room_rounded,
                        color: isFull
                            ? context.warningColor
                            : context.primaryColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: context.spacingSM),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room ${room.roomNumber}',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Floor ${room.floor} • ${room.roomType}',
                          style: context.textTheme.labelMedium?.copyWith(
                            color: context.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: context.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        '${room.beds.length} Beds',
                        style: context.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildIconButton(
                      context,
                      icon: Icons.edit_rounded,
                      color: context.primaryColor,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => _EditRoomDialog(
                            room: room,
                            pgId: widget.pg.id,
                            pgName: widget.pg.name,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    _buildIconButton(
                      context,
                      icon: Icons.delete_outline_rounded,
                      color: context.errorColor,
                      onTap: () {
                        // Delete logic
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: context.surfaceWhite,
                            title: Text(
                              'Delete Room',
                              style: context.textTheme.headlineSmall,
                            ),
                            content: Text(
                              'Are you sure you want to delete this room?',
                              style: context.textTheme.bodyMedium,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Cancel',
                                  style: context.textTheme.labelMedium
                                      ?.copyWith(color: context.textHint),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  try {
                                    await ref
                                        .read(pgListingRepositoryProvider)
                                        .deleteRoom(room.id);
                                    ref.invalidate(
                                      pgRoomsProvider(widget.pg.id),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Room deleted successfully',
                                            style: context.textTheme.bodyMedium
                                                ?.copyWith(color: Colors.white),
                                          ),
                                          backgroundColor: context.primaryColor,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(e.toString()),
                                          backgroundColor: context.errorColor,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  'Delete',
                                  style: context.textTheme.labelMedium
                                      ?.copyWith(color: context.errorColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bed List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(context.spacingMD),
            itemCount: room.beds.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: context.spacingSM),
            itemBuilder: (context, index) {
              return _BedItemTile(
                room: room,
                bed: room.beds[index],
                pg: widget.pg,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _BedItemTile extends ConsumerWidget {
  final RoomData room;
  final BedData bed;
  final PgModel pg;

  const _BedItemTile({required this.room, required this.bed, required this.pg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isAvailable = bed.status == 'available';
    String bedLetter = bed.bedNumber.contains('-')
        ? bed.bedNumber.split('-').last
        : bed.bedNumber;
    Color statusColor = isAvailable
        ? context.successColor
        : context.primaryColor;

    return Container(
      padding: EdgeInsets.all(context.spacingSM),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.bed_outlined, color: statusColor, size: 22),
          ),
          SizedBox(width: context.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Bed $bedLetter',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${bed.price.toStringAsFixed(0)} /mo',
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: context.textHint,
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        bed.position,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAvailable ? 'Available' : 'Occupied',
                        style: context.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: context.spacingSM),
          InkWell(
            onTap: () {
              if (isAvailable) {
                showDialog(
                  context: context,
                  builder: (context) => _AssignTenantDialog(
                    pgId: pg.id,
                    pgName: pg.name,
                    room: room,
                    bed: bed,
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) =>
                      _OccupiedBedDialog(room: room, bed: bed, pg: pg),
                );
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isAvailable
                    ? Icons.person_add_alt_1_rounded
                    : Icons.visibility_outlined,
                color: statusColor,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OccupiedBedDialog extends ConsumerWidget {
  final RoomData room;
  final BedData bed;
  final PgModel pg;

  const _OccupiedBedDialog({
    required this.room,
    required this.bed,
    required this.pg,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String initials = bed.tenantName?.isNotEmpty == true
        ? bed.tenantName!
              .trim()
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'O';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: context.surfaceWhite,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bed Details',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.textHint.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.primaryColor.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              bed.tenantName ?? 'Occupied',
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.backgroundLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.surfaceBorder),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    icon: Icons.meeting_room_outlined,
                    label: 'Room',
                    value: room.roomNumber,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _buildDetailRow(
                    context,
                    icon: Icons.bed_outlined,
                    label: 'Bed',
                    value: bed.bedNumber.contains('-')
                        ? bed.bedNumber.split('-').last
                        : bed.bedNumber,
                  ),
                  if (bed.tenantMobile != null &&
                      bed.tenantMobile!.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: context.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: context.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Mobile',
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () async {
                            final uri = Uri.parse('tel:${bed.tenantMobile}');
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: context.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  bed.tenantMobile!,
                                  style: context.textTheme.labelMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: context.primaryColor,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (bed.vehicleNumber != null &&
                      bed.vehicleNumber!.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _buildDetailRow(
                      context,
                      icon:
                          (bed.vehicleType?.toLowerCase() == 'bike' ||
                              bed.vehicleType?.toLowerCase() == '2-wheeler')
                          ? Icons.motorcycle_outlined
                          : Icons.directions_car_outlined,
                      label: 'Vehicle',
                      value: bed.vehicleNumber!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: context.surfaceWhite,
                    title: Text(
                      'Vacate Bed',
                      style: context.textTheme.headlineSmall,
                    ),
                    content: Text(
                      'Are you sure you want to vacate this bed?',
                      style: context.textTheme.bodyMedium,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: context.textTheme.labelMedium?.copyWith(
                            color: context.textHint,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                          try {
                            await ref
                                .read(pgListingRepositoryProvider)
                                .unassignBedFromTenant(bed.id);
                            ref.invalidate(pgRoomsProvider(pg.id));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Bed vacated successfully',
                                    style: context.textTheme.bodyMedium
                                        ?.copyWith(color: Colors.white),
                                  ),
                                  backgroundColor: context.primaryColor,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: context.errorColor,
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          'Vacate',
                          style: context.textTheme.labelMedium?.copyWith(
                            color: context.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(
                Icons.person_remove_rounded,
                size: 18,
                color: context.errorColor,
              ),
              label: Text(
                'Vacate Bed',
                style: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.errorColor,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.errorColor.withOpacity(0.1),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: context.primaryColor),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: context.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _AssignTenantDialog extends ConsumerStatefulWidget {
  final String pgId;
  final String pgName;
  final RoomData room;
  final BedData bed;

  const _AssignTenantDialog({
    required this.pgId,
    required this.pgName,
    required this.room,
    required this.bed,
  });

  @override
  ConsumerState<_AssignTenantDialog> createState() =>
      _AssignTenantDialogState();
}

class _AssignTenantDialogState extends ConsumerState<_AssignTenantDialog> {
  List<Map<String, dynamic>>? _eligibleTenants;
  String? _selectedTenantId;
  DateTime _checkInDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTenants();
  }

  Future<void> _fetchTenants() async {
    final repo = ref.read(pgListingRepositoryProvider);
    final tenants = await repo.fetchEligibleTenants(widget.pgId);
    if (mounted) {
      setState(() {
        _eligibleTenants = tenants;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.primaryColor,
              surface: context.surfaceWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null && mounted) {
      setState(() {
        _checkInDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String bedLetter = widget.bed.bedNumber.contains('-')
        ? widget.bed.bedNumber.split('-').last
        : widget.bed.bedNumber;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.spacingLG),
        decoration: BoxDecoration(
          color: context.surfaceWhite,
          borderRadius: BorderRadius.circular(context.radiusXL),
          border: Border.all(color: context.surfaceBorder),
          boxShadow: AppTheme.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Assign Tenant', style: context.textTheme.headlineMedium),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: context.textHint, size: 20),
                ),
              ],
            ),
            SizedBox(height: context.spacingLG),
            Container(
              padding: EdgeInsets.all(context.spacingSM),
              decoration: BoxDecoration(
                color: context.backgroundLight,
                borderRadius: BorderRadius.circular(context.radiusLG),
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: context.spacingXS,
                runSpacing: context.spacingXS,
                children: [
                  Text(
                    'Assigning tenant to Room ${widget.room.roomNumber} - Bed $bedLetter',
                    style: context.textTheme.bodyMedium,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.spacingXS,
                      vertical: context.spacingXXS,
                    ),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(context.radiusXL),
                      border: Border.all(
                        color: context.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      widget.pgName,
                      style: context.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.spacingLG),
            Text(
              'Select Tenant (with "Deal Done" status)',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: context.spacingMD),
            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(context.spacingXL),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (_eligibleTenants == null || _eligibleTenants!.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.spacingXL),
                child: Column(
                  children: [
                    Icon(
                      Icons.group_off_outlined,
                      color: context.textHint,
                      size: 48,
                    ),
                    SizedBox(height: context.spacingMD),
                    Text(
                      'No eligible tenants found.',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.textHint,
                      ),
                    ),
                    SizedBox(height: context.spacingXS),
                    Text(
                      'Users must have an enquiry with "Deal Done" status.',
                      style: context.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacingMD,
                  vertical: context.spacingXXS,
                ),
                decoration: BoxDecoration(
                  color: context.backgroundLight,
                  borderRadius: BorderRadius.circular(context.radiusSM),
                  border: Border.all(color: context.surfaceBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTenantId,
                    hint: Text(
                      'Select a tenant',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.textHint,
                      ),
                    ),
                    isExpanded: true,
                    dropdownColor: context.surfaceWhite,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: context.textHint,
                    ),
                    items: _eligibleTenants!.map((t) {
                      final name =
                          t['name'] ?? t['userName'] ?? 'Unknown Tenant';
                      return DropdownMenuItem<String>(
                        value: t['_id']?.toString() ?? t['id']?.toString(),
                        child: Text(
                          name.toString(),
                          style: context.textTheme.bodyMedium,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedTenantId = val;
                      });
                    },
                  ),
                ),
              ),
            SizedBox(height: context.spacingLG),
            Text(
              'Check-in / Joining Date *',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: context.spacingSM),
            InkWell(
              onTap: () => _pickDate(context),
              borderRadius: BorderRadius.circular(context.radiusSM),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacingMD,
                  vertical: context.spacingMD,
                ),
                decoration: BoxDecoration(
                  color: context.backgroundLight,
                  borderRadius: BorderRadius.circular(context.radiusSM),
                  border: Border.all(color: context.surfaceBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${_checkInDate.day.toString().padLeft(2, '0')}-${_checkInDate.month.toString().padLeft(2, '0')}-${_checkInDate.year}",
                      style: context.textTheme.bodyMedium,
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      color: context.textHint,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.spacingXL),
            Divider(color: AppTheme.dividerColor),
            SizedBox(height: context.spacingMD),
            ElevatedButton(
              onPressed:
                  (_eligibleTenants != null &&
                      _eligibleTenants!.isNotEmpty &&
                      _selectedTenantId != null)
                  ? () async {
                      try {
                        await ref
                            .read(pgListingRepositoryProvider)
                            .assignBedToTenant(
                              widget.bed.id,
                              _selectedTenantId!,
                            );
                        ref.invalidate(pgRoomsProvider(widget.pgId));
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Tenant Assigned Successfully',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: context.primaryColor,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: context.errorColor,
                            ),
                          );
                        }
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                disabledBackgroundColor: context.primaryColor.withOpacity(0.3),
                padding: EdgeInsets.symmetric(vertical: context.spacingMD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.radiusLG),
                ),
              ),
              child: Text(
                'Confirm Assignment',
                style: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddRoomDialog extends ConsumerStatefulWidget {
  final String pgId;
  final String pgName;
  const _AddRoomDialog({required this.pgId, required this.pgName});

  @override
  ConsumerState<_AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends ConsumerState<_AddRoomDialog> {
  final _roomNumberController = TextEditingController();
  final _floorController = TextEditingController();
  int _occupancy = 2;
  String _roomType = 'Non-AC';

  final List<TextEditingController> _priceControllers = [];
  final List<TextEditingController> _positionControllers = [];
  final List<String?> _priceErrors = [];
  bool _isSubmitting = false;
  String? _roomNumberError;
  String? _floorError;

  @override
  void initState() {
    super.initState();
    _roomNumberController.addListener(_validateRoomNumber);
    _updateBedControllers();
  }

  void _validateRoomNumber() {
    final roomNo = _roomNumberController.text.trim();
    if (roomNo.isEmpty) {
      if (_roomNumberError != null) setState(() => _roomNumberError = null);
      return;
    }
    final roomsState = ref.read(pgRoomsProvider(widget.pgId));
    final currentRooms = roomsState.valueOrNull ?? [];
    bool exists = currentRooms.any((r) {
      final String existingRoomNo =
          (r is Map ? r['roomNumber'] : r.roomNumber)?.toString() ?? '';
      return existingRoomNo.toLowerCase() == roomNo.toLowerCase();
    });
    if (exists && _roomNumberError == null) {
      setState(() => _roomNumberError = 'Room already exists');
    } else if (!exists && _roomNumberError != null) {
      setState(() => _roomNumberError = null);
    }
  }

  @override
  void dispose() {
    _roomNumberController.removeListener(_validateRoomNumber);
    _roomNumberController.dispose();
    _floorController.dispose();
    for (var c in _priceControllers) {
      c.dispose();
    }
    for (var c in _positionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateBedControllers() {
    while (_priceControllers.length < _occupancy) {
      _priceControllers.add(TextEditingController());
      _positionControllers.add(TextEditingController());
      _priceErrors.add(null);
    }
    while (_priceControllers.length > _occupancy) {
      _priceControllers.removeLast().dispose();
      _positionControllers.removeLast().dispose();
      _priceErrors.removeLast();
    }
  }

  Future<void> _submit() async {
    setState(() {
      _floorError = null;
      for (int i = 0; i < _priceErrors.length; i++) {
        _priceErrors[i] = null;
      }
    });

    final roomNo = _roomNumberController.text.trim();
    bool hasError = false;

    if (roomNo.isEmpty) {
      _roomNumberError = 'Room number is required';
      hasError = true;
    }
    if (_floorController.text.trim().isEmpty) {
      _floorError = 'Floor is required';
      hasError = true;
    }

    if (roomNo.isNotEmpty) {
      final roomsState = ref.read(pgRoomsProvider(widget.pgId));
      final currentRooms = roomsState.valueOrNull ?? [];
      if (currentRooms.any((r) {
        final String existingRoomNo =
            (r is Map ? r['roomNumber'] : r.roomNumber)?.toString() ?? '';
        return existingRoomNo.toLowerCase() == roomNo.toLowerCase();
      })) {
        _roomNumberError = 'Room already exists in this PG';
        hasError = true;
      }
    }

    final List<Map<String, dynamic>> beds = [];
    final letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];

    for (int i = 0; i < _occupancy; i++) {
      final priceText = _priceControllers[i].text.trim();
      final posText = _positionControllers[i].text.trim();
      if (priceText.isEmpty) {
        _priceErrors[i] = 'Required';
        hasError = true;
      }

      beds.add({
        'bedNumber': '${_roomNumberController.text.trim()}-${letters[i]}',
        'price': double.tryParse(priceText) ?? 0.0,
        'position': posText,
      });
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(pgListingRepositoryProvider);
      await repo.addRoom({
        'pgId': widget.pgId,
        'roomNumber': _roomNumberController.text.trim(),
        'floor': int.tryParse(_floorController.text.trim()) ?? 1,
        'sharingType': _occupancy,
        'roomType': _roomType,
        'beds': beds,
      });
      if (mounted) {
        ref.invalidate(pgRoomsProvider(widget.pgId));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Room added successfully'),
            backgroundColor: context.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: context.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildLabel(BuildContext context, String text) {
    if (!text.contains('*')) {
      return Text(
        text,
        style: context.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade700,
        ),
      );
    }

    final parts = text.split('*');
    return RichText(
      text: TextSpan(
        text: parts[0],
        style: context.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade700,
        ),
        children: [
          TextSpan(
            text: '*',
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.errorColor,
            ),
          ),
          if (parts.length > 1) TextSpan(text: parts[1]),
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, label),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null
                  ? context.errorColor
                  : Colors.grey.shade200,
            ),
          ),
          child: TextField(
            controller: controller,
            cursorColor: context.primaryColor,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: context.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.errorColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      elevation: 0,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.04),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: context.primaryColor.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add_home_work_outlined,
                        color: context.primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Room',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            widget.pgName,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade600,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              context,
                              'Room No. *',
                              _roomNumberController,
                              'e.g. 101',
                              errorText: _roomNumberError,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              context,
                              'Floor *',
                              _floorController,
                              'e.g. 1',
                              keyboardType: TextInputType.number,
                              errorText: _floorError,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(context, 'Occupancy *'),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FB),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _occupancy,
                                      isExpanded: true,
                                      dropdownColor: Colors.white,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.grey.shade400,
                                      ),
                                      items: List.generate(10, (i) => i + 1)
                                          .map((e) {
                                            return DropdownMenuItem(
                                              value: e,
                                              child: Text(
                                                '$e Beds',
                                                style: context
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            );
                                          })
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _occupancy = val;
                                            _updateBedControllers();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(context, 'Type'),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FB),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _roomType,
                                      isExpanded: true,
                                      dropdownColor: Colors.white,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.grey.shade400,
                                      ),
                                      items: ['Non-AC', 'AC'].map((e) {
                                        return DropdownMenuItem(
                                          value: e,
                                          child: Text(
                                            e,
                                            style: context.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _roomType = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(
                            Icons.king_bed_outlined,
                            color: context.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Bed Details',
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_occupancy, (index) {
                        final letter = [
                          'A',
                          'B',
                          'C',
                          'D',
                          'E',
                          'F',
                          'G',
                          'H',
                          'I',
                          'J',
                        ][index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: context.primaryColor.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  letter,
                                  style: context.textTheme.titleSmall?.copyWith(
                                    color: context.primaryColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      context,
                                      'Price/Mo *',
                                      _priceControllers[index],
                                      '₹',
                                      keyboardType: TextInputType.number,
                                      errorText: _priceErrors[index],
                                    ),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      context,
                                      'Position',
                                      _positionControllers[index],
                                      'e.g. Window',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: context.textTheme.labelLarge?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: (_isSubmitting || _roomNumberError != null)
                          ? null
                          : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Save Room',
                              style: context.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditRoomDialog extends ConsumerStatefulWidget {
  final RoomData room;
  final String pgId;
  final String pgName;
  const _EditRoomDialog({
    required this.room,
    required this.pgId,
    required this.pgName,
  });

  @override
  ConsumerState<_EditRoomDialog> createState() => _EditRoomDialogState();
}

class _EditRoomDialogState extends ConsumerState<_EditRoomDialog> {
  final _roomNumberController = TextEditingController();
  final _floorController = TextEditingController();
  int _occupancy = 2;
  String _roomType = 'Non-AC';

  final List<TextEditingController> _priceControllers = [];
  final List<TextEditingController> _positionControllers = [];
  final List<String?> _priceErrors = [];
  bool _isSubmitting = false;
  String? _roomNumberError;
  String? _floorError;

  @override
  void initState() {
    super.initState();
    _roomNumberController.text = widget.room.roomNumber;
    _floorController.text = widget.room.floor.toString();
    _occupancy = widget.room.sharingType;
    _roomType = widget.room.roomType;
    _updateBedControllers(initializeWithData: true);
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _floorController.dispose();
    for (var c in _priceControllers) {
      c.dispose();
    }
    for (var c in _positionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateBedControllers({bool initializeWithData = false}) {
    while (_priceControllers.length < _occupancy) {
      _priceControllers.add(TextEditingController());
      _positionControllers.add(TextEditingController());
      _priceErrors.add(null);
    }
    while (_priceControllers.length > _occupancy) {
      _priceControllers.removeLast().dispose();
      _positionControllers.removeLast().dispose();
      _priceErrors.removeLast();
    }
    if (initializeWithData) {
      for (int i = 0; i < widget.room.beds.length && i < _occupancy; i++) {
        // Drop the .0 if it's a whole number for cleaner UI
        final price = widget.room.beds[i].price;
        _priceControllers[i].text = price == price.toInt()
            ? price.toInt().toString()
            : price.toString();
        _positionControllers[i].text = widget.room.beds[i].position;
      }
    }
  }

  Future<void> _submit() async {
    setState(() {
      _roomNumberError = null;
      _floorError = null;
      for (int i = 0; i < _priceErrors.length; i++) {
        _priceErrors[i] = null;
      }
    });

    final roomNo = _roomNumberController.text.trim();
    bool hasError = false;

    if (roomNo.isEmpty) {
      _roomNumberError = 'Room number is required';
      hasError = true;
    }
    if (_floorController.text.trim().isEmpty) {
      _floorError = 'Floor is required';
      hasError = true;
    }

    if (roomNo.isNotEmpty &&
        roomNo.toLowerCase() != widget.room.roomNumber.toLowerCase()) {
      final roomsState = ref.read(pgRoomsProvider(widget.pgId));
      final currentRooms = roomsState.valueOrNull ?? [];
      if (currentRooms.any((r) {
        final String existingRoomNo =
            (r is Map ? r['roomNumber'] : r.roomNumber)?.toString() ?? '';
        return existingRoomNo.toLowerCase() == roomNo.toLowerCase();
      })) {
        _roomNumberError = 'Room already exists in this PG';
        hasError = true;
      }
    }

    final List<Map<String, dynamic>> beds = [];
    final letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];

    for (int i = 0; i < _occupancy; i++) {
      final priceText = _priceControllers[i].text.trim();
      final posText = _positionControllers[i].text.trim();
      if (priceText.isEmpty) {
        _priceErrors[i] = 'Required';
        hasError = true;
      }

      final bedPayload = <String, dynamic>{
        'bedNumber': '${_roomNumberController.text.trim()}-${letters[i]}',
        'price': double.tryParse(priceText) ?? 0.0,
        'position': posText,
      };

      if (i < widget.room.beds.length) {
        bedPayload['_id'] = widget.room.beds[i].id;
      }

      beds.add(bedPayload);
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(pgListingRepositoryProvider);
      await repo.updateRoom(widget.room.id, {
        'roomNumber': _roomNumberController.text.trim(),
        'floor': int.tryParse(_floorController.text.trim()) ?? 1,
        'sharingType': _occupancy,
        'roomType': _roomType,
        'beds': beds,
      });
      if (mounted) {
        ref.invalidate(pgRoomsProvider(widget.pgId));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Room updated successfully'),
            backgroundColor: context.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: context.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildLabel(BuildContext context, String text) {
    if (!text.contains('*')) {
      return Text(
        text,
        style: context.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: context.textSecondary,
        ),
      );
    }

    final parts = text.split('*');
    return RichText(
      text: TextSpan(
        text: parts[0],
        style: context.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: context.textSecondary,
        ),
        children: [
          TextSpan(
            text: '*',
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.errorColor,
            ),
          ),
          if (parts.length > 1) TextSpan(text: parts[1]),
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, label),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null
                  ? context.errorColor
                  : Colors.grey.shade200,
            ),
          ),
          child: TextField(
            controller: controller,
            cursorColor: context.primaryColor,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: context.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.errorColor,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      elevation: 0,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.04),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: context.primaryColor.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.edit_square,
                        color: context.primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Room',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            widget.pgName,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade600,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              context,
                              'Room No. *',
                              _roomNumberController,
                              'e.g. 101',
                              errorText: _roomNumberError,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              context,
                              'Floor *',
                              _floorController,
                              'e.g. 1',
                              keyboardType: TextInputType.number,
                              errorText: _floorError,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(context, 'Occupancy *'),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FB),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _occupancy,
                                      isExpanded: true,
                                      dropdownColor: Colors.white,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.grey.shade400,
                                      ),
                                      items: List.generate(10, (i) => i + 1)
                                          .map((e) {
                                            return DropdownMenuItem(
                                              value: e,
                                              child: Text(
                                                '$e Beds',
                                                style: context
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            );
                                          })
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _occupancy = val;
                                            _updateBedControllers();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(context, 'Type'),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FB),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _roomType,
                                      isExpanded: true,
                                      dropdownColor: Colors.white,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.grey.shade400,
                                      ),
                                      items: ['Non-AC', 'AC'].map((e) {
                                        return DropdownMenuItem(
                                          value: e,
                                          child: Text(
                                            e,
                                            style: context.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _roomType = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(
                            Icons.king_bed_outlined,
                            color: context.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Bed Details',
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_occupancy, (index) {
                        final letter = [
                          'A',
                          'B',
                          'C',
                          'D',
                          'E',
                          'F',
                          'G',
                          'H',
                          'I',
                          'J',
                        ][index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: context.primaryColor.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  letter,
                                  style: context.textTheme.titleSmall?.copyWith(
                                    color: context.primaryColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      context,
                                      'Price/Mo *',
                                      _priceControllers[index],
                                      '₹',
                                      keyboardType: TextInputType.number,
                                      errorText: _priceErrors[index],
                                    ),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      context,
                                      'Position',
                                      _positionControllers[index],
                                      'e.g. Window',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: context.textTheme.labelLarge?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: context.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

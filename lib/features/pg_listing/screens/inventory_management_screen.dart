import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';

class BedData {
  final String id;
  final String bedNumber;
  final String position;
  final double price;
  final String status;
  final String? tenantName;

  BedData({
    required this.id,
    required this.bedNumber,
    required this.position,
    required this.price,
    required this.status,
    this.tenantName,
  });

  factory BedData.fromJson(Map<String, dynamic> json) {
    return BedData(
      id: json['_id'] ?? '',
      bedNumber: json['bedNumber'] ?? '',
      position: json['position'] ?? 'Standard',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'available',
      tenantName:
          json['tenantName'] ?? (json['userId'] != null ? 'Occupied' : null),
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
  // Dark Theme Colors
  static const Color bgColor = Color(0xFF0F111A);
  static const Color panelColor = Color(0xFF1A1D2D);
  static const Color cardColor = Color(0xFF161A28);
  static const Color bedBgColor = Color(0xFF1E2336);
  static const Color borderColor = Color(0xFF2A2E3D);
  static const Color textWhite = Colors.white;
  static const Color textGray = Color(0xFF94A3B8);
  static const Color primaryPurple = Color(0xFF6366F1);
  static const Color buttonPurple = Color(0xFF8B5CF6);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final roomsAsyncValue = ref.watch(pgRoomsProvider(widget.pg.id));

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchAndFilterPanel(),
            Expanded(
              child: roomsAsyncValue.when(
                data: (data) {
                  List<RoomData> rooms = data
                      .map((json) => RoomData.fromJson(json))
                      .toList();
                  if (rooms.isEmpty) {
                    return Center(
                      child: Text(
                        'No rooms found.',
                        style: GoogleFonts.plusJakartaSans(color: textGray),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    itemCount: rooms.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildRoomCard(rooms[index]);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: primaryPurple),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    'Failed to load inventory.',
                    style: GoogleFonts.plusJakartaSans(color: Colors.redAccent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: textGray),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Inventory',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textWhite,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => _AddRoomDialog(
                      pgId: widget.pg.id,
                      pgName: widget.pg.name,
                    ),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                label: Text(
                  'Add Room',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primaryPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryPurple.withOpacity(0.3)),
                ),
                child: Text(
                  widget.pg.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: buttonPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Track occupancy, rooms, and beds for this property',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textGray),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            TextField(
              style: GoogleFonts.plusJakartaSans(
                color: textWhite,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Search Room, Bed, Tenant...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: textGray,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search, color: textGray, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: bgColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDropdown('All Types')),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown('All Status')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            hint,
            style: GoogleFonts.plusJakartaSans(
              color: textWhite,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: textGray, size: 16),
        ],
      ),
    );
  }

  Widget _buildRoomCard(RoomData room) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Room Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Room ${room.roomNumber}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textWhite,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        'F${room.floor} • ${room.roomType}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: textGray,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: successGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${room.beds.length} Beds',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: successGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => _EditRoomDialog(
                            room: room,
                            pgName: widget.pg.name,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryPurple.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: primaryPurple,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: cardColor,
                            title: Text(
                              'Delete Room',
                              style: GoogleFonts.plusJakartaSans(color: textWhite),
                            ),
                            content: Text(
                              'Are you sure you want to delete this room?',
                              style: GoogleFonts.plusJakartaSans(color: textGray),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.plusJakartaSans(color: textGray),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  try {
                                    await ref.read(pgListingRepositoryProvider).deleteRoom(room.id);
                                    ref.invalidate(pgRoomsProvider(widget.pg.id));
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Room deleted successfully')),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  'Delete',
                                  style: GoogleFonts.plusJakartaSans(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 16,
                        ),
                      ),
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
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: room.beds.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _buildBedItem(room, room.beds[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBedItem(RoomData room, BedData bed) {
    bool isAvailable = bed.status == 'available';
    String bedLetter = bed.bedNumber.contains('-')
        ? bed.bedNumber.split('-').last
        : bed.bedNumber;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bedBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.bed_outlined,
            color: isAvailable ? successGreen : warningOrange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bed\n$bedLetter',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: textWhite,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '(${bed.position} • ₹${bed.price.toStringAsFixed(0)})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: textGray,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (isAvailable)
                  Text(
                    'Available',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: successGreen,
                    ),
                  )
                else
                  Row(
                    children: [
                      Text(
                        bed.tenantName ?? 'Occupied',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryPurple,
                        ),
                      ),
                      Text(
                        ' • ...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: primaryPurple,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              if (isAvailable) {
                showDialog(
                  context: context,
                  builder: (context) => _AssignTenantDialog(
                    pgId: widget.pg.id,
                    pgName: widget.pg.name,
                    room: room,
                    bed: bed,
                  ),
                );
              }
            },
            child: Text(
              isAvailable ? 'Assign' : 'Vacate',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isAvailable ? textWhite : textGray,
              ),
            ),
          ),
        ],
      ),
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

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _InventoryManagementScreenState.primaryPurple,
              surface: _InventoryManagementScreenState.cardColor,
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF161A28),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A2E3D)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assign Tenant',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2336),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Text(
                    'Assigning tenant to Room ${widget.room.roomNumber} - Bed $bedLetter',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _InventoryManagementScreenState.primaryPurple
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _InventoryManagementScreenState.primaryPurple
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      widget.pgName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _InventoryManagementScreenState.buttonPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Tenant (with "Deal Done" status)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color: _InventoryManagementScreenState.primaryPurple,
                  ),
                ),
              )
            else if (_eligibleTenants == null || _eligibleTenants!.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.group_off_outlined,
                      color: Colors.white24,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No eligible tenants found.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Users must have an enquiry with "Deal Done" status.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2336),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2E3D)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTenantId,
                    hint: Text(
                      'Select a tenant',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white54),
                    ),
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E2336),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white54,
                    ),
                    items: _eligibleTenants!.map((t) {
                      final name =
                          t['name'] ?? t['userName'] ?? 'Unknown Tenant';
                      return DropdownMenuItem<String>(
                        value: t['_id']?.toString() ?? t['id']?.toString(),
                        child: Text(
                          name.toString(),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                          ),
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
            const SizedBox(height: 24),
            Text(
              'Check-in / Joining Date *',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2336),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2E3D)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${_checkInDate.day.toString().padLeft(2, '0')}-${_checkInDate.month.toString().padLeft(2, '0')}-${_checkInDate.year}",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Divider(color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  (_eligibleTenants != null &&
                      _eligibleTenants!.isNotEmpty &&
                      _selectedTenantId != null)
                  ? () {
                      // TODO: submit assignment
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tenant Assigned Successfully (Mock)'),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _InventoryManagementScreenState.primaryPurple,
                disabledBackgroundColor: _InventoryManagementScreenState
                    .primaryPurple
                    .withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Confirm Assignment',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _updateBedControllers();
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

  void _updateBedControllers() {
    while (_priceControllers.length < _occupancy) {
      _priceControllers.add(TextEditingController());
      _positionControllers.add(TextEditingController());
    }
    while (_priceControllers.length > _occupancy) {
      _priceControllers.removeLast().dispose();
      _positionControllers.removeLast().dispose();
    }
  }

  Future<void> _submit() async {
    if (_roomNumberController.text.trim().isEmpty ||
        _floorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all room fields')),
      );
      return;
    }

    final List<Map<String, dynamic>> beds = [];
    final letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

    for (int i = 0; i < _occupancy; i++) {
      final priceText = _priceControllers[i].text.trim();
      final posText = _positionControllers[i].text.trim();
      if (priceText.isEmpty || posText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all bed fields')),
        );
        return;
      }

      beds.add({
        'bedNumber': '${_roomNumberController.text.trim()}-${letters[i]}',
        'price': double.tryParse(priceText) ?? 0.0,
        'position': posText,
      });
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
          const SnackBar(content: Text('Room added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildLabel(String text) {
    if (!text.contains('*')) {
      return Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      );
    }

    final parts = text.split('*');
    return RichText(
      text: TextSpan(
        text: parts[0],
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
        children: [
          TextSpan(
            text: '*',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEF4444), // Red asterisk
            ),
          ),
          if (parts.length > 1) TextSpan(text: parts[1]),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E2336),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2E3D)),
          ),
          child: TextField(
            controller: controller,
            cursorColor: Colors.black,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.black,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                color: Colors.white24,
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      elevation: 0,
      child: Material(
        color: const Color(0xFF161A28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2A2E3D)),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Add New Room to ${widget.pgName}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Room Number *',
                        _roomNumberController,
                        'e.g. 101',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Floor *',
                        _floorController,
                        'e.g. 1',
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
                          _buildLabel('Occupancy (Beds) *'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2336),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF2A2E3D),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _occupancy,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF1E2336),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white54,
                                ),
                                items: [1, 2, 3, 4, 5, 6]
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e.toString(),
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Room Type'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2336),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF2A2E3D),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _roomType,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF1E2336),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white54,
                                ),
                                items: ['Non-AC', 'AC']
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _roomType = val;
                                    });
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
                Text(
                  'Bed Configurations',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 8),
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
                  ][index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bed $letter',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E2336),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF2A2E3D),
                                  ),
                                ),
                                child: Text(
                                  letter,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            'Price *',
                            _priceControllers[index],
                            'Price',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            'Position',
                            _positionControllers[index],
                            'Window Side',
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _InventoryManagementScreenState.primaryPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Create Room & Beds',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditRoomDialog extends ConsumerStatefulWidget {
  final RoomData room;
  final String pgName;
  const _EditRoomDialog({required this.room, required this.pgName});

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
  bool _isSubmitting = false;

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
    }
    while (_priceControllers.length > _occupancy) {
      _priceControllers.removeLast().dispose();
      _positionControllers.removeLast().dispose();
    }
    if (initializeWithData) {
      for (int i = 0; i < widget.room.beds.length && i < _occupancy; i++) {
        _priceControllers[i].text = widget.room.beds[i].price.toString();
        _positionControllers[i].text = widget.room.beds[i].position;
      }
    }
  }

  Future<void> _submit() async {
    if (_roomNumberController.text.trim().isEmpty ||
        _floorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all room fields')),
      );
      return;
    }

    final List<Map<String, dynamic>> beds = [];
    final letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

    for (int i = 0; i < _occupancy; i++) {
      final priceText = _priceControllers[i].text.trim();
      final posText = _positionControllers[i].text.trim();
      if (priceText.isEmpty || posText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all bed fields')),
        );
        return;
      }

      beds.add({
        'bedNumber': '${_roomNumberController.text.trim()}-${letters[i]}',
        'price': double.tryParse(priceText) ?? 0.0,
        'position': posText,
      });
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
        ref.invalidate(pgRoomsProvider(widget.room.id));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildLabel(String text) {
    if (!text.contains('*')) {
      return Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      );
    }

    final parts = text.split('*');
    return RichText(
      text: TextSpan(
        text: parts[0],
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
        children: [
          TextSpan(
            text: '*',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEF4444),
            ),
          ),
          if (parts.length > 1) TextSpan(text: parts[1]),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E2336),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2E3D)),
          ),
          child: TextField(
            controller: controller,
            cursorColor: Colors.black,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.black,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                color: Colors.white24,
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      elevation: 0,
      child: Material(
        color: const Color(0xFF161A28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2A2E3D)),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Edit Room Details - ${widget.pgName}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Room Number *',
                        _roomNumberController,
                        'e.g. 101',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Floor *',
                        _floorController,
                        'e.g. 1',
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
                          _buildLabel('Occupancy (Beds) *'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2336),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF2A2E3D),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _occupancy,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF1E2336),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white54,
                                ),
                                items: [1, 2, 3, 4, 5, 6]
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e.toString(),
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Room Type'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2336),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF2A2E3D),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _roomType,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF1E2336),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white54,
                                ),
                                items: ['Non-AC', 'AC']
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _roomType = val;
                                    });
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
                Text(
                  'Bed Configurations',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 8),
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
                  ][index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bed ${_roomNumberController.text.isNotEmpty ? _roomNumberController.text : "Room"}-$letter',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E2336),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF2A2E3D),
                                  ),
                                ),
                                child: Text(
                                  '${_roomNumberController.text.isNotEmpty ? _roomNumberController.text : "Room"}-$letter',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            'Price *',
                            _priceControllers[index],
                            'Price',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            'Position',
                            _positionControllers[index],
                            'Window Side',
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _InventoryManagementScreenState.primaryPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Update Room',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

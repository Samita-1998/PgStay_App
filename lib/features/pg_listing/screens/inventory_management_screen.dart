import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';

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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => _AddRoomDialog(
              pgId: widget.pg.id,
              pgName: widget.pg.name,
            ),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: context.spacingMD,
                      vertical: context.spacingMD,
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
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceWhite,
        borderRadius: BorderRadius.circular(context.radiusXL),
        border: Border.all(color: context.surfaceBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Room Header
          Padding(
            padding: EdgeInsets.all(context.spacingMD),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Room ${room.roomNumber}',
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: context.spacingXS),
                    Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Text(
                        'F${room.floor} • ${room.roomType}',
                        style: context.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.spacingXS,
                        vertical: context.spacingXXS,
                      ),
                      decoration: BoxDecoration(
                        color: context.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.radiusSM),
                        border: Border.all(
                          color: context.successColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${room.beds.length} Beds',
                        style: context.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.successColor,
                        ),
                      ),
                    ),
                    SizedBox(width: context.spacingXS),
                    InkWell(
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
                      borderRadius: BorderRadius.circular(context.radiusXL),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          color: context.primaryColor,
                          size: 16,
                        ),
                      ),
                    ),
                    SizedBox(width: context.spacingXS),
                    InkWell(
                      onTap: () {
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
                                    if (mounted) {
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
                                    if (mounted) {
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
                      borderRadius: BorderRadius.circular(context.radiusXL),
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.errorColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: context.errorColor,
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
            padding: EdgeInsets.fromLTRB(
              context.spacingSM,
              0,
              context.spacingSM,
              context.spacingSM,
            ),
            itemCount: room.beds.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: context.spacingXS),
            itemBuilder: (context, index) {
              return _buildBedItem(context, room, room.beds[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBedItem(BuildContext context, RoomData room, BedData bed) {
    bool isAvailable = bed.status == 'available';
    String bedLetter = bed.bedNumber.contains('-')
        ? bed.bedNumber.split('-').last
        : bed.bedNumber;

    return Container(
      padding: EdgeInsets.all(context.spacingSM),
      decoration: BoxDecoration(
        color: context.backgroundLight,
        borderRadius: BorderRadius.circular(context.radiusLG),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.bed_outlined,
            color: isAvailable ? context.successColor : context.warningColor,
            size: 20,
          ),
          SizedBox(width: context.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bed\n$bedLetter',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(width: context.spacingXS),
                    Expanded(
                      child: Text(
                        '(${bed.position} • ₹${bed.price.toStringAsFixed(0)})',
                        style: context.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.spacingXXS),
                if (isAvailable)
                  Text(
                    'Available',
                    style: context.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.successColor,
                    ),
                  )
                else
                  Row(
                    children: [
                      Text(
                        bed.tenantName ?? 'Occupied',
                        style: context.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.primaryColor,
                        ),
                      ),
                      Text(
                        ' • ...',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: context.primaryColor,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SizedBox(width: context.spacingXS),
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
              } else {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
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
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: context.textTheme.labelMedium?.copyWith(
                            color: context.textHint,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await ref
                                .read(pgListingRepositoryProvider)
                                .unassignBedFromTenant(bed.id);
                            ref.invalidate(pgRoomsProvider(widget.pg.id));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Tenant removed from bed successfully',
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
              }
            },
            child: Text(
              isAvailable ? 'Assign' : 'Vacate',
              style: context.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isAvailable ? context.textPrimary : context.errorColor,
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
        SnackBar(
          content: const Text('Please fill all room fields'),
          backgroundColor: context.errorColor,
        ),
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
          SnackBar(
            content: const Text('Please fill all bed fields'),
            backgroundColor: context.errorColor,
          ),
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
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, label),
        SizedBox(height: context.spacingXS),
        Container(
          decoration: BoxDecoration(
            color: context.backgroundLight,
            borderRadius: BorderRadius.circular(context.radiusSM),
            border: Border.all(color: context.surfaceBorder),
          ),
          child: TextField(
            controller: controller,
            cursorColor: context.primaryColor,
            style: context.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: context.textTheme.bodySmall,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.spacingMD,
                vertical: context.spacingSM,
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
        color: context.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radiusXL),
          side: BorderSide(color: context.surfaceBorder),
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.spacingLG),
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
                        style: context.textTheme.headlineSmall,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        color: context.textHint,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.spacingLG),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        context,
                        'Room Number *',
                        _roomNumberController,
                        'e.g. 101',
                      ),
                    ),
                    SizedBox(width: context.spacingMD),
                    Expanded(
                      child: _buildTextField(
                        context,
                        'Floor *',
                        _floorController,
                        'e.g. 1',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.spacingMD),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(context, 'Occupancy (Beds) *'),
                          SizedBox(height: context.spacingXS),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.spacingMD,
                            ),
                            decoration: BoxDecoration(
                              color: context.backgroundLight,
                              borderRadius: BorderRadius.circular(
                                context.radiusSM,
                              ),
                              border: Border.all(color: context.surfaceBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _occupancy,
                                isExpanded: true,
                                dropdownColor: context.surfaceWhite,
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: context.textHint,
                                ),
                                items: [1, 2, 3, 4, 5, 6]
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e.toString(),
                                          style: context.textTheme.bodyMedium,
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
                    SizedBox(width: context.spacingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(context, 'Room Type'),
                          SizedBox(height: context.spacingXS),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.spacingMD,
                            ),
                            decoration: BoxDecoration(
                              color: context.backgroundLight,
                              borderRadius: BorderRadius.circular(
                                context.radiusSM,
                              ),
                              border: Border.all(color: context.surfaceBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _roomType,
                                isExpanded: true,
                                dropdownColor: context.surfaceWhite,
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: context.textHint,
                                ),
                                items: ['Non-AC', 'AC']
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e,
                                          style: context.textTheme.bodyMedium,
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
                SizedBox(height: context.spacingLG),
                Text(
                  'Bed Configurations',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: context.spacingXS),
                Divider(color: AppTheme.dividerColor),
                SizedBox(height: context.spacingXS),
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
                    padding: EdgeInsets.only(bottom: context.spacingMD),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bed $letter',
                                style: context.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.textSecondary,
                                ),
                              ),
                              SizedBox(height: context.spacingXS),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.spacingMD,
                                  vertical: context.spacingSM,
                                ),
                                decoration: BoxDecoration(
                                  color: context.backgroundLight,
                                  borderRadius: BorderRadius.circular(
                                    context.radiusSM,
                                  ),
                                  border: Border.all(
                                    color: context.surfaceBorder,
                                  ),
                                ),
                                child: Text(
                                  letter,
                                  style: context.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: context.spacingSM),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            context,
                            'Price *',
                            _priceControllers[index],
                            'Price',
                          ),
                        ),
                        SizedBox(width: context.spacingSM),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            context,
                            'Position',
                            _positionControllers[index],
                            'Window Side',
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: context.spacingMD),
                Divider(color: AppTheme.dividerColor),
                SizedBox(height: context.spacingMD),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: context.textTheme.labelLarge?.copyWith(
                          color: context.textHint,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: context.spacingLG),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.spacingXL,
                          vertical: context.spacingSM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.radiusLG),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Create Room & Beds',
                              style: context.textTheme.labelLarge?.copyWith(
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
    if (_roomNumberController.text.trim().isEmpty ||
        _floorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all room fields'),
          backgroundColor: context.errorColor,
        ),
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
          SnackBar(
            content: const Text('Please fill all bed fields'),
            backgroundColor: context.errorColor,
          ),
        );
        return;
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
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, label),
        SizedBox(height: context.spacingXS),
        Container(
          decoration: BoxDecoration(
            color: context.backgroundLight,
            borderRadius: BorderRadius.circular(context.radiusSM),
            border: Border.all(color: context.surfaceBorder),
          ),
          child: TextField(
            controller: controller,
            cursorColor: context.primaryColor,
            style: context.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: context.textTheme.bodySmall,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.spacingMD,
                vertical: context.spacingSM,
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
        color: context.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radiusXL),
          side: BorderSide(color: context.surfaceBorder),
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.spacingLG),
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
                        style: context.textTheme.headlineSmall,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        color: context.textHint,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.spacingLG),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        context,
                        'Room Number *',
                        _roomNumberController,
                        'e.g. 101',
                      ),
                    ),
                    SizedBox(width: context.spacingMD),
                    Expanded(
                      child: _buildTextField(
                        context,
                        'Floor *',
                        _floorController,
                        'e.g. 1',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.spacingMD),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(context, 'Occupancy (Beds) *'),
                          SizedBox(height: context.spacingXS),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.spacingMD,
                            ),
                            decoration: BoxDecoration(
                              color: context.backgroundLight,
                              borderRadius: BorderRadius.circular(
                                context.radiusSM,
                              ),
                              border: Border.all(color: context.surfaceBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _occupancy,
                                isExpanded: true,
                                dropdownColor: context.surfaceWhite,
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: context.textHint,
                                ),
                                items: [1, 2, 3, 4, 5, 6]
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e.toString(),
                                          style: context.textTheme.bodyMedium,
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
                    SizedBox(width: context.spacingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(context, 'Room Type'),
                          SizedBox(height: context.spacingXS),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.spacingMD,
                            ),
                            decoration: BoxDecoration(
                              color: context.backgroundLight,
                              borderRadius: BorderRadius.circular(
                                context.radiusSM,
                              ),
                              border: Border.all(color: context.surfaceBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _roomType,
                                isExpanded: true,
                                dropdownColor: context.surfaceWhite,
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: context.textHint,
                                ),
                                items: ['Non-AC', 'AC']
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e,
                                          style: context.textTheme.bodyMedium,
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
                SizedBox(height: context.spacingLG),
                Text(
                  'Bed Configurations',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: context.spacingXS),
                Divider(color: AppTheme.dividerColor),
                SizedBox(height: context.spacingXS),
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
                    padding: EdgeInsets.only(bottom: context.spacingMD),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bed ${_roomNumberController.text.isNotEmpty ? _roomNumberController.text : "Room"}-$letter',
                                style: context.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.textSecondary,
                                ),
                              ),
                              SizedBox(height: context.spacingXS),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.spacingMD,
                                  vertical: context.spacingSM,
                                ),
                                decoration: BoxDecoration(
                                  color: context.backgroundLight,
                                  borderRadius: BorderRadius.circular(
                                    context.radiusSM,
                                  ),
                                  border: Border.all(
                                    color: context.surfaceBorder,
                                  ),
                                ),
                                child: Text(
                                  '${_roomNumberController.text.isNotEmpty ? _roomNumberController.text : "Room"}-$letter',
                                  style: context.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: context.spacingSM),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            context,
                            'Price *',
                            _priceControllers[index],
                            'Price',
                          ),
                        ),
                        SizedBox(width: context.spacingSM),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            context,
                            'Position',
                            _positionControllers[index],
                            'Window Side',
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: context.spacingMD),
                Divider(color: AppTheme.dividerColor),
                SizedBox(height: context.spacingMD),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: context.textTheme.labelLarge?.copyWith(
                          color: context.textHint,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: context.spacingLG),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.spacingXL,
                          vertical: context.spacingSM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.radiusLG),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Update Room',
                              style: context.textTheme.labelLarge?.copyWith(
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

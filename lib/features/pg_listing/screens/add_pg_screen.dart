import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';

class AddPgScreen extends ConsumerStatefulWidget {
  final PgModel? pgToEdit;

  const AddPgScreen({super.key, this.pgToEdit});

  @override
  ConsumerState<AddPgScreen> createState() => _AddPgScreenState();
}

class _AddPgScreenState extends ConsumerState<AddPgScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');
  final _locationDescriptionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _landlineController = TextEditingController();
  final _checkInController = TextEditingController(text: '12:00 PM');
  final _checkOutController = TextEditingController(text: '11:00 AM');
  final _locationLinkController = TextEditingController();
  final _dueDayController = TextEditingController(text: '10');
  final _lateFeeController = TextEditingController(text: '0');
  final _startedDateController = TextEditingController();

  // Dropdown / Selection Values
  String _selectedPgType = 'Co-Living';
  String? _selectedManagerId;
  List<String> _selectedFacilityIds = [];

  // API Data States
  List<Map<String, String>> _managers = [];
  List<Map<String, String>> _facilities = [];
  bool _isLoadingDropdowns = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.pgToEdit != null) {
      _populateFormWithExistingData();
    }
    _loadFormData();
  }

  void _populateFormWithExistingData() {
    _nameController.text = widget.pgToEdit!.name;
    _pincodeController.text = widget.pgToEdit!.address.pincode.toString();
    _landmarkController.text = widget.pgToEdit!.address.landmark;
    _cityController.text = widget.pgToEdit!.address.city;
    _stateController.text = widget.pgToEdit!.address.state;
    _countryController.text = widget.pgToEdit!.address.country;
    _checkInController.text = widget.pgToEdit!.checkInTime;
    _checkOutController.text = widget.pgToEdit!.checkOutTime;
    _selectedManagerId = widget.pgToEdit!.managerId;
    _locationDescriptionController.text = widget.pgToEdit!.address.locationDescription ?? '';
    _descriptionController.text = widget.pgToEdit!.description ?? '';
    _startedDateController.text = widget.pgToEdit!.pgStartedDate ?? '';
    _dueDayController.text = widget.pgToEdit!.dueDayOfMonth?.toString() ?? '10';
    _landlineController.text = widget.pgToEdit!.landline ?? '';
    _locationLinkController.text = widget.pgToEdit!.locationLink ?? '';

    final type = widget.pgToEdit!.pgType.toLowerCase();
    if (type == 'male')
      _selectedPgType = 'Male';
    else if (type == 'female')
      _selectedPgType = 'Female';
    else if (type == 'unisex')
      _selectedPgType = 'Unisex';
    else
      _selectedPgType = 'Co-Living';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _locationDescriptionController.dispose();
    _descriptionController.dispose();
    _landlineController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    _locationLinkController.dispose();
    _dueDayController.dispose();
    _lateFeeController.dispose();
    _startedDateController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    try {
      final repository = ref.read(pgListingRepositoryProvider);
      final fetchedManagers = await repository.fetchManagers();
      final fetchedFacilities = await repository.fetchFacilities();
      final currentUser = ref.read(authProvider).valueOrNull;

      if (mounted) {
        setState(() {
          _managers = List<Map<String, String>>.from(fetchedManagers);
          _facilities = fetchedFacilities;

          if (currentUser != null) {
            final exists = _managers.any((m) => m['id'] == currentUser.id);
            if (!exists) {
              _managers.insert(0, {
                'id': currentUser.id,
                'name': '${currentUser.name} (Owner / Me)',
              });
            }
          }

          if (_managers.isNotEmpty && _selectedManagerId == null) {
            _selectedManagerId = _managers.first['id'];
          }

          if (widget.pgToEdit != null) {
            _selectedFacilityIds = widget.pgToEdit!.facilities
                .map((facName) {
                  final found = _facilities.firstWhere(
                    (f) => f['name'] == facName,
                    orElse: () => {'id': ''},
                  );
                  return found['id']!;
                })
                .where((id) => id.isNotEmpty)
                .toList();
          }

          _isLoadingDropdowns = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDropdowns = false);
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedManagerId == null) {
      _showSnackBar('Please select a property manager.', AppTheme.error);
      return;
    }

    if (_selectedFacilityIds.isEmpty) {
      _showSnackBar('Please select at least one facility.', AppTheme.error);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(pgListingRepositoryProvider);

      String backendPgType;
      switch (_selectedPgType) {
        case 'Male':
          backendPgType = 'male';
          break;
        case 'Female':
          backendPgType = 'female';
          break;
        case 'Unisex':
          backendPgType = 'unisex';
          break;
        default:
          backendPgType = 'coLiving';
      }

      final Map<String, dynamic> addressData = {
        'pincode': int.parse(_pincodeController.text.trim()),
        'landmark': _landmarkController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': _countryController.text.trim(),
      };
      
      final locationDesc = _locationDescriptionController.text.trim();
      if (locationDesc.isNotEmpty) {
        addressData['locationDescription'] = locationDesc;
      }

      final Map<String, dynamic> pgData = {
        'name': _nameController.text.trim(),
        'address': addressData,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : 'A comfortable and secure PG stay with all essential amenities.',
        'managerId': _selectedManagerId,
        'pgType': backendPgType,
        'facilities': _selectedFacilityIds,
        'checkInTime': _checkInController.text.trim(),
        'checkOutTime': _checkOutController.text.trim(),
        'dueDayOfMonth': int.tryParse(_dueDayController.text.trim()) ?? 1,
        'pgStartedDate': _startedDateController.text.trim(),
      };

      if (_landlineController.text.trim().isNotEmpty) {
        pgData['landline'] = _landlineController.text.trim();
      }
      if (_locationLinkController.text.trim().isNotEmpty) {
        pgData['locationLink'] = _locationLinkController.text.trim();
      }

      if (widget.pgToEdit != null) {
        await repository.updatePG(widget.pgToEdit!.id, pgData);
        _showSnackBar(
          'PG Stay property updated successfully!',
          AppTheme.success,
        );
      } else {
        await repository.addPG(pgData);
        _showSnackBar(
          'PG Stay property created successfully!',
          AppTheme.success,
        );
      }

      ref.invalidate(ownerPgsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showSnackBar(e.toString(), AppTheme.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          widget.pgToEdit != null ? 'Edit Property' : 'Register Property',
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: _isLoadingDropdowns
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Banner
                    _buildHeroBanner(),
                    const SizedBox(height: AppTheme.spacingLG),

                    // Basic Information Card
                    _buildSectionCard(
                      title: 'Basic Information',
                      icon: Icons.info_outline_rounded,
                      children: [
                        _buildTextField(
                          label: 'PG Name *',
                          controller: _nameController,
                          hint: 'e.g., HappyDays Khandala',
                          icon: Icons.business_outlined,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'PG Name required'
                              : null,
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        _buildTextField(
                          label: 'Description',
                          controller: _descriptionController,
                          hint:
                              'Tell tenants about rooms, vacancy details, rules...',
                          icon: Icons.description_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField<String>(
                                label: 'PG Type *',
                                value: _selectedPgType,
                                icon: Icons.group_outlined,
                                items: const [
                                  'Male',
                                  'Female',
                                  'Unisex',
                                  'Co-Living',
                                ],
                                onChanged: (val) =>
                                    setState(() => _selectedPgType = val!),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMD),
                            Expanded(
                              child: _buildDropdownField<String>(
                                label: 'Manager *',
                                value: _selectedManagerId,
                                icon: Icons.person_pin_outlined,
                                items: _managers.map((m) => m['id']!).toList(),
                                itemLabel: (id) => _managers.firstWhere(
                                  (m) => m['id'] == id,
                                )['name']!,
                                onChanged: (val) =>
                                    setState(() => _selectedManagerId = val),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLG),

                    // Location Card
                    _buildSectionCard(
                      title: 'Location & Address',
                      icon: Icons.location_on_outlined,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Landmark *',
                                controller: _landmarkController,
                                hint: 'Near Metro Station',
                                icon: Icons.bookmark_outlined,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMD),
                            Expanded(
                              child: _buildTextField(
                                label: 'Pincode *',
                                controller: _pincodeController,
                                hint: '411001',
                                icon: Icons.pin_drop_outlined,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Required';
                                  if (int.tryParse(v) == null)
                                    return 'Must be digits';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'City *',
                                controller: _cityController,
                                hint: 'Pune',
                                icon: Icons.location_city_outlined,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMD),
                            Expanded(
                              child: _buildTextField(
                                label: 'State *',
                                controller: _stateController,
                                hint: 'Maharashtra',
                                icon: Icons.map_outlined,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        _buildTextField(
                          label: 'Country *',
                          controller: _countryController,
                          hint: 'India',
                          icon: Icons.public_outlined,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        _buildTextField(
                          label: 'Location Description',
                          controller: _locationDescriptionController,
                          hint: '2nd building right next to Coffee Shop',
                          icon: Icons.explore_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLG),

                    // Facilities Card
                    _buildSectionCard(
                      title: 'Select Facilities',
                      icon: Icons.wifi_outlined,
                      children: [
                        if (_facilities.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingMD),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.error.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLG,
                              ),
                            ),
                            child: Text(
                              'Failed to load facilities.',
                              style: AppTheme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.error,
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: AppTheme.spacingSM,
                            runSpacing: AppTheme.spacingSM,
                            children: _facilities.map((fac) {
                              final isSelected = _selectedFacilityIds.contains(
                                fac['id'],
                              );
                              final facIcon = _getFacilityIcon(fac['name']!);

                              return InkWell(
                                onTap: () => setState(() {
                                  if (isSelected) {
                                    _selectedFacilityIds.remove(fac['id']!);
                                  } else {
                                    _selectedFacilityIds.add(fac['id']!);
                                  }
                                }),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusLG,
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingMD,
                                    vertical: AppTheme.spacingSM,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primary.withOpacity(0.06)
                                        : AppTheme.surfaceWhite,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusLG,
                                    ),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : AppTheme.surfaceBorder,
                                      width: isSelected ? 1.8 : 1.0,
                                    ),
                                    boxShadow: isSelected
                                        ? AppTheme.primaryGlow(opacity: 0.08)
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        facIcon,
                                        color: isSelected
                                            ? AppTheme.primary
                                            : AppTheme.textSecondary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: AppTheme.spacingXS),
                                      Text(
                                        fac['name']!,
                                        style: AppTheme.textTheme.labelMedium
                                            ?.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: isSelected
                                                  ? AppTheme.primary
                                                  : AppTheme.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLG),

                    // Rules & Timings Card
                    _buildSectionCard(
                      title: 'Rules & Timings',
                      icon: Icons.watch_later_outlined,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Check-in Time',
                                controller: _checkInController,
                                hint: '12:00 PM',
                                icon: Icons.login_outlined,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMD),
                            Expanded(
                              child: _buildTextField(
                                label: 'Check-out Time',
                                controller: _checkOutController,
                                hint: '11:00 AM',
                                icon: Icons.logout_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Due Day of Month (1-28) *',
                                controller: _dueDayController,
                                hint: '10',
                                icon: Icons.calendar_today_outlined,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMD),
                            Expanded(
                              child: _buildTextField(
                                label: 'Late Fee Penalty (₹) *',
                                controller: _lateFeeController,
                                hint: '0',
                                icon: Icons.currency_rupee_outlined,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Location Link (Optional)',
                                controller: _locationLinkController,
                                hint: 'Maps URL',
                                icon: Icons.link_outlined,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMD),
                            Expanded(
                              child: _buildTextField(
                                label: 'PG Started Date *',
                                controller: _startedDateController,
                                hint: 'dd/mm/yyyy',
                                icon: Icons.date_range_outlined,
                                readOnly: true,
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    _startedDateController.text =
                                        "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        _buildTextField(
                          label: 'Contact No / Landline (Optional)',
                          controller: _landlineController,
                          hint: '+919876543210',
                          icon: Icons.phone_callback_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLG),

                    // Images Card
                    _buildSectionCard(
                      title: 'Showcase Images',
                      icon: Icons.image_outlined,
                      children: [
                        InkWell(
                          onTap: () => _showSnackBar(
                            'Image upload coming soon.',
                            AppTheme.info,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXL,
                          ),
                          child: Container(
                            height: 110,
                            width: 110,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXL,
                              ),
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: AppTheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingSM),
                                Text(
                                  'ADD IMAGE',
                                  style: AppTheme.textTheme.labelSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        Text(
                          '* Upload up to 10 high-quality showcase images. JPEG, PNG, WEBP files under 5MB are supported.',
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXXL),

                    // Submit Button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: AppTheme.primaryGlow(),
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLG,
                            ),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.pgToEdit != null
                                        ? Icons.update_rounded
                                        : Icons.add_rounded,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: AppTheme.spacingXS),
                                  Text(
                                    widget.pgToEdit != null
                                        ? 'Update Property'
                                        : 'Register Property',
                                    style: AppTheme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
        boxShadow: AppTheme.primaryGlow(),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.pgToEdit != null
                  ? Icons.edit_rounded
                  : Icons.add_business_rounded,
              color: AppTheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pgToEdit != null
                      ? 'Edit PG Property'
                      : 'Host a New PG Property',
                  style: AppTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  'Fill out details below to list your PG stay.',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 22),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                title,
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Divider(color: AppTheme.dividerColor, height: 1),
          const SizedBox(height: AppTheme.spacingLG),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: AppTheme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.textTheme.bodySmall,
            prefixIcon: Icon(icon, size: 20, color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surfaceWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              borderSide: const BorderSide(color: AppTheme.surfaceBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              borderSide: const BorderSide(color: AppTheme.surfaceBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required IconData icon,
    required List<T> items,
    String Function(T)? itemLabel,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppTheme.surfaceWhite,
          style: AppTheme.textTheme.bodyMedium,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            prefixIcon: Icon(icon, size: 20, color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surfaceWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              borderSide: const BorderSide(color: AppTheme.surfaceBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              borderSide: const BorderSide(color: AppTheme.surfaceBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel != null ? itemLabel(item) : item.toString(),
                style: AppTheme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';
import 'package:pgstay/features/pg_listing/screens/modern_text_field_widget.dart';
import 'package:pgstay/core/utils/change_tracker.dart';

class AddPgScreen extends ConsumerStatefulWidget {
  final PgModel? pgToEdit;

  const AddPgScreen({super.key, this.pgToEdit});

  @override
  ConsumerState<AddPgScreen> createState() => _AddPgScreenState();
}

class _AddPgScreenState extends ConsumerState<AddPgScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  int _maxStepReached = 0;
  final int _totalSteps = 3;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Controllers - Step 1: General
  final _nameController = TextEditingController();
  final _landlineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startedDateController = TextEditingController();
  DateTime? _selectedStartedDate;
  String _selectedPgType = 'Co-Living';
  String? _selectedManagerId;

  // Controllers - Step 2: Location
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');
  final _pincodeController = TextEditingController();
  final _locationLinkController = TextEditingController();
  final _locationDescriptionController = TextEditingController();
  PgLocation? _capturedLocation;
  bool _isCapturingLocation = false;

  // Controllers - Step 3: Features
  final _checkInController = TextEditingController(text: '12:00 PM');
  final _checkOutController = TextEditingController(text: '11:00 AM');
  final _dueDayController = TextEditingController(text: '10');
  final _lateFeeController = TextEditingController(text: '0');
  final _facilitySearchController = TextEditingController();
  final _upiIdController = TextEditingController();
  XFile? _qrImageFile;
  String? _existingQrImage;
  List<String> _selectedFacilityIds = [];
  List<String> _initialFacilityIds = [];
  bool _isFacilityListExpanded = false;

  // API Data States
  List<Map<String, String>> _managers = [];
  List<Map<String, String>> _facilities = [];
  bool _isLoadingDropdowns = true;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  List<String> _existingImages = [];

  bool get _hasChanges => _tracker.hasChanges || _untrackedHasChanges;
  late final ChangeTracker _tracker;

  bool get _untrackedHasChanges {
    if (widget.pgToEdit == null) return true;
    final pg = widget.pgToEdit!;

    final type = pg.pgType.toLowerCase();
    final originalType =
        {'male': 'Male', 'female': 'Female', 'unisex': 'Unisex'}[type] ??
        'Co-Living';
    if (_selectedPgType != originalType) return true;
    if (_selectedManagerId != pg.managerId) return true;

    if (_capturedLocation != pg.location) return true;
    if (_selectedImages.isNotEmpty) return true;
    if (_existingImages.length != pg.images.length) return true;
    if (_qrImageFile != null) return true;
    if (_existingQrImage != pg.paymentQrImage) return true;

    if (_selectedFacilityIds.length != _initialFacilityIds.length) return true;
    for (final id in _selectedFacilityIds) {
      if (!_initialFacilityIds.contains(id)) return true;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    _tracker = ChangeTracker(
      onStateChanged: () {
        if (mounted &&
            widget.pgToEdit != null &&
            _currentStep == _totalSteps - 1) {
          setState(() {});
        }
      },
    );

    if (widget.pgToEdit != null) {
      _maxStepReached = _totalSteps - 1;
      _populateFormWithExistingData();
    }
    _loadFormData();

    final listener = () {
      if (mounted &&
          widget.pgToEdit != null &&
          _currentStep == _totalSteps - 1) {
        setState(() {});
      }
    };

    void addTrackerListener(TextEditingController ctrl, String key) {
      ctrl.addListener(() {
        _tracker.updateValue(key, ctrl.text.trim());
        listener();
      });
    }

    addTrackerListener(_nameController, 'name');
    addTrackerListener(_landlineController, 'landline');
    addTrackerListener(_descriptionController, 'description');
    addTrackerListener(_startedDateController, 'startedDate');
    addTrackerListener(_landmarkController, 'landmark');
    addTrackerListener(_cityController, 'city');
    addTrackerListener(_stateController, 'state');
    addTrackerListener(_countryController, 'country');
    addTrackerListener(_pincodeController, 'pincode');
    addTrackerListener(_locationLinkController, 'locationLink');
    addTrackerListener(_locationDescriptionController, 'locationDesc');
    addTrackerListener(_checkInController, 'checkIn');
    addTrackerListener(_checkOutController, 'checkOut');
    addTrackerListener(_dueDayController, 'dueDay');
    addTrackerListener(_lateFeeController, 'lateFee');
    addTrackerListener(_upiIdController, 'upiId');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
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
    _facilitySearchController.dispose();
    _upiIdController.dispose();
    super.dispose();
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
    _locationDescriptionController.text =
        widget.pgToEdit!.address.locationDescription ?? '';
    _descriptionController.text = widget.pgToEdit!.description ?? '';

    if (widget.pgToEdit!.pgStartedDate != null &&
        widget.pgToEdit!.pgStartedDate!.isNotEmpty) {
      try {
        _selectedStartedDate = DateTime.parse(widget.pgToEdit!.pgStartedDate!);
        _startedDateController.text = _formatDate(_selectedStartedDate!);
      } catch (e) {
        _startedDateController.text = widget.pgToEdit!.pgStartedDate!;
      }
    }

    _dueDayController.text = widget.pgToEdit!.dueDayOfMonth?.toString() ?? '10';
    _lateFeeController.text =
        widget.pgToEdit!.lateFee?.toStringAsFixed(0) ?? '0';
    _landlineController.text = widget.pgToEdit!.landline ?? '';
    _locationLinkController.text = widget.pgToEdit!.locationLink ?? '';
    _upiIdController.text = widget.pgToEdit!.upiId ?? '';
    _existingQrImage = widget.pgToEdit!.paymentQrImage;
    _capturedLocation = widget.pgToEdit!.location;
    _existingImages = List.from(widget.pgToEdit!.images);

    final type = widget.pgToEdit!.pgType.toLowerCase();
    _selectedPgType =
        {'male': 'Male', 'female': 'Female', 'unisex': 'Unisex'}[type] ??
        'Co-Living';

    _tracker.setOriginal('name', widget.pgToEdit!.name);
    _tracker.setOriginal('landline', widget.pgToEdit!.landline ?? '');
    _tracker.setOriginal('description', widget.pgToEdit!.description ?? '');
    _tracker.setOriginal('startedDate', _startedDateController.text);
    _tracker.setOriginal('landmark', widget.pgToEdit!.address.landmark);
    _tracker.setOriginal('city', widget.pgToEdit!.address.city);
    _tracker.setOriginal('state', widget.pgToEdit!.address.state);
    _tracker.setOriginal('country', widget.pgToEdit!.address.country);
    _tracker.setOriginal(
      'pincode',
      widget.pgToEdit!.address.pincode.toString(),
    );
    _tracker.setOriginal('locationLink', widget.pgToEdit!.locationLink ?? '');
    _tracker.setOriginal(
      'locationDesc',
      widget.pgToEdit!.address.locationDescription ?? '',
    );
    _tracker.setOriginal('checkIn', widget.pgToEdit!.checkInTime);
    _tracker.setOriginal('checkOut', widget.pgToEdit!.checkOutTime);
    _tracker.setOriginal(
      'dueDay',
      widget.pgToEdit!.dueDayOfMonth?.toString() ?? '10',
    );
    _tracker.setOriginal(
      'lateFee',
      widget.pgToEdit!.lateFee?.toStringAsFixed(0) ?? '0',
    );
    _tracker.setOriginal('upiId', widget.pgToEdit!.upiId ?? '');
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
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
                .map((fac) {
                  final facTrimmed = fac.trim().toLowerCase();
                  final found = _facilities.firstWhere((f) {
                    final fName = (f['name'] ?? '').trim().toLowerCase();
                    final fId = (f['id'] ?? '').trim().toLowerCase();
                    return fName == facTrimmed || fId == facTrimmed;
                  }, orElse: () => {'id': ''});
                  return found['id']!;
                })
                .where((id) => id.isNotEmpty)
                .toList();
            _initialFacilityIds = List.from(_selectedFacilityIds);
          }

          _isLoadingDropdowns = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDropdowns = false);
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _isCapturingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Please enable location services.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission is required.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          _cityController.text =
              place.locality ??
              place.subAdministrativeArea ??
              _cityController.text;
          _stateController.text =
              place.administrativeArea ?? _stateController.text;
          _countryController.text = place.country ?? _countryController.text;
          _pincodeController.text = place.postalCode ?? _pincodeController.text;
          _landmarkController.text =
              place.subLocality ?? place.name ?? _landmarkController.text;
        }
      } catch (e) {
        debugPrint('Reverse geocoding error: $e');
      }

      setState(() {
        _capturedLocation = PgLocation(
          type: 'Point',
          coordinates: [position.longitude, position.latitude],
        );
        if (_locationLinkController.text.trim().isEmpty) {
          _locationLinkController.text =
              'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
        }
      });

      _showSnackBar(
        '📍 Location captured successfully!',
        const Color(0xFF10B981),
      );
    } catch (e) {
      _showSnackBar(e.toString(), const Color(0xFFEF4444));
    } finally {
      setState(() => _isCapturingLocation = false);
    }
  }

  void _nextStep() {
    if (!_formKey.currentState!.validate()) return;

    if (_currentStep == 0 && _selectedManagerId == null) {
      _showSnackBar('Please select a manager.', const Color(0xFFEF4444));
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
        if (_currentStep > _maxStepReached) {
          _maxStepReached = _currentStep;
        }
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      });
    } else {
      _submitForm();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFacilityIds.isEmpty) {
      _showSnackBar(
        'Please select at least one facility.',
        const Color(0xFFEF4444),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(pgListingRepositoryProvider);

      final backendPgType =
          {
            'Male': 'male',
            'Female': 'female',
            'Unisex': 'unisex',
          }[_selectedPgType] ??
          'coLiving';

      final addressData = {
        'pincode': int.parse(_pincodeController.text.trim()),
        'landmark': _landmarkController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': _countryController.text.trim(),
        if (_locationDescriptionController.text.trim().isNotEmpty)
          'locationDescription': _locationDescriptionController.text.trim(),
      };

      List<String> finalImages = [];
      for (String img in _existingImages) {
        if (img.contains('.com/')) {
          finalImages.add(img.split('.com/').last.split('?').first);
        } else {
          finalImages.add(img.split('?').first);
        }
      }

      for (var file in _selectedImages) {
        final bytes = await file.readAsBytes();
        final uploadData = await repository.getUploadUrl(
          file.name,
          'image/jpeg',
        );
        final uploadUrl = uploadData['uploadUrl']!;
        await repository.uploadFileToS3(uploadUrl, bytes, 'image/jpeg');
        finalImages.add(uploadData['key']!);
      }

      String? finalQrImageKey;
      if (_existingQrImage != null && _existingQrImage!.isNotEmpty) {
        finalQrImageKey = _existingQrImage!.contains('.com/')
            ? _existingQrImage!.split('.com/').last.split('?').first
            : _existingQrImage!.split('?').first;
      }

      if (_qrImageFile != null) {
        final bytes = await _qrImageFile!.readAsBytes();
        final uploadData = await repository.getPaymentQrUploadUrl(
          _qrImageFile!.name,
          'image/jpeg',
        );
        final uploadUrl = uploadData['uploadUrl']!;
        await repository.uploadFileToS3(uploadUrl, bytes, 'image/jpeg');
        finalQrImageKey = uploadData['key']!;
      }

      final pgData = {
        'name': _nameController.text.trim(),
        'address': addressData,
        'images': finalImages,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : 'A comfortable and secure PG stay with all essential amenities.',
        'managerId': _selectedManagerId,
        'pgType': backendPgType,
        'facilities': _selectedFacilityIds,
        'checkInTime': _checkInController.text.trim(),
        'checkOutTime': _checkOutController.text.trim(),
        'dueDayOfMonth': int.tryParse(_dueDayController.text.trim()) ?? 10,
        'lateFee': double.tryParse(_lateFeeController.text.trim()) ?? 0.0,
        'pgStartedDate':
            _selectedStartedDate?.toIso8601String() ??
            _startedDateController.text.trim(),
        if (_landlineController.text.trim().isNotEmpty)
          'landline': _landlineController.text.trim(),
        if (_locationLinkController.text.trim().isNotEmpty)
          'locationLink': _locationLinkController.text.trim(),
        if (_capturedLocation != null) 'location': _capturedLocation!.toJson(),
        if (_upiIdController.text.trim().isNotEmpty)
          'upiId': _upiIdController.text.trim(),
        if (finalQrImageKey != null) 'paymentQrKey': finalQrImageKey,
      };

      if (widget.pgToEdit != null) {
        List<String> changedFields = [];
        final pg = widget.pgToEdit!;

        bool safeCompare(dynamic a, dynamic b) {
          if (a == b) return true;
          if ((a == null || a == '') && (b == null || b == '')) return true;
          return false;
        }

        if (!safeCompare(pgData['name'], pg.name)) changedFields.add('name');
        if (!safeCompare(pgData['pgType'], pg.pgType))
          changedFields.add('pgType');
        if (!safeCompare(pgData['managerId'], pg.managerId))
          changedFields.add('managerId');
        if (!safeCompare(pgData['description'], pg.description))
          changedFields.add('description');
        if (!safeCompare(pgData['checkInTime'], pg.checkInTime))
          changedFields.add('checkInTime');
        if (!safeCompare(pgData['checkOutTime'], pg.checkOutTime))
          changedFields.add('checkOutTime');
        if (!safeCompare(pgData['dueDayOfMonth'], pg.dueDayOfMonth))
          changedFields.add('dueDayOfMonth');
        if (!safeCompare(pgData['lateFee'], pg.lateFee))
          changedFields.add('lateFee');
        if (!safeCompare(pgData['landline'], pg.landline))
          changedFields.add('landline');
        if (!safeCompare(pgData['locationLink'], pg.locationLink))
          changedFields.add('locationLink');
        if (!safeCompare(pgData['upiId'], pg.upiId)) changedFields.add('upiId');
        if (!safeCompare(pgData['paymentQrKey'], pg.paymentQrImage))
          changedFields.add('paymentQrKey');

        if (pgData['pgStartedDate'] != pg.pgStartedDate) {
          try {
            final d1 = DateTime.parse(pgData['pgStartedDate'] as String);
            final d2 = DateTime.parse(pg.pgStartedDate!);
            if (!d1.isAtSameMomentAs(d2)) changedFields.add('pgStartedDate');
          } catch (e) {
            changedFields.add('pgStartedDate');
          }
        }

        if (_capturedLocation != null) changedFields.add('location');

        final addr = pgData['address'] as Map;
        if (!safeCompare(addr['pincode'], pg.address.pincode))
          changedFields.add('address.pincode');
        if (!safeCompare(addr['landmark'], pg.address.landmark))
          changedFields.add('address.landmark');
        if (!safeCompare(addr['city'], pg.address.city))
          changedFields.add('address.city');
        if (!safeCompare(addr['state'], pg.address.state))
          changedFields.add('address.state');
        if (!safeCompare(addr['country'], pg.address.country))
          changedFields.add('address.country');
        if (!safeCompare(
          addr['locationDescription'],
          pg.address.locationDescription,
        ))
          changedFields.add('address.locationDescription');

        bool facilitiesChanged =
            _selectedFacilityIds.length != _initialFacilityIds.length ||
            _selectedFacilityIds.any((id) => !_initialFacilityIds.contains(id));
        if (facilitiesChanged) changedFields.add('facilities');

        if (_selectedImages.isNotEmpty) changedFields.add('selectedImages');
        if (_existingImages.length != pg.images.length)
          changedFields.add('existingImages');

        if (changedFields.isEmpty) {
          _showSnackBar('No changes made to update.', const Color(0xFF3B82F6));
          if (mounted) {
            setState(() => _isSubmitting = false);
            Navigator.pop(context);
          }
          return;
        } else {
          print('Changed fields: $changedFields');
        }

        await repository.updatePG(widget.pgToEdit!.id, pgData);
        _showSnackBar(
          '✅ Property updated successfully!',
          const Color(0xFF10B981),
        );
      } else {
        await repository.addPG(pgData);
        _showSnackBar(
          '✅ Property created successfully!',
          const Color(0xFF10B981),
        );
      }

      ref.invalidate(ownerPgsProvider);
      ref.invalidate(pgListProvider);
      ref.invalidate(discoverPgProvider);

      if (widget.pgToEdit != null) {
        ref.invalidate(pgDetailsProvider(widget.pgToEdit!.id));
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showSnackBar(e.toString(), const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                color == const Color(0xFF10B981)
                    ? Icons.check_circle_rounded
                    : Icons.error_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar(
          title: widget.pgToEdit != null ? 'Edit Property' : 'Add Property',
          showBackButton: true,
          pinnedSCurve: true,
          isCompact: true,
          centerTitle: true,
          onLeadingPressed: _isSubmitting ? () {} : null,
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 80 + MediaQuery.of(context).padding.top + 8,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildModernStepper(),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (index) {
                            setState(() => _currentStep = index);
                          },
                          children: [
                            _buildStep1General(),
                            _buildStep2Location(),
                            _buildStep3Features(),
                          ],
                        ),
                      ),
                      _buildModernBottomNav(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== MODERN STEPPER ====================
  Widget _buildModernStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalSteps, (index) {
          return Expanded(child: _buildModernStep(index));
        }),
      ),
    );
  }

  Widget _buildModernStep(int index) {
    final isActive = _currentStep == index;
    final isCompleted = _currentStep > index;
    final labels = ['Info', 'Location', 'Amenities'];
    final icons = [
      Icons.home_outlined,
      Icons.location_on_outlined,
      Icons.workspace_premium_outlined,
    ];

    return GestureDetector(
      onTap: () {
        if (index <= _maxStepReached && index != _currentStep) {
          if (index > _currentStep) {
            if (!_formKey.currentState!.validate()) return;
            if (_currentStep == 0 && _selectedManagerId == null) {
              _showSnackBar(
                'Please select a manager.',
                const Color(0xFFEF4444),
              );
              return;
            }
          }
          setState(() {
            _currentStep = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
            );
          });
        }
      },
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF03045E)
                        : isActive
                        ? const Color(0xFF03045E).withOpacity(0.3)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              if (index < _totalSteps - 1) ...[const SizedBox(width: 0)],
            ],
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 42 : 36,
            height: isActive ? 42 : 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive || isCompleted
                  ? const Color(0xFF03045E)
                  : Colors.white,
              border: Border.all(
                color: isActive || isCompleted
                    ? Colors.transparent
                    : const Color(0xFFE5E7EB),
                width: 2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF03045E).withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    )
                  : Icon(
                      icons[index],
                      color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                      size: isActive ? 20 : 16,
                    ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: GoogleFonts.plusJakartaSans(
              color: isActive
                  ? const Color(0xFF03045E)
                  : const Color(0xFF6B7280),
              fontSize: isActive ? 11 : 9,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.4,
            ),
            child: Text(labels[index]),
          ),
        ],
      ),
    );
  }

  // ==================== STEP 1: GENERAL ====================
  Widget _buildStep1General() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGlassCard(
            children: [
              _buildSectionHeader(
                Icons.home_work_outlined,
                'Property Details',
                'Tell us about your space',
              ),
              const SizedBox(height: 12),
              _buildModernTextField(
                label: 'Property Name',
                controller: _nameController,
                hint: 'Enter property name',
                icon: Icons.home_outlined,
                required: true,
              ),
              const SizedBox(height: 10),
              _buildModernDropdown(
                label: 'PG Type',
                value: _selectedPgType,
                items: ['Male', 'Female', 'Unisex', 'Co-Living'],
                onChanged: (v) => setState(() => _selectedPgType = v!),
                icon: Icons.people_outline,
                required: true,
              ),
              const SizedBox(height: 10),
              _buildModernSearchableDropdown(
                label: 'Manager',
                value: _selectedManagerId,
                items: _isLoadingDropdowns
                    ? []
                    : _managers.map((e) => e['id']!).toList(),
                itemLabel: (id) {
                  if (_isLoadingDropdowns || _managers.isEmpty)
                    return 'Loading...';
                  final match = _managers.where((m) => m['id'] == id).toList();
                  return match.isNotEmpty ? match.first['name']! : 'Unknown';
                },
                onChanged: _isLoadingDropdowns
                    ? (v) {}
                    : (v) => setState(() => _selectedManagerId = v),
                hint: _isLoadingDropdowns ? 'Loading...' : 'Search manager...',
                icon: Icons.person_outline,
                required: true,
              ),
              const SizedBox(height: 10),
              _buildModernTextField(
                label: 'Contact',
                controller: _landlineController,
                hint: 'Enter contact number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              _buildModernTextField(
                label: 'Description',
                controller: _descriptionController,
                hint: 'Describe your property...',
                icon: Icons.description_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 10),
              _buildModernDatePicker(),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==================== STEP 2: LOCATION ====================
  Widget _buildStep2Location() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGlassCard(
            children: [
              _buildSectionHeader(
                Icons.location_on_outlined,
                'Location',
                'Help guests find you',
              ),
              const SizedBox(height: 12),
              _buildModernTextField(
                label: 'Landmark',
                controller: _landmarkController,
                hint: 'Near metro station',
                icon: Icons.place_outlined,
                required: true,
              ),
              const SizedBox(height: 10),
              _buildModernTextField(
                label: 'City',
                controller: _cityController,
                hint: 'Pune',
                icon: Icons.location_city_outlined,
                required: true,
              ),
              const SizedBox(height: 10),
              _buildModernTextField(
                label: 'State',
                controller: _stateController,
                hint: 'Maharashtra',
                icon: Icons.map_outlined,
                required: true,
              ),
              const SizedBox(height: 10),
              _buildModernTextField(
                label: 'Country',
                controller: _countryController,
                hint: 'India',
                icon: Icons.public_outlined,
              ),
              const SizedBox(height: 10),
              _buildModernTextField(
                label: 'Pincode',
                controller: _pincodeController,
                hint: '411001',
                icon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
                required: true,
              ),
              const SizedBox(height: 10),
              _buildModernTextField(
                label: 'Location Description',
                controller: _locationDescriptionController,
                hint: 'Enter description',
                icon: Icons.info_outline,
              ),
              const SizedBox(height: 10),
              _buildLocationCard(),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==================== STEP 3: FEATURES ====================
  Widget _buildStep3Features() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGlassCard(
            children: [
              _buildSectionHeader(
                Icons.access_time_outlined,
                'Timings',
                'Set property guidelines',
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      label: 'Check-In Time',
                      controller: _checkInController,
                      hint: '12:00 PM',
                      icon: Icons.login_outlined,
                      readOnly: true,
                      onTap: () => _pickTime(_checkInController),
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernTextField(
                      label: 'Check-Out Time',
                      controller: _checkOutController,
                      hint: '11:00 AM',
                      icon: Icons.logout_outlined,
                      readOnly: true,
                      onTap: () => _pickTime(_checkOutController),
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      label: 'Due Day',
                      controller: _dueDayController,
                      hint: '10',
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernTextField(
                      label: 'Late Fee (₹)',
                      controller: _lateFeeController,
                      hint: '₹0',
                      icon: Icons.currency_rupee_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGlassCard(
            children: [
              _buildSectionHeader(
                Icons.room_preferences_outlined,
                'Facilities',
                'Select amenities',
              ),
              const SizedBox(height: 12),
              _isLoadingDropdowns
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF03045E),
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : _buildFacilitiesGrid(),
            ],
          ),
          const SizedBox(height: 12),
          _buildGlassCard(
            children: [
              _buildSectionHeader(
                Icons.photo_library_outlined,
                'Images',
                'Upload property photos',
              ),
              const SizedBox(height: 12),
              _buildImageUploadSection(),
            ],
          ),
          const SizedBox(height: 12),
          _buildGlassCard(
            children: [
              _buildSectionHeader(
                Icons.payments_outlined,
                'Payment Settings',
                'Provide scanner and UPI ID',
              ),
              const SizedBox(height: 12),
              _buildPaymentSettings(),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==================== REUSABLE COMPONENTS ====================

  Widget _buildGlassCard({required List<Widget> children}) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primaryColor;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: primaryColor.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primaryColor;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.1),
                primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF1A1A2E),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF6B7280),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== UPDATED MODERN TEXT FIELD ====================
  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    IconData? icon,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    return ModernTextFieldWidget(
      label: label,
      controller: controller,
      hint: hint,
      icon: icon,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      keyboardType: keyboardType,
      required: required,
    );
  }

  // ==================== UPDATED MODERN DROPDOWN ====================
  Widget _buildModernDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData? icon,
    bool required = false,
  }) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: context.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark ? const Color(0xFF2A2A3E) : Colors.white,
                isDark ? const Color(0xFF1E1E32) : const Color(0xFFFAFAFE),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : primaryColor.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: primaryColor.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            validator: (val) {
              if (required && (val == null || val.trim().isEmpty)) {
                return 'This field is required';
              }
              return null;
            },
            dropdownColor: context.colorScheme.surface,
            style: GoogleFonts.plusJakartaSans(
              color: context.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            icon: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: primaryColor,
                size: 20,
              ),
            ),
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16, right: 10),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor.withOpacity(0.12),
                              primaryColor.withOpacity(0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: primaryColor, size: 18),
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: context.surfaceBorder,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: context.surfaceBorder,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 2,
                ),
              ),
              errorStyle: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFEF4444),
                fontSize: 11,
              ),
            ),
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                      style: GoogleFonts.plusJakartaSans(
                        color: context.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  // ==================== MODERN SEARCHABLE DROPDOWN ====================
  Widget _buildModernSearchableDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? hint,
    IconData? icon,
    String Function(String)? itemLabel,
    bool required = false,
  }) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: context.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        MouseRegion(
          cursor: items.isEmpty
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              if (items.isEmpty) return;
              _showElegantBottomSheet(
                context: context,
                items: items,
                value: value,
                onChanged: onChanged,
                itemLabel: itemLabel,
                isDark: isDark,
                primaryColor: primaryColor,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.only(
                left: 16,
                right: 14,
                top: 8,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.colorScheme.surface,
                    context.theme.scaffoldBackgroundColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.surfaceBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.2)
                        : context.primaryColor.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: primaryColor.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.12),
                            primaryColor.withOpacity(0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: primaryColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      (value != null && value.isNotEmpty)
                          ? (itemLabel != null ? itemLabel(value) : value)
                          : (hint ?? 'Select an option'),
                      style: GoogleFonts.plusJakartaSans(
                        color: (value != null && value.isNotEmpty)
                            ? (isDark ? Colors.white : const Color(0xFF1A1A2E))
                            : (isDark
                                  ? const Color(0xFF6B6B80)
                                  : const Color(0xFF9CA3AF)),
                        fontSize: 14,
                        fontWeight: (value != null && value.isNotEmpty)
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: 0.0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (items.isEmpty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 12,
                  color: const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 4),
                Text(
                  'No options available',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ==================== ELEGANT BOTTOM SHEET ====================
  void _showElegantBottomSheet({
    required BuildContext context,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
    String Function(String)? itemLabel,
    required bool isDark,
    required Color primaryColor,
  }) {
    String searchQuery = '';
    final TextEditingController searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredItems = items.where((item) {
              final labelStr = itemLabel != null ? itemLabel(item) : item;
              return labelStr.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF1E1E32), const Color(0xFF0F0F1A)]
                      : [Colors.white, const Color(0xFFF8F9FF)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 3.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withOpacity(0.85),
                          primaryColor.withOpacity(0.65),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Option',
                          style: GoogleFonts.plusJakartaSans(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withOpacity(0.1),
                                primaryColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${filteredItems.length}',
                            style: GoogleFonts.plusJakartaSans(
                              color: primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A3E)
                            : const Color(0xFFF1F4F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3A3A4E)
                              : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Icon(
                            Icons.search_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              onChanged: (val) =>
                                  setState(() => searchQuery = val),
                              style: GoogleFonts.plusJakartaSans(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search options...',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF9CA3AF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          if (searchQuery.isNotEmpty)
                            IconButton(
                              onPressed: () {
                                searchController.clear();
                                setState(() => searchQuery = '');
                              },
                              icon: Icon(
                                Icons.close_rounded,
                                color: const Color(0xFF9CA3AF),
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  color: const Color(0xFF9CA3AF),
                                  size: 40,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No results found',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF9CA3AF),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Try adjusting your search',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFFB0B0B0),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            itemCount: filteredItems.length,
                            separatorBuilder: (context, index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              height: 1,
                              color: isDark
                                  ? const Color(0xFF2A2A3E)
                                  : const Color(0xFFE5E7EB).withOpacity(0.5),
                            ),
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              final isSelected = item == value;

                              return GestureDetector(
                                onTap: () {
                                  onChanged(item);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark
                                              ? primaryColor.withOpacity(0.15)
                                              : primaryColor.withOpacity(0.08))
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? Border.all(
                                            color: primaryColor.withOpacity(
                                              0.3,
                                            ),
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: isSelected
                                              ? LinearGradient(
                                                  colors: [
                                                    primaryColor,
                                                    primaryColor.withOpacity(
                                                      0.7,
                                                    ),
                                                  ],
                                                )
                                              : null,
                                          color: isSelected
                                              ? null
                                              : (isDark
                                                    ? const Color(0xFF2A2A3E)
                                                    : const Color(0xFFF1F4F9)),
                                          border: Border.all(
                                            color: isSelected
                                                ? primaryColor
                                                : (isDark
                                                      ? const Color(0xFF3A3A4E)
                                                      : const Color(
                                                          0xFFE5E7EB,
                                                        )),
                                            width: 2,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 14,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          itemLabel != null
                                              ? itemLabel(item)
                                              : item,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: isSelected
                                                ? primaryColor
                                                : (isDark
                                                      ? Colors.white
                                                      : const Color(
                                                          0xFF1A1A2E,
                                                        )),
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                primaryColor.withOpacity(0.1),
                                                primaryColor.withOpacity(0.05),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Text(
                                            'SELECTED',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: primaryColor,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==================== UPDATED MODERN DATE PICKER ====================
  Widget _buildModernDatePicker() {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Started Date',
              style: GoogleFonts.plusJakartaSans(
                color: context.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _pickDate,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.only(
                left: 16,
                right: 14,
                top: 8,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.colorScheme.surface,
                    context.theme.scaffoldBackgroundColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.surfaceBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.2)
                        : context.primaryColor.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: primaryColor.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.12),
                          primaryColor.withOpacity(0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      color: primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _startedDateController.text.isNotEmpty
                          ? _startedDateController.text
                          : 'Select Date',
                      style: GoogleFonts.plusJakartaSans(
                        color: _startedDateController.text.isNotEmpty
                            ? (isDark ? Colors.white : const Color(0xFF1A1A2E))
                            : (isDark
                                  ? const Color(0xFF6B6B80)
                                  : const Color(0xFF9CA3AF)),
                        fontSize: 14,
                        fontWeight: _startedDateController.text.isNotEmpty
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: 0.0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== LOCATION CARD ====================
  Widget _buildLocationCard() {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primaryColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.04),
            primaryColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCapturingLocation
                  ? null
                  : (_capturedLocation == null
                        ? _captureLocation
                        : () async {
                            final url = Uri.tryParse(
                              _locationLinkController.text.trim(),
                            );
                            if (url != null && await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              final fallbackUrl = Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=${_capturedLocation!.coordinates[1]},${_capturedLocation!.coordinates[0]}',
                              );
                              if (await canLaunchUrl(fallbackUrl)) {
                                await launchUrl(fallbackUrl);
                              }
                            }
                          }),
              icon: _isCapturingLocation
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _capturedLocation != null
                          ? Icons.map_rounded
                          : Icons.my_location_rounded,
                      size: 20,
                    ),
              label: Text(
                _isCapturingLocation
                    ? 'Capturing...'
                    : (_capturedLocation != null
                          ? 'Show on Map'
                          : 'Get Current Location'),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _capturedLocation != null
                    ? const Color(0xFF10B981)
                    : primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                shadowColor: _capturedLocation != null
                    ? const Color(0xFF10B981).withOpacity(0.3)
                    : primaryColor.withOpacity(0.3),
              ),
            ),
          ),
          if (_capturedLocation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Location locked at ${_capturedLocation!.coordinates[1].toStringAsFixed(4)}° N, ${_capturedLocation!.coordinates[0].toStringAsFixed(4)}° E',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF1A1A2E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  // ==================== PAYMENT SETTINGS ====================
  Widget _buildPaymentSettings() {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModernTextField(
          label: 'UPI ID (for Direct Pay)',
          controller: _upiIdController,
          hint: 'e.g. owner@upi',
        ),
        const SizedBox(height: 10),
        Text(
          'Payment QR Code Image',
          style: GoogleFonts.plusJakartaSans(
            color: context.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            try {
              final picked = await _picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 50,
              );
              if (picked != null) {
                setState(() {
                  _qrImageFile = picked;
                });
              }
            } catch (e) {
              _showSnackBar('Error picking image: $e', const Color(0xFFEF4444));
            }
          },
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF3A3A4E)
                    : const Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            child: _qrImageFile != null || _existingQrImage != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _qrImageFile != null
                            ? FutureBuilder<Uint8List>(
                                future: _qrImageFile!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              )
                            : Image.network(
                                _existingQrImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                              ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () async {
                            if (_existingQrImage != null) {
                              try {
                                await ref
                                    .read(pgListingRepositoryProvider)
                                    .deleteFile(_existingQrImage!);
                                _showSnackBar(
                                  'QR code image deleted successfully',
                                  const Color(0xFF10B981),
                                );
                              } catch (e) {
                                _showSnackBar(
                                  'Failed to delete QR image: $e',
                                  const Color(0xFFEF4444),
                                );
                                return;
                              }
                            }
                            setState(() {
                              _qrImageFile = null;
                              _existingQrImage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Color(0xFFEF4444),
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: isDark
                              ? const Color(0xFFA5B4FC)
                              : primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ADD IMAGE',
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark
                              ? const Color(0xFFA5B4FC)
                              : primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '* Upload a high-quality payment QR scanner image. JPEG, PNG, WEBP files under 5MB are supported.',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF6B7280),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ==================== FACILITIES GRID ====================
  Widget _buildFacilitiesGrid() {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primaryColor;

    final searchQuery = _facilitySearchController.text.toLowerCase();
    final filteredFacilities = _facilities.where((fac) {
      return fac['name']!.toLowerCase().contains(searchQuery);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedFacilityIds.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedFacilityIds.map((id) {
              final fac = _facilities.firstWhere(
                (f) => f['id'] == id,
                orElse: () => {'id': id, 'name': 'Unknown'},
              );
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? primaryColor.withOpacity(0.4)
                      : primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fac['name']!,
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? const Color(0xFFA5B4FC) : primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFacilityIds.remove(id);
                        });
                      },
                      child: Icon(
                        Icons.close_rounded,
                        size: 12,
                        color: isDark ? const Color(0xFFA5B4FC) : primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.surfaceBorder, width: 1.5),
          ),
          child: TextField(
            controller: _facilitySearchController,
            onTap: () {
              setState(() {
                _isFacilityListExpanded = true;
              });
            },
            onChanged: (value) => setState(() {}),
            style: GoogleFonts.plusJakartaSans(
              color: context.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              suffixIcon: IconButton(
                icon: Icon(
                  _isFacilityListExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isFacilityListExpanded = !_isFacilityListExpanded;
                  });
                },
              ),
              hintText: 'Click or type to search facilities...',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF9CA3AF),
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
        Text(
          '${_selectedFacilityIds.length} facilities selected',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF6B7280),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),

        if (_isFacilityListExpanded)
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2A2A3E)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredFacilities.length,
                itemBuilder: (context, index) {
                  final fac = filteredFacilities[index];
                  final isSelected = _selectedFacilityIds.contains(fac['id']);

                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? const Color(0xFF2A2A3E)
                              : const Color(0xFFE5E7EB),
                          width: index == filteredFacilities.length - 1 ? 0 : 1,
                        ),
                      ),
                    ),
                    child: CheckboxListTile(
                      value: isSelected,
                      title: Text(
                        fac['name']!,
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      activeColor: primaryColor,
                      checkColor: Colors.white,
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF4B5563)
                            : const Color(0xFF9CA3AF),
                        width: 1.5,
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedFacilityIds.add(fac['id']!);
                          } else {
                            _selectedFacilityIds.remove(fac['id']!);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  // ==================== IMAGE UPLOAD SECTION ====================
  Widget _buildImageUploadSection() {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount:
              _existingImages.length +
              _selectedImages.length +
              (_existingImages.length + _selectedImages.length < 10 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < _existingImages.length) {
              String img = _existingImages[index];
              return _buildModernImageTile(
                index: index,
                onTap: () => _showFullScreenGallery(index),
                imageWidget: img.startsWith('data:image')
                    ? Image.memory(
                        base64Decode(img.split(',').last),
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        img,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xFFF9FAFB),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor,
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                onDelete: () async {
                  try {
                    final repo = ref.read(pgListingRepositoryProvider);
                    await repo.deleteFile(img);
                    _showSnackBar(
                      'PG image deleted successfully from S3',
                      const Color(0xFF10B981),
                    );
                  } catch (e) {
                    _showSnackBar(
                      'Failed to delete image: $e',
                      const Color(0xFFEF4444),
                    );
                    return;
                  }
                  setState(() {
                    _existingImages.removeAt(index);
                  });
                },
              );
            } else if (index <
                _existingImages.length + _selectedImages.length) {
              int selectedIdx = index - _existingImages.length;
              XFile file = _selectedImages[selectedIdx];
              return _buildModernImageTile(
                index: index,
                onTap: () => _showFullScreenGallery(index),
                imageWidget: FutureBuilder<Uint8List>(
                  future: file.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    }
                    return Container(
                      color: const Color(0xFFF9FAFB),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF03045E),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                onDelete: () {
                  setState(() {
                    _selectedImages.removeAt(selectedIdx);
                  });
                },
              );
            } else {
              return InkWell(
                onTap: () async {
                  try {
                    final List<XFile> picked = await _picker.pickMultiImage(
                      imageQuality: 30,
                      maxWidth: 600,
                      maxHeight: 600,
                    );
                    if (picked.isNotEmpty) {
                      setState(() {
                        _selectedImages.addAll(picked);
                      });
                    }
                  } catch (e) {
                    _showSnackBar(
                      'Error picking images: $e',
                      const Color(0xFFEF4444),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add Photo',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF6B7280),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: const Color(0xFF6B7280),
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'JPEG, PNG, WEBP • Max 10 images • Recommended: 600x600',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== IMAGE TILE ====================
  Widget _buildModernImageTile({
    required int index,
    required VoidCallback onTap,
    required Widget imageWidget,
    required VoidCallback onDelete,
    bool isLoading = false,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: onTap,
                child: Hero(tag: 'hero_image_$index', child: imageWidget),
              ),
              if (isLoading)
                Container(
                  color: Colors.white.withOpacity(0.7),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF03045E),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: onDelete,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== BOTTOM NAVIGATION ====================
  Widget _buildModernBottomNav() {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primaryColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: primaryColor.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _isSubmitting
                    ? null
                    : (_currentStep == 0
                          ? () => Navigator.pop(context)
                          : _prevStep),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_currentStep > 0)
                      const Icon(
                        Icons.arrow_circle_left_outlined,
                        color: Color(0xFF03045E),
                        size: 14,
                      ),
                    if (_currentStep > 0) const SizedBox(width: 4),
                    Text(
                      _currentStep == 0 ? 'Cancel' : 'Back',
                      style: GoogleFonts.plusJakartaSans(
                        color: _currentStep == 0
                            ? const Color(0xFF6B7280)
                            : primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    _isSubmitting ||
                        (widget.pgToEdit != null &&
                            _currentStep == _totalSteps - 1 &&
                            !_hasChanges)
                    ? null
                    : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: primaryColor.withOpacity(0.3),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep < _totalSteps - 1
                                ? 'Continue'
                                : (widget.pgToEdit != null
                                      ? 'Update'
                                      : 'Create'),
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_currentStep < _totalSteps - 1) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_circle_right_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final primaryColor = const Color(0xFF03045E);
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedStartedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              surface: Colors.white,
              onSurface: Color(0xFF1A1A2E),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _selectedStartedDate = date;
        _startedDateController.text = _formatDate(date);
      });
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final primaryColor = const Color(0xFF03045E);
    TimeOfDay initialTime = TimeOfDay.now();

    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(' ');
        if (parts.length == 2) {
          final timeParts = parts[0].split(':');
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);
          if (parts[1].toUpperCase() == 'PM' && hour < 12) hour += 12;
          if (parts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;
          initialTime = TimeOfDay(hour: hour, minute: minute);
        }
      } catch (_) {}
    }

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              surface: Colors.white,
              onSurface: const Color(0xFF1A1A2E),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      if (!mounted) return;
      setState(() {
        controller.text = time.format(context);
      });
    }
  }

  void _showFullScreenGallery(int initialIndex) {
    final pageController = PageController(initialPage: initialIndex);
    final totalImages = _existingImages.length + _selectedImages.length;
    int currentIndex = initialIndex;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(dialogContext),
                  child: Container(
                    color: Colors.black.withOpacity(0.9),
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: totalImages,
                      onPageChanged: (index) {
                        setStateDialog(() {
                          currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final isExisting = index < _existingImages.length;

                        Widget imageWidget;
                        if (isExisting) {
                          String img = _existingImages[index];
                          imageWidget = img.startsWith('data:image')
                              ? Image.memory(
                                  base64Decode(img.split(',').last),
                                  fit: BoxFit.contain,
                                )
                              : Image.network(
                                  img,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                        size: 40,
                                      ),
                                );
                        } else {
                          XFile file =
                              _selectedImages[index - _existingImages.length];
                          imageWidget = FutureBuilder<Uint8List>(
                            future: file.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.contain,
                                );
                              }
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          );
                        }

                        return InteractiveViewer(
                          panEnabled: true,
                          minScale: 0.5,
                          maxScale: 4,
                          child: Center(
                            child: Hero(
                              tag: 'hero_image_$index',
                              child: imageWidget,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
                if (totalImages > 1)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(totalImages, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: currentIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: currentIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

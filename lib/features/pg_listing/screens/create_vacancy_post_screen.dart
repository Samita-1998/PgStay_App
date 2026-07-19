import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:pgstay/features/pg_listing/widgets/pg_image_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';
import 'package:pgstay/core/utils/change_tracker.dart';

class CreateVacancyPostScreen extends ConsumerStatefulWidget {
  final PgPost? existingPost;

  const CreateVacancyPostScreen({super.key, this.existingPost});

  @override
  ConsumerState<CreateVacancyPostScreen> createState() =>
      _CreateVacancyPostScreenState();
}

class _CreateVacancyPostScreenState
    extends ConsumerState<CreateVacancyPostScreen>
    with SingleTickerProviderStateMixin {
  // ─── State ──────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _vacancyController = TextEditingController();
  final _maleVacancyController = TextEditingController();
  final _femaleVacancyController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  DateTime? _availableFrom;
  bool _isSubmitting = false;
  bool _isActive = true;
  List<String> _existingImages = [];
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  PgModel? _selectedPg;
  List<dynamic> _pgRooms = [];
  bool _isLoadingRooms = false;

  int? _pgTotalVacancy;
  double? _pgMinPrice;
  double? _pgMaxPrice;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final PageController _pageController = PageController();
  int _currentStep = 0;
  int _maxStepReached = 0;
  final int _totalSteps = 3;

  final Map<String, int> _occupancyRoomCount = {
    'single': 0,
    'double': 0,
    'triple': 0,
    'four': 0,
    'other': 0,
  };
  final Map<String, int> _occupancyBedCount = {
    'single': 0,
    'double': 0,
    'triple': 0,
    'four': 0,
    'other': 0,
  };
  final Map<String, bool> _occupancySelected = {
    'single': false,
    'double': false,
    'triple': false,
    'four': false,
    'other': false,
  };

  bool get _isUnisex {
    final t = _selectedPg?.pgType.toLowerCase() ?? '';
    return t.contains('coliving') ||
        t.contains('co-living') ||
        t.contains('unisex');
  }

  bool get _isEditMode => widget.existingPost != null;

  bool get _hasChanges => _tracker.hasChanges || _untrackedHasChanges;
  late final ChangeTracker _tracker;

  bool get _untrackedHasChanges {
    if (widget.existingPost == null) return true;
    final post = widget.existingPost!;

    if (_isActive != post.isActive) return true;

    if (_selectedImages.isNotEmpty) return true;
    if (_existingImages.length != post.images.length) return true;

    if (post.availableFrom != null && _availableFrom != null) {
      try {
        final d = DateTime.parse(post.availableFrom!);
        if (d.year != _availableFrom!.year ||
            d.month != _availableFrom!.month ||
            d.day != _availableFrom!.day) {
          return true;
        }
      } catch (_) {
        return true;
      }
    } else if (post.availableFrom != null || _availableFrom != null) {
      return true;
    }

    final originalTypes = post.occupancyTypes
        .map((e) => e.toLowerCase())
        .toList();
    final currentTypes = _occupancySelected.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    if (originalTypes.length != currentTypes.length) return true;
    for (final t in currentTypes) {
      if (!originalTypes.contains(t)) return true;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();

    if (_isEditMode) {
      _initEditMode();
      _maxStepReached = _totalSteps - 1;
    }

    _tracker = ChangeTracker(
      onStateChanged: () {
        if (mounted && _isEditMode && _currentStep == _totalSteps - 1) {
          setState(() {});
        }
      },
    );

    final listener = () {
      if (mounted && _isEditMode && _currentStep == _totalSteps - 1) {
        setState(() {});
      }
    };

    void addTrackerListener(TextEditingController ctrl, String key) {
      ctrl.addListener(() {
        _tracker.updateValue(key, ctrl.text.trim());
        listener();
      });
    }

    addTrackerListener(_titleController, 'title');
    addTrackerListener(_descController, 'desc');
    addTrackerListener(_vacancyController, 'vacancy');
    addTrackerListener(_maleVacancyController, 'male');
    addTrackerListener(_femaleVacancyController, 'female');
    addTrackerListener(_minPriceController, 'min');
    addTrackerListener(_maxPriceController, 'max');
  }

  void _initEditMode() {
    final post = widget.existingPost!;
    _titleController.text = post.title;
    _descController.text = post.description;

    _vacancyController.text = post.vacancyCount.toString();
    if (post.maleVacancyCount != null) {
      _maleVacancyController.text = post.maleVacancyCount.toString();
    }
    if (post.femaleVacancyCount != null) {
      _femaleVacancyController.text = post.femaleVacancyCount.toString();
    }

    if (post.minPrice != null)
      _minPriceController.text = post.minPrice.toString();
    if (post.maxPrice != null)
      _maxPriceController.text = post.maxPrice.toString();

    if (post.availableFrom != null) {
      try {
        _availableFrom = DateTime.parse(post.availableFrom!);
      } catch (_) {}
    }

    for (final t in post.occupancyTypes) {
      final key = t.toLowerCase();
      if (_occupancySelected.containsKey(key)) {
        _occupancySelected[key] = true;
      }
    }
    _isActive = post.isActive;
    _existingImages = List.from(post.images);

    _tracker.setOriginal('title', post.title);
    _tracker.setOriginal('desc', post.description);
    _tracker.setOriginal('vacancy', post.vacancyCount.toString());
    _tracker.setOriginal('male', post.maleVacancyCount?.toString() ?? '');
    _tracker.setOriginal('female', post.femaleVacancyCount?.toString() ?? '');
    _tracker.setOriginal('min', post.minPrice?.toString() ?? '');
    _tracker.setOriginal('max', post.maxPrice?.toString() ?? '');
  }

  int get _totalVacancy {
    if (_isUnisex) {
      return (int.tryParse(_maleVacancyController.text) ?? 0) +
          (int.tryParse(_femaleVacancyController.text) ?? 0);
    }
    return int.tryParse(_vacancyController.text) ?? 0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _vacancyController.dispose();
    _maleVacancyController.dispose();
    _femaleVacancyController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _onPgSelected(
    PgModel pg, {
    bool isInitialization = false,
  }) async {
    setState(() {
      _selectedPg = pg;
      _isLoadingRooms = true;
      for (final k in _occupancyRoomCount.keys) {
        _occupancyRoomCount[k] = 0;
        _occupancyBedCount[k] = 0;
        if (!isInitialization) _occupancySelected[k] = false;
      }
      if (!isInitialization) {
        _minPriceController.clear();
        _maxPriceController.clear();
        _vacancyController.clear();
        _maleVacancyController.clear();
        _femaleVacancyController.clear();
      }
      _pgTotalVacancy = null;
      _pgMinPrice = null;
      _pgMaxPrice = null;
    });

    try {
      final repo = ref.read(pgListingRepositoryProvider);
      final rooms = await repo.fetchRooms(pg.id);

      double minP = double.infinity;
      double maxP = 0;
      int totalEmpty = 0;

      for (final room in rooms) {
        final beds = room['beds'] as List<dynamic>? ?? [];
        final sharingType = room['sharingType'] ?? beds.length;

        String type = 'other';
        if (sharingType == 1)
          type = 'single';
        else if (sharingType == 2)
          type = 'double';
        else if (sharingType == 3)
          type = 'triple';
        else if (sharingType == 4)
          type = 'four';

        int emptyBeds = 0;
        for (final bed in beds) {
          final status = (bed['status'] ?? 'available')
              .toString()
              .toLowerCase();
          final isOccupied = bed['tenantName'] != null || bed['userId'] != null;
          if (status == 'available' && !isOccupied) {
            emptyBeds++;
          }

          final price = (bed['price'] as num?)?.toDouble() ?? 0.0;
          if (price > 0) {
            if (price < minP) minP = price;
            if (price > maxP) maxP = price;
          }
        }

        if (minP == double.infinity || maxP == 0) {
          final roomPrice =
              (room['pricePerBed'] ?? room['pricePerMonth'] ?? 0.0 as num)
                  .toDouble();
          if (roomPrice > 0) {
            if (roomPrice < minP) minP = roomPrice;
            if (roomPrice > maxP) maxP = roomPrice;
          }
        }

        final key = type;
        _occupancyRoomCount[key] = (_occupancyRoomCount[key] ?? 0) + 1;
        _occupancyBedCount[key] = (_occupancyBedCount[key] ?? 0) + emptyBeds;

        if (emptyBeds > 0 && !isInitialization) {
          _occupancySelected[key] = true;
        }
        if (emptyBeds > 0) {
          totalEmpty += emptyBeds;
        }
      }

      setState(() {
        _pgRooms = rooms;
        _isLoadingRooms = false;
        if (minP != double.infinity) {
          _pgMinPrice = minP;
          _minPriceController.text = minP.toInt().toString();
        } else {
          _pgMinPrice = null;
        }
        if (maxP > 0) {
          _pgMaxPrice = maxP;
          _maxPriceController.text = maxP.toInt().toString();
        } else {
          _pgMaxPrice = null;
        }
        _pgTotalVacancy = totalEmpty;
        _vacancyController.text = totalEmpty.toString();

        if (!isInitialization && pg.pgType.toLowerCase() == 'unisex') {
          int maleBeds = totalEmpty ~/ 2;
          int femaleBeds = totalEmpty - maleBeds;
          _maleVacancyController.text = maleBeds.toString();
          _femaleVacancyController.text = femaleBeds.toString();
        }
      });
    } catch (e) {
      setState(() => _isLoadingRooms = false);
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _pickDate() async {
    final primaryColor = const Color(0xFF03045E);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            surface: Colors.white,
            onSurface: const Color(0xFF1A1A2E),
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _availableFrom = picked);
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  void _nextStep() {
    if (!_formKey.currentState!.validate()) return;

    if (_currentStep == 0) {
      if (_selectedPg == null) {
        _showSnack('Please select a property.');
        return;
      }
    } else if (_currentStep == 1) {
      final selectedTypes = _occupancySelected.entries
          .where((e) => e.value)
          .toList();
      if (selectedTypes.isEmpty) {
        _showSnack('Please select at least one occupancy type.');
        return;
      }
      if (_availableFrom == null) {
        _showSnack('Please select availability date.');
        return;
      }
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
      _submit();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('Please fill all required fields correctly.');
      return;
    }
    if (_selectedPg == null) {
      _showSnack('Please select a PG first.');
      return;
    }
    final selectedTypes = _occupancySelected.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    if (selectedTypes.isEmpty) {
      _showSnack('Please select at least one occupancy type.');
      return;
    }
    if (_availableFrom == null) {
      _showSnack('Please select an availability date.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(pgListingRepositoryProvider);
      List<String> finalImages = List.from(_existingImages);
      for (var file in _selectedImages) {
        final bytes = await file.readAsBytes();

        final uploadData = await repo.getUploadUrl(file.name, 'image/jpeg');
        final uploadUrl = uploadData['uploadUrl']!;

        await repo.uploadFileToS3(uploadUrl, bytes, 'image/jpeg');

        final publicUrl = uploadUrl.split('?').first;
        finalImages.add(publicUrl);
      }

      final payload = <String, dynamic>{
        'pgId': _selectedPg!.id,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'occupancyTypes': selectedTypes,
        'vacancyCount': _totalVacancy,
        'minPrice': double.tryParse(_minPriceController.text.trim()) ?? 0.0,
        'maxPrice': double.tryParse(_maxPriceController.text.trim()) ?? 0.0,
        'pgType': _selectedPg!.pgType,
        'availableFrom': _availableFrom!.toIso8601String(),
        'images': finalImages,
      };

      if (_isEditMode) {
        payload['isActive'] = _isActive;
      }

      if (_isUnisex) {
        payload['maleVacancyCount'] =
            int.tryParse(_maleVacancyController.text) ?? 0;
        payload['femaleVacancyCount'] =
            int.tryParse(_femaleVacancyController.text) ?? 0;
      }

      if (_isEditMode) {
        await repo.updatePost(widget.existingPost!.id, payload);
      } else {
        await repo.createPost(payload);
      }

      if (mounted) {
        ref.invalidate(pgListProvider);
        _showSnack(
          _isEditMode
              ? 'Vacancy post updated successfully!'
              : 'Vacancy post created successfully!',
          isSuccess: true,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 30,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      _showSnack('Error picking images: $e');
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    final color = isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444);
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
                isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
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

  // ─── UI ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final pgsAsync = ref.watch(ownerPgsProvider);
    final postsAsync = ref.watch(pgListProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: _isEditMode ? 'Edit Vacancy Post' : 'Create New Post',
        showBackButton: true,
        pinnedSCurve: true,
        isCompact: true,
        centerTitle: true,
      ),
      bottomNavigationBar: pgsAsync.when(
        data: (_) => _buildModernBottomNav(),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      body: pgsAsync.when(
        data: (pgs) {
          final existingPgIds =
              postsAsync.valueOrNull?.map((p) => p.pg.id).toSet() ?? {};
          if (_isEditMode && widget.existingPost != null) {
            existingPgIds.remove(widget.existingPost!.pg.id);
          }
          final filteredPgs = pgs
              .where((pg) => !existingPgIds.contains(pg.id))
              .toList();

          return FadeTransition(
            opacity: _fadeAnimation,
            child: _buildForm(filteredPgs, isSmallScreen),
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentColor,
                      AppTheme.accentColor.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading PGs...',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: AppTheme.error.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load PGs',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your connection',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(List<PgModel> pgs, bool isSmallScreen) {
    if (_isEditMode && _selectedPg == null && pgs.isNotEmpty) {
      try {
        _selectedPg = pgs.firstWhere((p) => p.id == widget.existingPost!.pg.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _onPgSelected(_selectedPg!, isInitialization: true);
        });
      } catch (_) {}
    }

    return SlideTransition(
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
                      _buildStep1Property(pgs, isSmallScreen),
                      _buildStep2Details(isSmallScreen),
                      _buildStep3Publish(isSmallScreen),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Property(List<PgModel> pgs, bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 16 : 24,
        8,
        isSmallScreen ? 16 : 24,
        12,
      ),
      child: Column(
        children: [
          _buildElegantCard(
            title: 'Select Property',
            icon: Icons.apartment_rounded,
            required: true,
            isSmallScreen: isSmallScreen,
            child: _buildDropdown(pgs, isSmallScreen),
          ),
          const SizedBox(height: 16),
          _buildElegantCard(
            title: 'Post Title',
            icon: Icons.title_rounded,
            required: true,
            isSmallScreen: isSmallScreen,
            child: _buildElegantTextField(
              controller: _titleController,
              hint: 'e.g., Premium AC Room with Meals',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
          ),
          const SizedBox(height: 16),
          _buildElegantCard(
            title: 'Description',
            icon: Icons.description_rounded,
            required: true,
            isSmallScreen: isSmallScreen,
            child: _buildElegantTextField(
              controller: _descController,
              hint: 'Describe the vacancy details, amenities, and benefits...',
              maxLines: 4,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Description is required'
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          _buildElegantCard(
            title: _isUnisex ? 'Gender-wise Vacancies' : 'Vacancy Count',
            icon: _isUnisex
                ? Icons.people_alt_rounded
                : Icons.person_add_rounded,
            required: true,
            isSmallScreen: isSmallScreen,
            child: Column(
              children: [
                if (_isUnisex) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildGenderVacancyField(
                          title: 'Male',
                          icon: Icons.male,
                          controller: _maleVacancyController,
                          color: const Color(0xFF4A90E2),
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGenderVacancyField(
                          title: 'Female',
                          icon: Icons.female,
                          controller: _femaleVacancyController,
                          color: const Color(0xFFE24A90),
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTotalVacancyChip(isSmallScreen),
                ] else ...[
                  _buildElegantTextField(
                    controller: _vacancyController,
                    hint: 'Number of vacancies',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final val = int.tryParse(v);
                      if (val == null) return 'Invalid';
                      if (_pgTotalVacancy != null && val > _pgTotalVacancy!) {
                        return 'Cannot exceed actual available beds ($_pgTotalVacancy)';
                      }
                      return null;
                    },
                  ),
                  if (_pgTotalVacancy != null) ...[
                    const SizedBox(height: 8),
                    _buildVacancyHint(isSmallScreen),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStep2Details(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 16 : 24,
        8,
        isSmallScreen ? 16 : 24,
        12,
      ),
      child: Column(
        children: [
          _buildElegantCard(
            title: 'Price Range',
            icon: Icons.currency_rupee_rounded,
            required: true,
            isSmallScreen: isSmallScreen,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildElegantPriceField(
                        controller: _minPriceController,
                        hint: 'Min Price',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildElegantPriceField(
                        controller: _maxPriceController,
                        hint: 'Max Price',
                      ),
                    ),
                  ],
                ),
                if (_pgMinPrice != null || _pgMaxPrice != null) ...[
                  const SizedBox(height: 8),
                  _buildPriceHint(isSmallScreen),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildElegantCard(
            title: 'PG Type',
            icon: Icons.category_rounded,
            isSmallScreen: isSmallScreen,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentColor.withOpacity(0.1),
                    AppTheme.accentColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.home_work_rounded,
                    size: 20,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedPg != null
                          ? _capitalize(_selectedPg!.pgType)
                          : 'Not selected',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _selectedPg != null
                            ? AppTheme.textPrimary
                            : AppTheme.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildElegantCard(
            title: 'Available From',
            icon: Icons.calendar_today_rounded,
            required: true,
            isSmallScreen: isSmallScreen,
            child: _buildElegantDatePicker(),
          ),
          const SizedBox(height: 16),
          _buildElegantCard(
            title: 'Room Types',
            icon: Icons.meeting_room_rounded,
            required: true,
            isSmallScreen: isSmallScreen,
            child: _isLoadingRooms
                ? _buildLoadingOccupancy()
                : _buildOccupancyGrid(isSmallScreen),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStep3Publish(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 16 : 24,
        8,
        isSmallScreen ? 16 : 24,
        12,
      ),
      child: Column(
        children: [
          _buildElegantCard(
            title: 'Media',
            icon: Icons.image_rounded,
            subtitle: 'Add up to 5 showcase images',
            isSmallScreen: isSmallScreen,
            child: _buildImageGrid(isSmallScreen),
          ),
          const SizedBox(height: 16),
          if (_isEditMode) ...[
            _buildElegantCard(
              title: 'Post Status',
              icon: Icons.toggle_on_rounded,
              isSmallScreen: isSmallScreen,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isActive
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: _isActive
                              ? AppTheme.success
                              : AppTheme.textHint,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isActive
                              ? 'Active (Visible to tenants)'
                              : 'Inactive (Hidden)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _isActive
                                ? AppTheme.success
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (val) => setState(() => _isActive = val),
                      activeColor: Colors.white,
                      activeTrackColor: AppTheme.success,
                      inactiveThumbColor: AppTheme.textSecondary,
                      inactiveTrackColor: AppTheme.surfaceBorder,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  // ─── ELEGANT COMPONENTS ────────────────────────────────────────────────

  Widget _buildModernStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return Expanded(child: _buildModernStep(index));
        }),
      ),
    );
  }

  Widget _buildModernStep(int index) {
    final isActive = _currentStep == index;
    final isCompleted =
        _currentStep > index || (_isEditMode && index <= _maxStepReached);
    final labels = ['Property', 'Details', 'Publish'];
    final icons = [
      Icons.apartment_rounded,
      Icons.list_alt_rounded,
      Icons.check_circle_outline,
    ];

    return GestureDetector(
      onTap: () {
        if (index < _currentStep ||
            (index <= _maxStepReached &&
                _formKey.currentState?.validate() == true)) {
          setState(() {
            _currentStep = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 500),
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
              if (index < 2) ...[const SizedBox(width: 0)],
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

  Widget _buildElegantCard({
    required String title,
    required IconData icon,
    String? subtitle,
    bool required = false,
    required bool isSmallScreen,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFF8F9FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildSectionHeader(icon, title, subtitle ?? '')),
              if (required)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Required',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.error,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 14 : 18),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.accentColor.withOpacity(0.1),
                AppTheme.accentColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.accentColor, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.textHint,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildElegantTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onChanged: onChanged,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.textHint,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: maxLines > 1 ? 12 : 14,
          ),
        ),
      ),
    );
  }

  Widget _buildElegantPriceField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          prefixText: '₹ ',
          prefixStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.accentColor,
          ),
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.textHint,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildElegantDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _availableFrom != null
                  ? AppTheme.accentColor.withOpacity(0.05)
                  : Colors.transparent,
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _availableFrom != null
                ? AppTheme.accentColor.withOpacity(0.3)
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: _availableFrom != null
                  ? AppTheme.accentColor
                  : AppTheme.textHint,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _availableFrom != null
                    ? _formatDate(_availableFrom!)
                    : 'Select availability date',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: _availableFrom != null
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: _availableFrom != null
                      ? AppTheme.accentColor
                      : AppTheme.textHint,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppTheme.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderVacancyField({
    required String title,
    required IconData icon,
    required TextEditingController controller,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$title Vacancy Count ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '*',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final val = int.tryParse(v);
              if (val == null) return 'Invalid';
              if (_pgTotalVacancy != null && _totalVacancy > _pgTotalVacancy!) {
                return 'Total sum of male and female cannot exceed actual available beds ($_pgTotalVacancy)';
              }
              return null;
            },
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (_pgTotalVacancy != null) ...[
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              text: 'PG vacant beds: ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isSmallScreen ? 10 : 11,
                color: AppTheme.textHint,
              ),
              children: [
                TextSpan(
                  text: '$_pgTotalVacancy',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warning,
                  ),
                ),
                TextSpan(text: ' (Override if needed)'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTotalVacancyChip(bool isSmallScreen) {
    final int maleCount = int.tryParse(_maleVacancyController.text) ?? 0;
    final int femaleCount = int.tryParse(_femaleVacancyController.text) ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Total vacancies: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isSmallScreen ? 13 : 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            '$_totalVacancy',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isSmallScreen ? 15 : 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.accentColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '( ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isSmallScreen ? 12 : 13,
              color: AppTheme.textHint,
            ),
          ),
          Icon(Icons.male, size: 14, color: AppTheme.textHint),
          Text(
            ' $maleCount male + ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isSmallScreen ? 12 : 13,
              color: AppTheme.textHint,
            ),
          ),
          Icon(Icons.female, size: 14, color: AppTheme.textHint),
          Text(
            ' $femaleCount female )',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isSmallScreen ? 12 : 13,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVacancyHint(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'PG has $_pgTotalVacancy vacant bed(s) • You can override this value',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isSmallScreen ? 10 : 11,
                color: AppTheme.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceHint(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.trending_up_rounded,
            size: 14,
            color: AppTheme.accentColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'PG price range: ${_pgMinPrice != null ? '₹${_pgMinPrice!.toInt()}' : 'N/A'} - ${_pgMaxPrice != null ? '₹${_pgMaxPrice!.toInt()}' : 'N/A'}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isSmallScreen ? 10 : 11,
                color: AppTheme.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOccupancy() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Center(
          child: CircularProgressIndicator(
            color: AppTheme.accentColor,
            strokeWidth: 2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Loading room information...',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppTheme.textHint,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOccupancyGrid(bool isSmallScreen) {
    final types = ['single', 'double', 'triple', 'four', 'other'];
    final typeNames = {
      'single': 'Single',
      'double': 'Double',
      'triple': 'Triple',
      'four': 'Four Sharing',
      'other': 'Other',
    };
    final typeIcons = {
      'single': Icons.person_outline_rounded,
      'double': Icons.people_outline_rounded,
      'triple': Icons.groups_rounded,
      'four': Icons.group_rounded,
      'other': Icons.meeting_room_rounded,
    };

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: types.map((type) {
        final isSelected = _occupancySelected[type] ?? false;
        final rooms = _occupancyRoomCount[type] ?? 0;
        final beds = _occupancyBedCount[type] ?? 0;
        final hasAvailability = beds > 0;

        return GestureDetector(
          onTap: () => setState(() => _occupancySelected[type] = !isSelected),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width:
                (MediaQuery.of(context).size.width -
                    (isSmallScreen ? 60 : 76)) /
                2.2,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.accentColor.withOpacity(0.12),
                        AppTheme.accentColor.withOpacity(0.05),
                      ],
                    )
                  : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppTheme.accentColor
                    : (hasAvailability
                          ? AppTheme.success.withOpacity(0.3)
                          : const Color(0xFFE5E7EB)),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentColor.withOpacity(0.15)
                            : const Color(0xFFF1F4F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        typeIcons[type],
                        size: 16,
                        color: isSelected
                            ? AppTheme.accentColor
                            : (hasAvailability
                                  ? AppTheme.success
                                  : AppTheme.textHint),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        typeNames[type]!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.accentColor
                              : AppTheme.textSecondary,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: const Color(0xFFE5E7EB).withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatChip(
                        Icons.meeting_room_rounded,
                        '$rooms Room${rooms != 1 ? 's' : ''}',
                        isSmallScreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildStatChip(
                        Icons.bed_rounded,
                        '$beds bed${beds != 1 ? 's' : ''}',
                        isSmallScreen,
                        highlight: beds > 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String label,
    bool isSmallScreen, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.success.withOpacity(0.1)
            : const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 12,
            color: highlight ? AppTheme.success : AppTheme.textHint,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isSmallScreen ? 9 : 10,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
                color: highlight ? AppTheme.success : AppTheme.textHint,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(bool isSmallScreen) {
    int totalImages = _existingImages.length + _selectedImages.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._existingImages.asMap().entries.map(
              (e) => _buildImageItem(e.value, true, isSmallScreen, e.key),
            ),
            ..._selectedImages.asMap().entries.map(
              (e) => _buildImageItem(
                e.value,
                false,
                isSmallScreen,
                _existingImages.length + e.key,
              ),
            ),
            if (totalImages < 5) _buildAddImageButton(isSmallScreen),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppTheme.textHint,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Upload up to 5 images (JPEG, PNG, WEBP) • Max 5MB each',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: AppTheme.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageItem(
    dynamic img,
    bool isExisting,
    bool isSmallScreen,
    int globalIndex,
  ) {
    return Container(
      width: isSmallScreen ? 100 : 110,
      height: isSmallScreen ? 100 : 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: GestureDetector(
              onTap: () => _showFullScreenGallery(globalIndex),
              child: Hero(
                tag: 'hero_image_$img',
                child: isExisting
                    ? PgImageWidget(
                        imageUrl: img as String,
                        fit: BoxFit.cover,
                        fallbackWidget: Container(
                          color: const Color(0xFFF1F4F9),
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Image.file(File((img as XFile).path), fit: BoxFit.cover),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () async {
                if (isExisting) {
                  try {
                    final repo = ref.read(pgListingRepositoryProvider);
                    await repo.deleteFile(img as String);
                  } catch (e) {
                    _showSnack('Failed to delete image: $e');
                    return;
                  }
                }
                setState(() {
                  if (isExisting) {
                    _existingImages.remove(img);
                  } else {
                    _selectedImages.remove(img);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton(bool isSmallScreen) {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: isSmallScreen ? 100 : 110,
        height: isSmallScreen ? 100 : 110,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FF),
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
                    AppTheme.accentColor,
                    AppTheme.accentColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add_rounded,
                size: isSmallScreen ? 18 : 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add Photo',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isSmallScreen ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
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
                        final img = isExisting
                            ? _existingImages[index]
                            : _selectedImages[index - _existingImages.length];

                        return InteractiveViewer(
                          panEnabled: true,
                          minScale: 0.5,
                          maxScale: 4,
                          child: Center(
                            child: Hero(
                              tag: 'hero_image_$img',
                              child: isExisting
                                  ? PgImageWidget(
                                      imageUrl: img as String,
                                      fit: BoxFit.contain,
                                      fallbackWidget: Container(
                                        color: const Color(0xFFF1F4F9),
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : Image.file(
                                      File((img as XFile).path),
                                      fit: BoxFit.contain,
                                    ),
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

  Widget _buildDropdown(List<PgModel> pgs, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedPg != null
              ? AppTheme.accentColor.withOpacity(0.5)
              : const Color(0xFFE5E7EB),
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PgModel>(
          isExpanded: true,
          dropdownColor: Colors.white,
          value: _selectedPg,
          hint: Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: AppTheme.textHint),
              const SizedBox(width: 8),
              Text(
                'Search or select PG...',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textHint,
                  fontSize: isSmallScreen ? 13 : 14,
                ),
              ),
            ],
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.textSecondary,
          ),
          items: pgs.map((pg) {
            return DropdownMenuItem<PgModel>(
              value: pg,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pg.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (pg.address != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatAddress(pg.address!),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isSmallScreen ? 10 : 11,
                          color: AppTheme.textHint,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (pg) {
            if (pg != null) _onPgSelected(pg);
          },
        ),
      ),
    );
  }

  String _formatAddress(PgAddress address) {
    final parts = <String>[];
    if (address.landmark.isNotEmpty) parts.add(address.landmark);
    if (address.city.isNotEmpty && address.city != 'Unknown City')
      parts.add(address.city);
    if (address.state.isNotEmpty) parts.add(address.state);
    if (parts.isEmpty) return 'Address not available';
    return parts.join(', ');
  }

  Widget _buildModernBottomNav() {
    final primaryColor = AppTheme.primary;
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
      child: SafeArea(
        top: false,
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
                          (_isEditMode &&
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
                                  : (_isEditMode ? 'Update' : 'Create'),
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
      ),
    );
  }
}

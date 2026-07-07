import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:pgstay/features/pg_listing/widgets/pg_image_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';

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

  // Occupancy data computed from rooms
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
    _animationController.forward();

    if (_isEditMode) {
      _initEditMode();
    }
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

  // ─── Fetch rooms and auto-populate fields ────────────────────────────────
  Future<void> _onPgSelected(
    PgModel pg, {
    bool isInitialization = false,
  }) async {
    setState(() {
      _selectedPg = pg;
      _isLoadingRooms = true;
      // Reset
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

        // fallback if price isn't in beds
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
      });
    } catch (e) {
      setState(() => _isLoadingRooms = false);
    }
  }

  String _normalizeType(String type) {
    if (type.contains('single')) return 'single';
    if (type.contains('double')) return 'double';
    if (type.contains('triple')) return 'triple';
    if (type.contains('four') || type.contains('quad')) return 'four';
    return 'other';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // ─── Date picker helper ──────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accentColor,
            surface: AppTheme.surfaceWhite,
          ),
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

  // ─── Submit ──────────────────────────────────────────────────────────────
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Vacancy post updated successfully!'
                  : 'Vacancy post created successfully!',
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
          ),
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

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
      ),
    );
  }

  // ─── UI ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final pgsAsync = ref.watch(ownerPgsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: _isEditMode ? 'Edit Vacancy Post' : 'Create New Post',
        showBackButton: true,
      ),
      body: pgsAsync.when(
        data: (pgs) => FadeTransition(
          opacity: _fadeAnimation,
          child: _buildForm(pgs, isSmallScreen),
        ),
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
                style: GoogleFonts.inter(
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
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppTheme.error.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load PGs',
                style: GoogleFonts.inter(
                  color: AppTheme.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your connection',
                style: GoogleFonts.inter(
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

    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          isSmallScreen ? 16 : 24,
          8,
          isSmallScreen ? 16 : 24,
          120,
        ),
        children: [
          // Hero Header
          if (!_isEditMode) ...[
            _buildHeroHeader(isSmallScreen),
            const SizedBox(height: 24),
          ],

          // Progress Steps
          _buildProgressSteps(isSmallScreen),
          const SizedBox(height: 32),

          // ── Select PG ──────────────────────────────
          _buildSectionCard(
            title: 'Select Property',
            icon: Icons.apartment_rounded,
            required: true,
            isSmallScreen: isSmallScreen,
            child: _buildDropdown(pgs, isSmallScreen),
          ),
          const SizedBox(height: 20),

          // ── Post Title ─────────────────────────────
          _buildSectionCard(
            title: 'Post Title',
            icon: Icons.title_rounded,
            required: true,
            isSmallScreen: isSmallScreen,
            child: _buildTextField(
              controller: _titleController,
              hint: 'e.g., Premium AC Room with Meals',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
              isSmallScreen: isSmallScreen,
            ),
          ),
          const SizedBox(height: 20),

          // ── Description ────────────────────────────
          _buildSectionCard(
            title: 'Description',
            icon: Icons.description_rounded,
            required: true,
            isSmallScreen: isSmallScreen,
            child: _buildTextField(
              controller: _descController,
              hint: 'Describe the vacancy details, amenities, and benefits...',
              maxLines: 4,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Description is required'
                  : null,
              isSmallScreen: isSmallScreen,
            ),
          ),
          const SizedBox(height: 20),

          // ── Vacancy Count ──────────────────────────
          _buildSectionCard(
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
                  _buildTextField(
                    controller: _vacancyController,
                    hint: 'Number of vacancies',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                    isSmallScreen: isSmallScreen,
                  ),
                  if (_pgTotalVacancy != null) ...[
                    const SizedBox(height: 8),
                    _buildVacancyHint(isSmallScreen),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Price ──────────────────────────────────
          _buildSectionCard(
            title: 'Price Range',
            icon: Icons.currency_rupee_rounded,
            required: true,
            isSmallScreen: isSmallScreen,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildPriceField(
                        controller: _minPriceController,
                        hint: 'Min Price',
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPriceField(
                        controller: _maxPriceController,
                        hint: 'Max Price',
                        isSmallScreen: isSmallScreen,
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
          const SizedBox(height: 20),

          // ── PG Type & Available From ───────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSectionCard(
                  title: 'PG Type',
                  icon: Icons.category_rounded,
                  isSmallScreen: isSmallScreen,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
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
                            style: GoogleFonts.inter(
                              fontSize: isSmallScreen ? 13 : 14,
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSectionCard(
                  title: 'Available From',
                  icon: Icons.calendar_today_rounded,
                  required: true,
                  isSmallScreen: isSmallScreen,
                  child: _buildDatePicker(isSmallScreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Occupancy Types ────────────────────────
          _buildSectionCard(
            title: 'Room Types',
            icon: Icons.meeting_room_rounded,
            required: true,
            isSmallScreen: isSmallScreen,
            child: _isLoadingRooms
                ? _buildLoadingOccupancy()
                : _buildOccupancyGrid(isSmallScreen),
          ),
          const SizedBox(height: 20),

          // ── Media ──────────────────────────────────
          _buildSectionCard(
            title: 'Media',
            icon: Icons.image_rounded,
            subtitle: 'Add up to 5 showcase images',
            isSmallScreen: isSmallScreen,
            child: _buildImageGrid(isSmallScreen),
          ),
          const SizedBox(height: 20),

          // ── Post Status ────────────────────────────
          if (_isEditMode) ...[
            _buildSectionCard(
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
                          color: _isActive ? AppTheme.success : AppTheme.textHint,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isActive
                              ? 'Active (Visible to tenants)'
                              : 'Inactive (Hidden)',
                          style: GoogleFonts.inter(
                            fontSize: isSmallScreen ? 13 : 14,
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

          // ── Actions ───────────────────────────────
          _buildActionButtons(isSmallScreen),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withOpacity(0.15),
            AppTheme.accentColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentColor,
                  AppTheme.accentColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.post_add_rounded,
              color: Colors.white,
              size: isSmallScreen ? 24 : 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share Your Vacancy',
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fill in the details below to attract potential tenants',
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSteps(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildProgressStep(1, 'Basic', 0, isSmallScreen),
          Expanded(child: _buildProgressLine(0.25, isSmallScreen)),
          _buildProgressStep(2, 'Details', 1, isSmallScreen),
          Expanded(child: _buildProgressLine(0.5, isSmallScreen)),
          _buildProgressStep(3, 'Media', 2, isSmallScreen),
          Expanded(child: _buildProgressLine(0.75, isSmallScreen)),
          _buildProgressStep(4, 'Finish', 3, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildProgressStep(
    int step,
    String label,
    int currentStep,
    bool isSmallScreen,
  ) {
    final isActive = step <= (_isEditMode ? 4 : currentStep + 1);
    return Column(
      children: [
        Container(
          width: isSmallScreen ? 28 : 32,
          height: isSmallScreen ? 28 : 32,
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      AppTheme.accentColor,
                      AppTheme.accentColor.withOpacity(0.7),
                    ],
                  )
                : null,
            color: isActive ? null : AppTheme.surfaceBorder,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 9 : 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppTheme.accentColor : AppTheme.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(double progress, bool isSmallScreen) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentColor, AppTheme.accentColor.withOpacity(0.3)],
          stops: [progress, progress],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    String? subtitle,
    bool required = false,
    required bool isSmallScreen,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.surfaceBorder.withOpacity(0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: AppTheme.accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: title,
                          style: GoogleFonts.inter(
                            fontSize: isSmallScreen ? 14 : 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          children: required
                              ? [
                                  TextSpan(
                                    text: ' *',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ]
                              : [],
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: isSmallScreen ? 10 : 11,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: child,
          ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        style: GoogleFonts.inter(
          fontSize: isSmallScreen ? 13 : 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: color, size: 20),
          hintText: title,
          hintStyle: GoogleFonts.inter(
            fontSize: isSmallScreen ? 13 : 14,
            color: AppTheme.textHint,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: isSmallScreen ? 12 : 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalVacancyChip(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withOpacity(0.1),
            AppTheme.accentColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_alt_rounded, size: 18, color: AppTheme.accentColor),
          const SizedBox(width: 8),
          Text(
            'Total Vacancies: $_totalVacancy',
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentColor,
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
          Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'PG has $_pgTotalVacancy vacant bed(s) • You can override this value',
              style: GoogleFonts.inter(
                fontSize: isSmallScreen ? 10 : 11,
                color: AppTheme.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String hint,
    required bool isSmallScreen,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      style: GoogleFonts.inter(
        fontSize: isSmallScreen ? 13 : 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixText: '₹ ',
        prefixStyle: GoogleFonts.inter(
          fontSize: isSmallScreen ? 13 : 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.accentColor,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: isSmallScreen ? 13 : 14,
          color: AppTheme.textHint,
        ),
        filled: true,
        fillColor: AppTheme.surfaceWhite,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isSmallScreen ? 12 : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accentColor, width: 1.5),
        ),
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
            size: 16,
            color: AppTheme.accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'PG price range: ${_pgMinPrice != null ? '₹${_pgMinPrice!.toInt()}' : 'N/A'} - ${_pgMaxPrice != null ? '₹${_pgMaxPrice!.toInt()}' : 'N/A'}',
              style: GoogleFonts.inter(
                fontSize: isSmallScreen ? 10 : 11,
                color: AppTheme.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(bool isSmallScreen) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                : AppTheme.surfaceBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: _availableFrom != null
                  ? AppTheme.accentColor
                  : AppTheme.textHint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _availableFrom != null
                    ? _formatDate(_availableFrom!)
                    : 'Select availability date',
                style: GoogleFonts.inter(
                  fontSize: isSmallScreen ? 13 : 14,
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
              size: 20,
              color: AppTheme.textHint,
            ),
          ],
        ),
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
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textHint),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ─── Occupancy Type Grid ────────────────────────────────────────────
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
      spacing: 12,
      runSpacing: 12,
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
                    (isSmallScreen ? 68 : 84)) /
                2.2,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.accentColor.withOpacity(0.15),
                        AppTheme.accentColor.withOpacity(0.05),
                      ],
                    )
                  : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppTheme.accentColor
                    : (hasAvailability
                          ? AppTheme.success.withOpacity(0.3)
                          : AppTheme.surfaceBorder),
                width: isSelected ? 2 : 1,
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
                            ? AppTheme.accentColor.withOpacity(0.2)
                            : AppTheme.surfaceBorder.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        typeIcons[type],
                        size: 18,
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
                        style: GoogleFonts.inter(
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
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: AppTheme.surfaceBorder.withOpacity(0.5),
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
                    const SizedBox(width: 8),
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
            : AppTheme.surfaceBorder.withOpacity(0.3),
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
              style: GoogleFonts.inter(
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
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._existingImages.map((img) => _buildImageItem(img, true, isSmallScreen)),
            ..._selectedImages.map((file) => _buildImageItem(file, false, isSmallScreen)),
            if (totalImages < 5) _buildAddImageButton(isSmallScreen),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceBorder.withOpacity(0.3),
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
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 9 : 10,
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

  Widget _buildImageItem(dynamic img, bool isExisting, bool isSmallScreen) {
    return Container(
      width: isSmallScreen ? 100 : 110,
      height: isSmallScreen ? 100 : 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: isExisting
                ? PgImageWidget(
                    imageUrl: img as String,
                    fit: BoxFit.cover,
                    fallbackWidget: Container(
                      color: AppTheme.surfaceBorder,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  )
                : Image.file(
                    File((img as XFile).path),
                    fit: BoxFit.cover,
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
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.surfaceBorder,
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_rounded,
              size: isSmallScreen ? 28 : 32,
              color: AppTheme.accentColor,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload',
              style: GoogleFonts.inter(
                fontSize: isSmallScreen ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentColor,
              ),
            ),
            Text(
              'Image',
              style: GoogleFonts.inter(
                fontSize: isSmallScreen ? 10 : 11,
                color: AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 20,
              vertical: isSmallScreen ? 10 : 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.surfaceBorder),
            ),
          ),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              fontSize: isSmallScreen ? 13 : 14,
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              disabledBackgroundColor: AppTheme.accentColor.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 20 : 28,
              ),
              elevation: 0,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isEditMode ? 'Update Post' : 'Create Post',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ─── PG Dropdown ─────────────────────────────────────────────────────────
  Widget _buildDropdown(List<PgModel> pgs, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedPg != null
              ? AppTheme.accentColor.withOpacity(0.5)
              : AppTheme.surfaceBorder,
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
                style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (pg.address != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatAddress(pg.address!),
                        style: GoogleFonts.inter(
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    String? helperText,
    required bool isSmallScreen,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: GoogleFonts.inter(
        fontSize: isSmallScreen ? 13 : 14,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: AppTheme.textHint,
          fontSize: isSmallScreen ? 13 : 14,
        ),
        helperText: helperText,
        helperStyle: GoogleFonts.inter(
          color: AppTheme.textHint,
          fontSize: isSmallScreen ? 9 : 10,
        ),
        filled: true,
        fillColor: AppTheme.surfaceWhite,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: maxLines > 1 ? 14 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
        ),
        errorStyle: GoogleFonts.inter(
          color: AppTheme.error,
          fontSize: isSmallScreen ? 9 : 10,
        ),
      ),
    );
  }
}

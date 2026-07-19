import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/profile/providers/profile_provider.dart';
import 'package:pgstay/features/profile/models/profile_model.dart';
import 'package:pgstay/core/utils/change_tracker.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _localVehicleType;
  final TextEditingController _vehicleNumberController =
      TextEditingController();
  bool _isInit = false;

  bool _isEditing = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _mobNo1Ctrl;
  late TextEditingController _mobNo2Ctrl;
  late TextEditingController _genderCtrl;
  late TextEditingController _locationDescCtrl;
  late TextEditingController _landmarkCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _pincodeCtrl;
  late TextEditingController _vehicleTypeCtrl;
  late TextEditingController _aadharNumberCtrl;
  late ChangeTracker _tracker;

  bool get _hasChanges => _isEditing && _tracker.hasChanges;

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    if (_isEditing) {
      _disposeEditControllers();
    }
    super.dispose();
  }

  void _startEditing(UserProfile profile) {
    _nameCtrl = TextEditingController(text: profile.name);
    _mobNo1Ctrl = TextEditingController(text: profile.mobNo1);
    _mobNo2Ctrl = TextEditingController(text: profile.mobNo2 ?? '');
    _genderCtrl = TextEditingController(text: profile.gender ?? '');
    _locationDescCtrl = TextEditingController(
      text: profile.locationDescription ?? '',
    );
    _landmarkCtrl = TextEditingController(text: profile.landmark ?? '');
    _cityCtrl = TextEditingController(text: profile.city ?? '');
    _stateCtrl = TextEditingController(text: profile.state ?? '');
    _countryCtrl = TextEditingController(text: profile.country ?? '');
    _pincodeCtrl = TextEditingController(text: profile.pincode ?? '');
    _vehicleTypeCtrl = TextEditingController(text: profile.vehicleType ?? '');
    _vehicleNumberController.text = profile.vehicleNumber ?? '';
    _aadharNumberCtrl = TextEditingController(text: profile.aadharNumber ?? '');

    _tracker = ChangeTracker(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );

    _tracker.setOriginal('name', profile.name);
    _tracker.setOriginal('mobNo1', profile.mobNo1);
    _tracker.setOriginal('mobNo2', profile.mobNo2 ?? '');
    _tracker.setOriginal('gender', profile.gender ?? '');
    _tracker.setOriginal('locationDesc', profile.locationDescription ?? '');
    _tracker.setOriginal('landmark', profile.landmark ?? '');
    _tracker.setOriginal('city', profile.city ?? '');
    _tracker.setOriginal('state', profile.state ?? '');
    _tracker.setOriginal('country', profile.country ?? '');
    _tracker.setOriginal('pincode', profile.pincode ?? '');
    _tracker.setOriginal('vehicleType', profile.vehicleType ?? '');
    _tracker.setOriginal('vehicleNumber', profile.vehicleNumber ?? '');
    _tracker.setOriginal('aadharNumber', profile.aadharNumber ?? '');

    _nameCtrl.addListener(
      () => _tracker.updateValue('name', _nameCtrl.text.trim()),
    );
    _mobNo1Ctrl.addListener(
      () => _tracker.updateValue('mobNo1', _mobNo1Ctrl.text.trim()),
    );
    _mobNo2Ctrl.addListener(
      () => _tracker.updateValue('mobNo2', _mobNo2Ctrl.text.trim()),
    );
    _genderCtrl.addListener(
      () => _tracker.updateValue('gender', _genderCtrl.text.trim()),
    );
    _locationDescCtrl.addListener(
      () => _tracker.updateValue('locationDesc', _locationDescCtrl.text.trim()),
    );
    _landmarkCtrl.addListener(
      () => _tracker.updateValue('landmark', _landmarkCtrl.text.trim()),
    );
    _cityCtrl.addListener(
      () => _tracker.updateValue('city', _cityCtrl.text.trim()),
    );
    _stateCtrl.addListener(
      () => _tracker.updateValue('state', _stateCtrl.text.trim()),
    );
    _countryCtrl.addListener(
      () => _tracker.updateValue('country', _countryCtrl.text.trim()),
    );
    _pincodeCtrl.addListener(
      () => _tracker.updateValue('pincode', _pincodeCtrl.text.trim()),
    );
    _vehicleTypeCtrl.addListener(
      () => _tracker.updateValue('vehicleType', _vehicleTypeCtrl.text.trim()),
    );
    _vehicleNumberController.addListener(
      () => _tracker.updateValue(
        'vehicleNumber',
        _vehicleNumberController.text.trim(),
      ),
    );
    _aadharNumberCtrl.addListener(
      () => _tracker.updateValue('aadharNumber', _aadharNumberCtrl.text.trim()),
    );

    setState(() {
      _isEditing = true;
    });
  }

  void _disposeEditControllers() {
    _nameCtrl.dispose();
    _mobNo1Ctrl.dispose();
    _mobNo2Ctrl.dispose();
    _genderCtrl.dispose();
    _locationDescCtrl.dispose();
    _landmarkCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    _pincodeCtrl.dispose();
    _vehicleTypeCtrl.dispose();
    _aadharNumberCtrl.dispose();
  }

  void _cancelEditing() {
    _disposeEditControllers();
    setState(() {
      _isEditing = false;
      _isLoading = false;
    });
  }

  Future<void> _pickAndUploadAadhar() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() => _isLoading = true);

        final repo = ref.read(profileRepositoryProvider);
        await repo.uploadAadharDocument(image.path, image.name);

        ref.invalidate(userProfileProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aadhar document uploaded successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading document: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() => _isLoading = true);

        final repo = ref.read(profileRepositoryProvider);
        await repo.uploadProfilePicture(image.path, image.name);

        ref.invalidate(userProfileProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile image: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeProfileImage() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.removeProfilePicture();

      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image removed successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing profile image: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(profileRepositoryProvider);
      final currentProfile = ref.read(userProfileProvider).valueOrNull;
      await repo.updateProfile({
        'name': _nameCtrl.text.trim(),
        'email': currentProfile?.email ?? '',
        'mobNo1': _mobNo1Ctrl.text.trim(),
        'mobNo2': _mobNo2Ctrl.text.trim(),
        'gender': _genderCtrl.text.trim(),
        'vehicleType': _vehicleTypeCtrl.text.trim(),
        'vehicleNumber': _vehicleNumberController.text.trim().isEmpty
            ? null
            : _vehicleNumberController.text.trim(),
        'aadharNumber': _aadharNumberCtrl.text.trim(),
        'aadharFileKey': currentProfile?.aadharFileKey,
        'address': {
          'locationDescription': _locationDescCtrl.text.trim(),
          'landmark': _landmarkCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'state': _stateCtrl.text.trim(),
          'country': _countryCtrl.text.trim(),
          'pincode': _pincodeCtrl.text.trim(),
        },
      });
      _tracker.commitChanges();
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        _cancelEditing();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted && _isEditing) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: _isEditing ? 'Edit Profile' : 'My Profile',
        showBackButton: false,
        pinnedSCurve: true,
        isCompact: true,
        actionWidget: _isEditing
            ? Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: _cancelEditing,
                ),
              )
            : const SizedBox.shrink(),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (!_isInit) {
            _vehicleNumberController.text = profile.vehicleNumber ?? '';
            _isInit = true;
          }
          final currentVehicleType =
              _localVehicleType ??
              (profile.vehicleType == null || profile.vehicleType!.isEmpty
                  ? 'none'
                  : profile.vehicleType);

          return MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(userProfileProvider),
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  24,
                  80 + MediaQuery.of(context).padding.top + 32,
                  24,
                  100,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── User Profile Card ───────────────────────────
                      StaggeredFadeIn(
                        delay: const Duration(milliseconds: 100),
                        child: Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.surfaceBorder),
                            boxShadow: AppTheme.surfaceShadow,
                          ),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 86,
                                    height: 86,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.06,
                                      ),
                                      border: Border.all(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        width: 2,
                                      ),
                                      image:
                                          profile.picture != null &&
                                              profile.picture!.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                profile.picture!,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child:
                                        profile.picture == null ||
                                            profile.picture!.isEmpty
                                        ? const Icon(
                                            Icons.person_rounded,
                                            size: 44,
                                            color: AppTheme.primary,
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: PopupMenuButton<String>(
                                      offset: const Offset(0, 40),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      onSelected: (value) {
                                        if (value == 'change') {
                                          _pickAndUploadProfileImage();
                                        } else if (value == 'remove') {
                                          _removeProfileImage();
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'change',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.photo_library_outlined,
                                                size: 20,
                                              ),
                                              SizedBox(width: 12),
                                              Text('Change Image'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_outline_rounded,
                                                size: 20,
                                                color: AppTheme.error,
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'Remove Photo',
                                                style: TextStyle(
                                                  color: AppTheme.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (_isEditing)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: TextFormField(
                                    controller: _nameCtrl,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Full Name',
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      profile.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (profile.isEmailVerified) ...[
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.verified,
                                        color: AppTheme.success,
                                        size: 18,
                                      ),
                                    ],
                                  ],
                                ),
                              const SizedBox(height: 4),
                              Text(
                                profile.email,
                                style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.06,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'ROLE: ${profile.role.toUpperCase()}',
                                      style: GoogleFonts.inter(
                                        color: AppTheme.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  if (profile.createdAt != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.textSecondary
                                              .withValues(alpha: 0.12),
                                        ),
                                      ),
                                      child: Text(
                                        'JOINED: ${profile.createdAt!.year}',
                                        style: GoogleFonts.inter(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (!_isEditing) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      _startEditing(profile);
                                    },
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Edit Profile'),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: AppTheme.primary,
                                      ),
                                      foregroundColor: AppTheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ─── Personal Info ──────────────────────
                      StaggeredFadeIn(
                        delay: const Duration(milliseconds: 200),
                        child: _buildInfoCard(
                          title: 'Personal Information',
                          icon: Icons.info_outline_rounded,
                          children: [
                            _buildDetailRow(
                              'Phone',
                              profile.mobNo1,
                              controller: _isEditing ? _mobNo1Ctrl : null,
                              keyboardType: TextInputType.phone,
                            ),
                            if (profile.mobNo2 != null &&
                                    profile.mobNo2!.isNotEmpty ||
                                _isEditing) ...[
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Alt Phone',
                                profile.mobNo2 ?? '',
                                controller: _isEditing ? _mobNo2Ctrl : null,
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                            if (profile.gender != null || _isEditing) ...[
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Gender',
                                profile.gender ?? '',
                                controller: _isEditing ? _genderCtrl : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ─── Address ──────────────────────
                      if (profile.city != null ||
                          profile.country != null ||
                          _isEditing) ...[
                        StaggeredFadeIn(
                          delay: const Duration(milliseconds: 300),
                          child: _buildInfoCard(
                            title: 'Address',
                            icon: Icons.location_on_outlined,
                            children: [
                              if (profile.locationDescription != null &&
                                      profile.locationDescription!.isNotEmpty ||
                                  _isEditing) ...[
                                _buildDetailRow(
                                  'Location',
                                  profile.locationDescription ?? '',
                                  controller: _isEditing
                                      ? _locationDescCtrl
                                      : null,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (profile.landmark != null &&
                                      profile.landmark!.isNotEmpty ||
                                  _isEditing) ...[
                                _buildDetailRow(
                                  'Landmark',
                                  profile.landmark ?? '',
                                  controller: _isEditing ? _landmarkCtrl : null,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (profile.city != null || _isEditing) ...[
                                _buildDetailRow(
                                  'City',
                                  profile.city ?? '',
                                  controller: _isEditing ? _cityCtrl : null,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (profile.state != null || _isEditing) ...[
                                _buildDetailRow(
                                  'State',
                                  profile.state ?? '',
                                  controller: _isEditing ? _stateCtrl : null,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (profile.country != null || _isEditing) ...[
                                _buildDetailRow(
                                  'Country',
                                  profile.country ?? '',
                                  controller: _isEditing ? _countryCtrl : null,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (profile.pincode != null || _isEditing) ...[
                                _buildDetailRow(
                                  'Pincode',
                                  profile.pincode ?? '',
                                  controller: _isEditing ? _pincodeCtrl : null,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ─── Identity Verification ──────────────────────
                      StaggeredFadeIn(
                        delay: const Duration(milliseconds: 400),
                        child: Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.surfaceBorder),
                            boxShadow: AppTheme.surfaceShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.shield_outlined,
                                          color: AppTheme.primary,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Identity Verification',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppTheme.success.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline,
                                          color: AppTheme.success,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          profile.aadharNumber != null
                                              ? 'Verified'
                                              : 'Pending',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundLight.withValues(
                                    alpha: 0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.surfaceBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: Colors.grey.shade200,
                                        image: profile.aadharFileUrl != null
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                  profile.aadharFileUrl!,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: profile.aadharFileUrl == null
                                          ? const Icon(
                                              Icons.credit_card,
                                              color: Colors.grey,
                                              size: 20,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'AADHAAR',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textSecondary,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (_isEditing)
                                            TextFormField(
                                              controller: _aadharNumberCtrl,
                                              keyboardType:
                                                  TextInputType.number,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textPrimary,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'Aadhar Number',
                                                isDense: true,
                                                filled: true,
                                                fillColor: AppTheme
                                                    .backgroundLight
                                                    .withValues(alpha: 0.3),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            )
                                          else
                                            Text(
                                              profile.aadharNumber != null &&
                                                      profile
                                                              .aadharNumber!
                                                              .length ==
                                                          12
                                                  ? '${profile.aadharNumber!.substring(0, 4)} ${profile.aadharNumber!.substring(4, 8)} ${profile.aadharNumber!.substring(8)}'
                                                  : profile.aadharNumber ??
                                                        'Not provided',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: AppTheme.textPrimary,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(
                                      Icons.open_in_new_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'View Document',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primary,
                                    ),
                                    onPressed: () {
                                      // TODO: View adhar document
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    icon: const Icon(
                                      Icons.upload_file_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Replace',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primary,
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : _pickAndUploadAadhar,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── Vehicle Details ──────────────────────
                      StaggeredFadeIn(
                        delay: const Duration(milliseconds: 450),
                        child: Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.surfaceBorder),
                            boxShadow: AppTheme.surfaceShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_car_filled_outlined,
                                    color: AppTheme.accentColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Vehicle Details',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'For PG parking verification',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Divider(color: AppTheme.dividerColor, height: 1),
                              const SizedBox(height: 20),
                              Text(
                                'DO YOU OWN A VEHICLE?',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.surfaceBorder,
                                  ),
                                ),
                                child: IgnorePointer(
                                  ignoring: !_isEditing,
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: currentVehicleType,
                                      isExpanded: true,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppTheme.textSecondary,
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: 'none',
                                          child: Text(
                                            'No Vehicle',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'two-wheeler',
                                          child: Text(
                                            'Two-Wheeler (Bike/Scooter)',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'four-wheeler',
                                          child: Text(
                                            'Four-Wheeler (Car)',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _localVehicleType = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              if (currentVehicleType != 'none') ...[
                                const SizedBox(height: 20),
                                RichText(
                                  text: TextSpan(
                                    text: 'Vehicle Number Plate ',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '*',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                IgnorePointer(
                                  ignoring: !_isEditing,
                                  child: TextFormField(
                                    controller: _vehicleNumberController,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. MH19AC2317',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.5),
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.backgroundLight
                                          .withValues(alpha: 0.3),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppTheme.surfaceBorder,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppTheme.surfaceBorder,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppTheme.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      // Can handle saving locally or wait for main save
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_isEditing)
                        StaggeredFadeIn(
                          delay: const Duration(milliseconds: 500),
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _hasChanges && !_isLoading
                                  ? _updateProfile
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                disabledBackgroundColor: AppTheme.primary
                                    .withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Save Changes',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        )
                      else
                        // ─── Logout Button ────────────────────────────────
                        StaggeredFadeIn(
                          delay: const Duration(milliseconds: 500),
                          child: SizedBox(
                            height: 54,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await ref.read(authProvider.notifier).logout();
                                if (context.mounted) context.go('/login');
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppTheme.error,
                                  width: 1.5,
                                ),
                                foregroundColor: AppTheme.error,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.logout_rounded, size: 18),
                              label: Text(
                                'Logout Session',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentColor),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading profile: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: AppTheme.surfaceShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppTheme.dividerColor, height: 1),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
    Color? highlightColor,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return Row(
      crossAxisAlignment: _isEditing && controller != null
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: _isEditing && controller != null
              ? TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: AppTheme.backgroundLight.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.surfaceBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.surfaceBorder),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(
                        color: AppTheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                )
              : Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isHighlight
                        ? (highlightColor ?? AppTheme.primary)
                        : AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
        ),
      ],
    );
  }
}

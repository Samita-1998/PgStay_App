import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/profile/models/profile_model.dart';
import 'package:pgstay/features/profile/providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _mobNo1Ctrl;
  late TextEditingController _mobNo2Ctrl;
  late TextEditingController _genderCtrl;
  late TextEditingController
  _dobCtrl; // Not using, keeping for now if backend adds it back
  late TextEditingController _professionCtrl; // Not using
  late TextEditingController _locationDescCtrl;
  late TextEditingController _landmarkCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _pincodeCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _mobNo1Ctrl = TextEditingController(text: widget.profile.mobNo1);
    _mobNo2Ctrl = TextEditingController(text: widget.profile.mobNo2 ?? '');
    _genderCtrl = TextEditingController(text: widget.profile.gender ?? '');
    _dobCtrl = TextEditingController(text: '');
    _professionCtrl = TextEditingController(text: '');
    _locationDescCtrl = TextEditingController(
      text: widget.profile.locationDescription ?? '',
    );
    _landmarkCtrl = TextEditingController(text: widget.profile.landmark ?? '');
    _cityCtrl = TextEditingController(text: widget.profile.city ?? '');
    _stateCtrl = TextEditingController(text: widget.profile.state ?? '');
    _countryCtrl = TextEditingController(text: widget.profile.country ?? '');
    _pincodeCtrl = TextEditingController(text: widget.profile.pincode ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobNo1Ctrl.dispose();
    _mobNo2Ctrl.dispose();
    _genderCtrl.dispose();
    _dobCtrl.dispose();
    _professionCtrl.dispose();
    _locationDescCtrl.dispose();
    _landmarkCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile({
        'name': _nameCtrl.text.trim(),
        'mobNo1': _mobNo1Ctrl.text.trim(),
        'mobNo2': _mobNo2Ctrl.text.trim(),
        'gender': _genderCtrl.text.trim(),
        'address': {
          'locationDescription': _locationDescCtrl.text.trim(),
          'landmark': _landmarkCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'state': _stateCtrl.text.trim(),
          'country': _countryCtrl.text.trim(),
          'pincode': _pincodeCtrl.text.trim(),
        },
      });

      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.pop();
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _updateProfile,
              child: Text(
                'Save',
                style: GoogleFonts.inter(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Personal Details'),
              _buildTextField(
                'Full Name',
                _nameCtrl,
                icon: Icons.person_outline,
              ),
              _buildTextField(
                'Phone Number',
                _mobNo1Ctrl,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                'Alternate Phone',
                _mobNo2Ctrl,
                icon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Gender',
                      _genderCtrl,
                      icon: Icons.wc_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      'Date of Birth',
                      _dobCtrl,
                      icon: Icons.calendar_today_outlined,
                      hint: 'YYYY-MM-DD',
                    ),
                  ),
                ],
              ),
              _buildTextField(
                'Profession',
                _professionCtrl,
                icon: Icons.work_outline,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Address'),
              _buildTextField(
                'Address Line 1',
                _locationDescCtrl,
                icon: Icons.home_outlined,
              ),
              _buildTextField(
                'Address Line 2',
                _landmarkCtrl,
                icon: Icons.map_outlined,
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'City',
                      _cityCtrl,
                      icon: Icons.location_city_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      'State',
                      _stateCtrl,
                      icon: Icons.map_outlined,
                    ),
                  ),
                ],
              ),
              _buildTextField(
                'Pincode',
                _pincodeCtrl,
                icon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    TextInputType? keyboardType,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null
              ? Icon(icon, size: 20, color: AppTheme.textHint)
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.surfaceBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.surfaceBorder),
          ),
        ),
        validator: (val) {
          if (label == 'Full Name' || label == 'Phone Number') {
            if (val == null || val.trim().isEmpty) return 'Required';
          }
          return null;
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';
import 'package:pgstay/features/enquiries/models/enquiry_model.dart';
import 'package:pgstay/features/pg_listing/screens/modern_text_field_widget.dart';

class TenantOnboardingScreen extends ConsumerStatefulWidget {
  final EnquiryModel enquiry;

  const TenantOnboardingScreen({super.key, required this.enquiry});

  @override
  ConsumerState<TenantOnboardingScreen> createState() =>
      _TenantOnboardingScreenState();
}

class _TenantOnboardingScreenState extends ConsumerState<TenantOnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  int _maxStepReached = 0;
  final int _totalSteps = 3;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Step 1 Controllers
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  String _selectedRelation = 'Parent';
  bool _verifiedDocuments = false;

  // Step 2 Controllers
  final _securityDepositController = TextEditingController();
  final _depositRefController = TextEditingController();
  final _depositDateController = TextEditingController();
  DateTime? _selectedDepositDate;
  bool _depositReceived = false;

  // Step 3 Controllers
  final _joiningDateController = TextEditingController();
  DateTime? _selectedJoiningDate;
  bool _isSubmitting = false;

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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _securityDepositController.dispose();
    _depositRefController.dispose();
    _depositDateController.dispose();
    _joiningDateController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_formKey.currentState!.validate()) return;

    if (_currentStep == 0 && !_verifiedDocuments) {
      _showSnackBar('Please verify documents to proceed', AppTheme.error);
      return;
    }
    if (_currentStep == 1 && !_depositReceived) {
      _showSnackBar('Please confirm security deposit receipt', AppTheme.error);
      return;
    }
    if (_currentStep == 2 && _selectedJoiningDate == null) {
      _showSnackBar('Please select a joining date', AppTheme.error);
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

  void _submitForm() async {
    setState(() => _isSubmitting = true);
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isSubmitting = false);
    if (mounted) {
      _showSnackBar('Tenant onboarded successfully! 🎉', AppTheme.success);
      context.pop();
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Slate 50, very clean and modern
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Tenant Onboarding',

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
                        children: [_buildStep1(), _buildStep2(), _buildStep3()],
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
    final labels = ['Verification', 'Financials', 'Joining'];
    final icons = [
      Icons.verified_user_outlined,
      Icons.attach_money_rounded,
      Icons.calendar_today_rounded,
    ];

    return GestureDetector(
      onTap: () {
        if (index <= _maxStepReached && index != _currentStep) {
          if (index > _currentStep) {
            if (!_formKey.currentState!.validate()) return;
            if (_currentStep == 0 && !_verifiedDocuments) {
              _showSnackBar(
                'Please verify documents to proceed',
                AppTheme.error,
              );
              return;
            }
            if (_currentStep == 1 && !_depositReceived) {
              _showSnackBar(
                'Please confirm security deposit receipt',
                AppTheme.error,
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
                  height: 2,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.primary
                        : isActive
                        ? AppTheme.primary.withOpacity(0.4)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              if (index < _totalSteps - 1) ...[const SizedBox(width: 0)],
            ],
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 48 : 40,
            height: isActive ? 48 : 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive || isCompleted ? AppTheme.primary : Colors.white,
              border: Border.all(
                color: isActive || isCompleted
                    ? Colors.transparent
                    : const Color(0xFFCBD5E1),
                width: 2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 24,
                    )
                  : Icon(
                      icons[index],
                      color: isActive ? Colors.white : const Color(0xFF94A3B8),
                      size: isActive ? 24 : 20,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: GoogleFonts.plusJakartaSans(
              color: isActive ? AppTheme.primary : const Color(0xFF64748B),
              fontSize: isActive ? 13 : 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: 0.3,
            ),
            child: Text(labels[index]),
          ),
        ],
      ),
    );
  }

  // ==================== GLASS CARD ====================
  Widget _buildGlassCard({
    String? title,
    String? subtitle,
    IconData? icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF94A3B8).withOpacity(0.15),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null && icon != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
                  ),
                ),
                child: _buildSectionHeader(icon, title, subtitle ?? ''),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ==================== STEP 1: VERIFICATION ====================
  Widget _buildStep1() {
    final user = widget.enquiry.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGlassCard(
            title: 'Tenant Details',
            subtitle: 'Verify basic information',
            icon: Icons.person_outline,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    backgroundImage:
                        (user?.picture != null && user!.picture!.isNotEmpty)
                        ? NetworkImage(user.picture!)
                        : null,
                    child: (user?.picture == null || user!.picture!.isEmpty)
                        ? Icon(Icons.person, color: AppTheme.primary, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Unknown User',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          user?.email ?? 'No email',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.phone,
                      'Mobile 1',
                      user?.mobNo1 ?? 'N/A',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.phone_android,
                      'Mobile 2',
                      'N/A',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.badge_outlined,
                      'Aadhaar',
                      user?.aadharNumber ?? 'Not Provided',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.male,
                      'Gender',
                      user?.gender ?? 'Not Provided',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGlassCard(
            title: 'Aadhar Document',
            subtitle: 'Verify identity proof',
            icon: Icons.shield_outlined,
            children: [
              Text(
                'Aadhaar Number',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.aadharNumber ?? 'Not Provided',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              if (user?.aadharFileUrl != null &&
                  user!.aadharFileUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    user.aadharFileUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildNoAadharImage(),
                  ),
                )
              else
                _buildNoAadharImage(),
            ],
          ),
          const SizedBox(height: 16),
          _buildGlassCard(
            title: 'Emergency Contact',
            subtitle: 'In case of emergency',
            icon: Icons.contact_phone_outlined,
            children: [
              _buildModernTextField(
                label: 'Contact Name',
                controller: _contactNameController,
                hint: 'e.g. Ramesh Kumar',
                icon: Icons.person_outline,
                required: true,
              ),
              const SizedBox(height: 12),
              _buildModernTextField(
                label: 'Phone Number',
                controller: _contactPhoneController,
                hint: 'e.g. 9876543210',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                required: true,
              ),
              const SizedBox(height: 12),
              Text(
                'Relation *',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRelation,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF9CA3AF),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    items: ['Parent', 'Sibling', 'Spouse', 'Guardian', 'Friend']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRelation = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGlassCard(
            children: [
              InkWell(
                onTap: () =>
                    setState(() => _verifiedDocuments = !_verifiedDocuments),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _verifiedDocuments
                              ? AppTheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _verifiedDocuments
                                ? AppTheme.primary
                                : const Color(0xFFD1D5DB),
                            width: 2,
                          ),
                        ),
                        child: _verifiedDocuments
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I have verified all documents',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Confirm that Aadhaar and profile details match the tenant.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Center(child: Icon(icon, size: 20, color: AppTheme.primary)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoAadharImage() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 8),
            Text(
              'Document image not available',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== STEP 2: FINANCIALS ====================
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGlassCard(
            title: 'Financial Terms',
            subtitle: 'Deposit and Payment Info',
            icon: Icons.account_balance_wallet_outlined,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFDBA74),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFEA580C),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bed assignment is blocked until security deposit is confirmed.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9A3412),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                label: 'Security Deposit Amount (₹)',
                controller: _securityDepositController,
                hint: 'e.g. 10000',
                icon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
                required: true,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  if (!_depositReceived &&
                      _securityDepositController.text.trim().isEmpty) {
                    _showSnackBar(
                      'Please enter Security Deposit Amount first',
                      AppTheme.error,
                    );
                    return;
                  }
                  setState(() => _depositReceived = !_depositReceived);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _depositReceived
                        ? AppTheme.success.withOpacity(0.04)
                        : Colors.white,
                    border: Border.all(
                      color: _depositReceived
                          ? AppTheme.success.withOpacity(0.5)
                          : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      if (!_depositReceived)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _depositReceived
                              ? AppTheme.success.withOpacity(0.15)
                              : const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_user_outlined,
                          color: _depositReceived
                              ? AppTheme.success
                              : const Color(0xFF9CA3AF),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Security Deposit',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: _depositReceived
                                          ? AppTheme.success
                                          : AppTheme.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                Icon(
                                  _depositReceived
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: _depositReceived
                                      ? AppTheme.success
                                      : const Color(0xFFD1D5DB),
                                  size: 22,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to mark as collected',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            if (_depositReceived) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.success,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Received',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_depositReceived) ...[
                const SizedBox(height: 16),
                _buildModernTextField(
                  label: 'Deposit Ref (Txn ID)',
                  controller: _depositRefController,
                  hint: 'e.g. TXN12345',
                  icon: Icons.receipt_long_outlined,
                ),
                const SizedBox(height: 16),
                _buildDatePicker(
                  label: 'Deposit Date *',
                  controller: _depositDateController,
                  selectedDate: _selectedDepositDate,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDepositDate = date;
                      _depositDateController.text =
                          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                    });
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==================== STEP 3: JOINING DATE ====================
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGlassCard(
            title: 'Joining Date',
            subtitle: 'Select move-in date',
            icon: Icons.calendar_month_outlined,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Rent billing starts from this date. The first month\'s rent will be prorated if the tenant doesn\'t move in on the 1st.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildDatePicker(
                label: 'Joining Date *',
                controller: _joiningDateController,
                selectedDate: _selectedJoiningDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedJoiningDate = date;
                    _joiningDateController.text =
                        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                  });
                },
              ),
              if (_selectedJoiningDate != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Joining Date',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_selectedJoiningDate!.day.toString().padLeft(2, '0')} ${_getMonth(_selectedJoiningDate!.month)} ${_selectedJoiningDate!.year}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getMonth(int month) {
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
    return months[month - 1];
  }

  Widget _buildDatePicker({
    required String label,
    required TextEditingController controller,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: AppTheme.primary,
                      onPrimary: Colors.white,
                      onSurface: AppTheme.textPrimary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              onDateSelected(date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: AppTheme.textHint,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? 'YYYY-MM-DD' : controller.text,
                    style: GoogleFonts.inter(
                      color: controller.text.isEmpty
                          ? AppTheme.textHint
                          : AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== TEXT FIELD WRAPPER ====================
  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return ModernTextFieldWidget(
      label: label,
      controller: controller,
      hint: hint,
      icon: icon,
      keyboardType: keyboardType,
      maxLines: maxLines,
      required: required,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            }
          : null,
    );
  }

  // ==================== BOTTOM NAV ====================
  Widget _buildModernBottomNav() {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : (_currentStep > 0 ? _prevStep : () => context.pop()),
              icon: Icon(
                _currentStep > 0
                    ? Icons.arrow_back_rounded
                    : Icons.close_rounded,
                size: 18,
              ),
              label: Text(
                _currentStep > 0 ? 'Previous' : 'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _currentStep == _totalSteps - 1
                                ? 'Complete Onboarding'
                                : 'Save & Continue',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _currentStep == _totalSteps - 1
                              ? Icons.check_circle_rounded
                              : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

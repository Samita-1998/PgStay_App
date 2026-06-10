import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Selected role maps to backend role types:
  // Tenant -> 'user'
  // Owner -> 'owner'
  // Manager -> 'manager'
  // Staff -> 'employee'
  String _selectedRole = 'user'; 
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          mobNo1: _phoneController.text.trim(),
          role: _selectedRole,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please log in.'),
          backgroundColor: AppTheme.success,
        ),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      'Create Account',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'Join PGStay and experience clean living management',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Card
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(28.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.surfaceBorder),
                        boxShadow: AppTheme.surfaceShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Full Name
                          _buildLabel('Full Name'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            validator: (val) => val == null || val.isEmpty ? 'Please enter your name' : null,
                            decoration: const InputDecoration(
                              hintText: 'John Doe',
                              prefixIcon: Icon(Icons.person_outline, size: 20),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Email Address
                          _buildLabel('Email Address'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Please enter your email';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: 'name@example.com',
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 18),

                          // Mobile Number
                          _buildLabel('Mobile Number'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _phoneController,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Please enter your mobile number';
                              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(val)) {
                                return 'Please enter a valid 10-digit Indian number';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: '9876543210',
                              prefixIcon: Icon(Icons.phone_outlined, size: 20),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 18),

                          // Role Selector Widget
                          _buildLabel('Select Your Role'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildRoleSelectorItem('Tenant', 'user'),
                              const SizedBox(width: 8),
                              _buildRoleSelectorItem('Owner', 'owner'),
                              const SizedBox(width: 8),
                              _buildRoleSelectorItem('Manager', 'manager'),
                              const SizedBox(width: 8),
                              _buildRoleSelectorItem('Staff', 'employee'),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Password
                          _buildLabel('Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                            decoration: InputDecoration(
                              hintText: 'Enter secure password',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Register Button
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: authState.isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Create Account',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),

                          if (authState.hasError) ...[
                            const SizedBox(height: 14),
                            Text(
                              authState.error.toString().replaceAll('Exception:', '').trim(),
                              style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Login Link
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 400),
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: 'Log in',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildRoleSelectorItem(String label, String roleValue) {
    final isSelected = _selectedRole == roleValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = roleValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.surfaceBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

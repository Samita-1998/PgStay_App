import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please check your credentials.'),
          backgroundColor: AppTheme.error,
        ),
      );
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
            padding: const EdgeInsets.symmetric(
              horizontal: 28.0,
              vertical: 16.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ─── Animated Brand Icon ─────────────────────────────
                  ScaleIn(
                    delay: const Duration(milliseconds: 100),
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final glow = 0.04 + (_pulseController.value * 0.06);
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary.withOpacity(0.06),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(glow),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.home_work_rounded,
                            size: 48,
                            color: AppTheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Title ────────────────────────────────────────────
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'Welcome Back',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      'Log in to PGStay to continue',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ─── Card Form ────────────────────────────────────────
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 400),
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
                          // Email Field
                          _buildLabel('Email Address'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: 'name@example.com',
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLabel('Password'),
                              GestureDetector(
                                onTap: () => context.push('/forgot-password'),
                                child: Text(
                                  'Forgot?',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                  color: AppTheme.textHint,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Login Button
                          _buildPremiumButton(
                            label: 'Login',
                            isLoading: authState.isLoading,
                            onPressed: authState.isLoading ? null : _login,
                          ),

                          if (authState.hasError) ...[
                            const SizedBox(height: 16),
                            Text(
                              authState.error
                                  .toString()
                                  .replaceAll('Exception:', '')
                                  .trim(),
                              style: const TextStyle(
                                color: AppTheme.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Register Link ─────────────────────────────────────
                  StaggeredFadeIn(
                    delay: const Duration(milliseconds: 500),
                    child: TextButton(
                      onPressed: () => context.go('/register'),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: 'Sign up',
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
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildPremiumButton({
    required String label,
    required bool isLoading,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          shadowColor: AppTheme.primary.withOpacity(0.2),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cityController;
  late final TextEditingController _budgetController;
  late String _selectedPgType;
  late String _selectedOccupancy;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: ref.read(pgSearchCityProvider));
    final currentMaxPrice = ref.read(pgMaxPriceFilterProvider);
    _budgetController = TextEditingController(
      text: currentMaxPrice > 0 ? currentMaxPrice.toStringAsFixed(0) : '',
    );
    _selectedPgType = ref.read(pgTypeFilterProvider);
    _selectedOccupancy = ref.read(pgOccupancyFilterProvider);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _savePreferences() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(pgSearchCityProvider.notifier).state = _cityController.text.trim();
    ref.read(pgTypeFilterProvider.notifier).state = _selectedPgType;
    ref.read(pgOccupancyFilterProvider.notifier).state = _selectedOccupancy;

    final price = double.tryParse(_budgetController.text) ?? 0.0;
    ref.read(pgMaxPriceFilterProvider.notifier).state = price;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferences saved! Discover tab updated.'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
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
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withOpacity(0.06),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.1), width: 2),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user?.name ?? 'PGStay User',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'user@pgstay.com',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
                      ),
                      child: Text(
                        'ROLE: ${user?.role.toUpperCase() ?? 'USER'}',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ─── Search Preferences Form ──────────────────────
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.surfaceBorder),
                  boxShadow: AppTheme.surfaceShadow,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded, color: AppTheme.accentColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Search Preferences',
                            style: GoogleFonts.plusJakartaSans(
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

                      // Preferred City
                      _buildLabel('Preferred City'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Pune, Mumbai',
                          prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Max Budget
                      _buildLabel('Max Budget (₹/Month)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _budgetController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 10000',
                          prefixIcon: Icon(Icons.payments_outlined, size: 20),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // PG Type
                      _buildLabel('Preferred PG Type'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedPgType,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.group_outlined, size: 20),
                        ),
                        dropdownColor: Colors.white,
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All Types')),
                          DropdownMenuItem(value: 'Boys', child: Text('Boys PG')),
                          DropdownMenuItem(value: 'Girls', child: Text('Girls PG')),
                          DropdownMenuItem(value: 'Coliving', child: Text('Coliving')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPgType = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Occupancy
                      _buildLabel('Preferred Occupancy'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedOccupancy,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.single_bed_outlined, size: 20),
                        ),
                        dropdownColor: Colors.white,
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All Sharing')),
                          DropdownMenuItem(value: 'Single', child: Text('Single Sharing')),
                          DropdownMenuItem(value: 'Double', child: Text('Double Sharing')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedOccupancy = val);
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _savePreferences,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            'Save Preferences',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ─── Logout Button ────────────────────────────────
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 300),
              child: SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.error, width: 1.5),
                    foregroundColor: AppTheme.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(
                    'Logout Session',
                    style: GoogleFonts.plusJakartaSans(
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
}

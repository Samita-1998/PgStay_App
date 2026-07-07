import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/features/profile/providers/profile_provider.dart';
import 'package:pgstay/features/profile/screens/edit_profile_screen.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'My Profile',
        showBackButton: false,
        pinnedSCurve: true,
        isCompact: true,
      ),
      body: profileAsync.when(
        data: (profile) {
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
                  120 + MediaQuery.of(context).padding.top + 32,
                  24,
                  100,
                ),
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
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primary.withValues(alpha: 0.06),
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
                                        image: NetworkImage(profile.picture!),
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
                            const SizedBox(height: 14),
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
                                      color: AppTheme.textSecondary.withValues(
                                        alpha: 0.06,
                                      ),
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
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => context.push(
                                  '/edit-profile',
                                  extra: profile,
                                ),
                                icon: const Icon(Icons.edit_rounded, size: 16),
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
                          _buildDetailRow('Phone', profile.mobNo1),
                          if (profile.mobNo2 != null &&
                              profile.mobNo2!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow('Alt Phone', profile.mobNo2!),
                          ],
                          if (profile.gender != null) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow('Gender', profile.gender!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── Address ──────────────────────
                    if (profile.city != null || profile.country != null) ...[
                      StaggeredFadeIn(
                        delay: const Duration(milliseconds: 300),
                        child: _buildInfoCard(
                          title: 'Address',
                          icon: Icons.location_on_outlined,
                          children: [
                            if (profile.locationDescription != null &&
                                profile.locationDescription!.isNotEmpty) ...[
                              _buildDetailRow(
                                'Location',
                                profile.locationDescription!,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (profile.landmark != null &&
                                profile.landmark!.isNotEmpty) ...[
                              _buildDetailRow('Landmark', profile.landmark!),
                              const SizedBox(height: 12),
                            ],
                            if (profile.city != null) ...[
                              _buildDetailRow('City', profile.city!),
                              const SizedBox(height: 12),
                            ],
                            if (profile.state != null) ...[
                              _buildDetailRow('State', profile.state!),
                              const SizedBox(height: 12),
                            ],
                            if (profile.country != null) ...[
                              _buildDetailRow('Country', profile.country!),
                              const SizedBox(height: 12),
                            ],
                            if (profile.pincode != null) ...[
                              _buildDetailRow('Pincode', profile.pincode!),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ─── KYC Details ──────────────────────
                    StaggeredFadeIn(
                      delay: const Duration(milliseconds: 400),
                      child: _buildInfoCard(
                        title: 'KYC & Verification',
                        icon: Icons.verified_user_outlined,
                        children: [
                          _buildDetailRow(
                            'Aadhar Status',
                            profile.aadharNumber != null
                                ? 'SUBMITTED'
                                : 'PENDING',
                            isHighlight: profile.aadharNumber != null,
                            highlightColor: profile.aadharNumber != null
                                ? AppTheme.success
                                : AppTheme.warning,
                          ),
                          if (profile.aadharNumber != null) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              'Aadhar Number',
                              'XXXX XXXX ${profile.aadharNumber!.length > 4 ? profile.aadharNumber!.substring(profile.aadharNumber!.length - 4) : profile.aadharNumber}',
                            ),
                          ],
                          if (profile.aadharFileUrl != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.surfaceBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.description_outlined,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Aadhar Document Uploaded',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.success,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

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
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          child: Text(
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/features/complaints/providers/complaint_provider.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';

class ComplaintsListScreen extends ConsumerWidget {
  const ComplaintsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final isStaff = user?.role == 'manager' || user?.role == 'owner';
    final complaints = ref.watch(isStaff ? propertyComplaintsProvider : userComplaintsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          isStaff ? 'Property Complaints' : 'My Complaints',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      floatingActionButton: !isStaff
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/complaints/create'),
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'Raise Issue',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      body: complaints.isEmpty
          ? Center(
              child: Text(
                'No complaints found.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20).copyWith(bottom: 100),
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                final complaint = complaints[index];
                return StaggeredFadeIn(
                  delay: Duration(milliseconds: 50 * index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.surfaceBorder),
                      boxShadow: AppTheme.softShadow(opacity: 0.02),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                complaint.category,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            _buildStatusBadge(complaint.status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          complaint.description,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: AppTheme.dividerColor),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'By: ${complaint.userName}',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${complaint.createdAt.day}/${complaint.createdAt.month}/${complaint.createdAt.year}',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textHint,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (isStaff && complaint.status != 'Resolved') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    ref.read(complaintNotifierProvider.notifier).updateStatus(complaint.id, 'In Progress');
                                  },
                                  child: const Text('Mark In Progress'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    ref.read(complaintNotifierProvider.notifier).updateStatus(complaint.id, 'Resolved');
                                  },
                                  child: const Text('Resolve'),
                                ),
                              ),
                            ],
                          )
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;

    switch (status) {
      case 'Resolved':
        color = AppTheme.success;
        bgColor = AppTheme.success.withOpacity(0.1);
        break;
      case 'In Progress':
        color = AppTheme.warning;
        bgColor = AppTheme.warning.withOpacity(0.1);
        break;
      default:
        color = AppTheme.error;
        bgColor = AppTheme.error.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

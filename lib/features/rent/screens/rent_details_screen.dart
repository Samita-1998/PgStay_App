import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/features/rent/models/rent_model.dart';

class RentDetailsScreen extends StatelessWidget {
  final RentModel rent;
  const RentDetailsScreen({super.key, required this.rent});

  String _formatDate(DateTime? d) {
    if (d == null) return 'N/A';
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
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  Color _getStatusColor() {
    switch (rent.status) {
      case 'paid':
        return AppTheme.success;
      case 'pending':
        return AppTheme.warning;
      case 'overdue':
        return AppTheme.error;
      case 'waived':
        return AppTheme.textHint;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Rent Details',
          style: AppTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 100),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(color: AppTheme.surfaceBorder),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rent.month,
                          style: AppTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSM,
                            ),
                          ),
                          child: Text(
                            rent.status.toUpperCase(),
                            style: AppTheme.textTheme.labelMedium?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '₹${rent.amount.toInt()}',
                      style: AppTheme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due on ${_formatDate(rent.dueDate)}',
                      style: AppTheme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            StaggeredFadeIn(
              delay: const Duration(milliseconds: 200),
              child: Text(
                'Payment Information',
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(color: AppTheme.surfaceBorder),
                  boxShadow: AppTheme.surfaceShadow,
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Amount Paid',
                      '₹${rent.paidAmount.toInt()}',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Penalty Amount',
                      '₹${rent.penaltyAmount.toInt()}',
                    ),
                    if (rent.paidDate != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow('Paid On', _formatDate(rent.paidDate)),
                    ],
                    if (rent.paymentMethod != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Payment Method',
                        rent.paymentMethod!.toUpperCase(),
                      ),
                    ],
                    if (rent.receiptNo != null &&
                        rent.receiptNo!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow('Reference No.', rent.receiptNo!),
                    ],
                  ],
                ),
              ),
            ),

            if (rent.staffRemarks != null && rent.staffRemarks!.isNotEmpty) ...[
              const SizedBox(height: 24),
              StaggeredFadeIn(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'Notes',
                  style: AppTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StaggeredFadeIn(
                delay: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notes_rounded,
                        color: AppTheme.accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rent.staffRemarks!,
                          style: GoogleFonts.inter(
                            textStyle: AppTheme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTheme.textTheme.labelMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

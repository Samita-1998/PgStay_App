import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/features/enquiries/models/enquiry_model.dart';

class EnquiryDetailsScreen extends StatelessWidget {
  final EnquiryModel enquiry;
  const EnquiryDetailsScreen({super.key, required this.enquiry});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'interested':
        return Colors.blue;
      case 'contacted':
        return Colors.orange;
      case 'visited':
        return Colors.purple;
      case 'deal done':
      case 'dealdone':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(enquiry.status);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Enquiry Details',
          style: AppTheme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
                          'Status',
                          style: AppTheme.textTheme.titleSmall?.copyWith(color: AppTheme.textSecondary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                          ),
                          child: Text(
                            enquiry.status.toUpperCase(),
                            style: AppTheme.textTheme.labelMedium?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: AppTheme.dividerColor),
                    const SizedBox(height: 16),
                    _buildDetailRow('Enquiry ID', enquiry.id),
                    const SizedBox(height: 12),
                    _buildDetailRow('Created At', _formatDate(enquiry.createdAt)),
                    const SizedBox(height: 12),
                    _buildDetailRow('Last Updated', _formatDate(enquiry.updatedAt)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            StaggeredFadeIn(
              delay: const Duration(milliseconds: 200),
              child: Text(
                'Property Information',
                style: AppTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (enquiry.pg != null) ...[
                      _buildDetailRow('PG Name', enquiry.pg!.name),
                      const SizedBox(height: 12),
                    ],
                    if (enquiry.post != null) ...[
                      _buildDetailRow('Post Title', enquiry.post!.title),
                      const SizedBox(height: 12),
                      _buildDetailRow('Occupancy', enquiry.post!.occupancyType ?? 'N/A'),
                      if (enquiry.post!.minPrice != null) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow('Price', '₹${enquiry.post!.minPrice?.toInt()}'),
                      ],
                    ],
                    const SizedBox(height: 16),
                    if (enquiry.post != null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.push('/pg-details/${enquiry.post!.id}'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primary),
                            foregroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
                          ),
                          child: const Text('View Post Details'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (enquiry.staffRemarks != null && enquiry.staffRemarks!.isNotEmpty) ...[
              StaggeredFadeIn(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'Staff Remarks',
                  style: AppTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
                    border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.comment_rounded, color: AppTheme.accentColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          enquiry.staffRemarks!,
                          style: AppTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            height: 1.5,
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

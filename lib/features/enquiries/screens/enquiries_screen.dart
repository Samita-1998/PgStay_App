import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/enquiries/providers/enquiries_provider.dart';

class EnquiriesScreen extends ConsumerWidget {
  const EnquiriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enquiriesAsync = ref.watch(enquiriesListProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'My Enquiries',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: enquiriesAsync.when(
        data: (enquiries) {
          if (enquiries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark_outline_rounded, size: 64, color: AppTheme.textHint),
                  const SizedBox(height: 16),
                  Text(
                    'No enquiries submitted yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      'Browse active stay listings in the Discover tab and click "Submit Enquiry" to get started.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Discover Stays'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(enquiriesListProvider),
            color: AppTheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              itemCount: enquiries.length,
              itemBuilder: (context, index) {
                final enquiry = enquiries[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.surfaceBorder),
                    boxShadow: AppTheme.surfaceShadow,
                  ),
                  child: InkWell(
                    onTap: () {
                      if (enquiry.post != null) {
                        context.push('/pg-details/${enquiry.post!.id}');
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  enquiry.pg?.name ?? 'StaySync PG',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              _buildStatusBadge(enquiry.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            enquiry.post?.title ?? 'Vacancy Inquiry',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: AppTheme.dividerColor, height: 1),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Submitted: ${_formatDate(enquiry.createdAt)}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textHint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'View Details',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.primary),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentColor),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load enquiries',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(err.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(enquiriesListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'interested':
        badgeColor = Colors.orange.withOpacity(0.08);
        textColor = Colors.orange;
        break;
      case 'contacted':
        badgeColor = AppTheme.primary.withOpacity(0.08);
        textColor = AppTheme.primary;
        break;
      case 'visited':
        badgeColor = AppTheme.accentColor.withOpacity(0.08);
        textColor = AppTheme.accentColor;
        break;
      case 'dealdone':
        badgeColor = AppTheme.success.withOpacity(0.08);
        textColor = AppTheme.success;
        break;
      case 'rejected':
      case 'inventoryfull':
        badgeColor = AppTheme.error.withOpacity(0.08);
        textColor = AppTheme.error;
        break;
      default:
        badgeColor = AppTheme.textHint.withOpacity(0.08);
        textColor = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'N/A';
    }
  }
}

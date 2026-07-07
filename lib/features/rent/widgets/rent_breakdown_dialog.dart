import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/rent/models/rent_model.dart';

class RentBreakdownDialog extends StatelessWidget {
  final RentModel rent;

  const RentBreakdownDialog({super.key, required this.rent});

  String _formatMonth(String monthStr) {
    try {
      final parts = monthStr.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return monthStr;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final double totalAmount = rent.amount + rent.penaltyAmount;
    final double remaining = totalAmount - rent.paidAmount;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF191A25), // Matches the image dark background
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rent Payment Breakdown',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section 1: Rent Period
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'RENT PERIOD',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF6B4EFF), // Purple hint
                                letterSpacing: 1,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: rent.status == 'paid' ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.warning.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: rent.status == 'paid' ? AppTheme.success.withValues(alpha: 0.5) : AppTheme.warning.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                rent.status == 'paid' ? 'Paid' : (rent.status == 'partial' ? 'Partial' : 'Pending'),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: rent.status == 'paid' ? AppTheme.success : AppTheme.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatMonth(rent.month),
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${rent.pgName ?? 'PG'} · Bed ${rent.bedNumber ?? 'N/A'} · Room ${rent.roomNumber ?? 'N/A'}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            text: 'Days Occupied: ',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white54,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: '30 days',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF6B4EFF),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Section 2: Tenant Details
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TENANT DETAILS',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white38,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailRichText('Name: ', rent.userName ?? 'N/A'),
                            ),
                            Expanded(
                              child: _buildDetailRichText('Phone: ', rent.userPhone ?? 'N/A'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRichText('Email: ', rent.userEmail ?? 'N/A'),
                      ],
                    ),
                  ),

                  // Section 3: Financial Breakdown
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FINANCIAL BREAKDOWN',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white38,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBreakdownRow('Base Rent:', rent.amount, isBold: false),
                        if (rent.penaltyAmount > 0) ...[
                          const SizedBox(height: 12),
                          _buildBreakdownRow('Late Penalty:', rent.penaltyAmount, isBold: false, color: AppTheme.error),
                        ],
                        const SizedBox(height: 16),
                        Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                        const SizedBox(height: 16),
                        _buildBreakdownRow('Total Due:', totalAmount, isBold: true, fontSize: 16),
                        const SizedBox(height: 12),
                        _buildBreakdownRow('Amount Paid:', rent.paidAmount, isBold: true, color: AppTheme.success, fontSize: 16),
                        const SizedBox(height: 12),
                        _buildBreakdownRow('Outstanding Balance:', remaining < 0 ? 0 : remaining, isBold: true, color: Colors.white54, fontSize: 14),
                      ],
                    ),
                  ),

                  // Section 4: Transaction Info
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRANSACTION INFO',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white38,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Payment Method',
                                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.payments_outlined, color: AppTheme.success, size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          (rent.paymentMethod ?? 'N/A').toUpperCase().replaceAll('_', ' '),
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Transaction Date',
                                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatDate(rent.paidDate),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Transaction Reference / Txn ID',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (rent.receiptNo == null || rent.receiptNo!.isEmpty) ? '-' : rent.receiptNo!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Recorded By',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          rent.staffRemarks != null && rent.staffRemarks!.isNotEmpty ? rent.staffRemarks! : 'System',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4EFF), // Exact purple from image
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Close Details',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
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

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF24243A), // Slightly lighter than background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }

  Widget _buildDetailRichText(String label, String value) {
    return RichText(
      text: TextSpan(
        text: label,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
        children: [
          TextSpan(
            text: value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, {bool isBold = false, Color color = Colors.white, double fontSize = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? color : Colors.white54,
          ),
        ),
        Text(
          '₹${amount.toInt()}',
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

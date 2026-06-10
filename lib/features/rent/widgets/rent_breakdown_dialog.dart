import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/rent/models/rent_model.dart';

class RentBreakdownDialog extends StatelessWidget {
  final RentModel rent;

  const RentBreakdownDialog({super.key, required this.rent});

  @override
  Widget build(BuildContext context) {
    final double totalAmount = rent.amount + rent.penaltyAmount;
    final double remaining = totalAmount - rent.paidAmount;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E), // Premium dark background
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rent Breakdown',
                      style: GoogleFonts.plusJakartaSans(
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
                const SizedBox(height: 20),

                // User Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Text(
                    '${rent.userName ?? 'Tenant'} · Bed ${rent.bedNumber ?? 'N/A'} · ${rent.month}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Breakdown Items
                _buildBreakdownRow('Base Rent', rent.amount, isSub: false),
                if (rent.penaltyAmount > 0) ...[
                  const SizedBox(height: 12),
                  _buildBreakdownRow('Late Payment Penalty', rent.penaltyAmount, isSub: false, isError: true),
                ],
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),
                
                _buildBreakdownRow('Total Amount', totalAmount, isSub: false, isBold: true),
                const SizedBox(height: 12),
                _buildBreakdownRow('Amount Paid', rent.paidAmount, isSub: true, isSuccess: true),
                
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),

                _buildBreakdownRow(
                  'Balance Remaining', 
                  remaining < 0 ? 0 : remaining, 
                  isSub: false, 
                  isBold: true,
                  isWarning: remaining > 0,
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label, 
    double amount, {
    bool isSub = false, 
    bool isBold = false,
    bool isError = false,
    bool isSuccess = false,
    bool isWarning = false,
  }) {
    Color textColor = Colors.white;
    if (isError) textColor = AppTheme.error;
    if (isSuccess) textColor = AppTheme.success;
    if (isWarning) textColor = AppTheme.warning;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? Colors.white : Colors.white70,
          ),
        ),
        Text(
          '${isSub ? '-' : ''}₹${amount.toInt()}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/features/booking/models/booking_model.dart';
import 'package:pgstay/features/booking/providers/booking_provider.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  final String pgId;
  final String pgName;
  final String roomId;
  final String roomType;
  final double pricePerMonth;

  const BookingFlowScreen({
    super.key,
    required this.pgId,
    required this.pgName,
    required this.roomId,
    required this.roomType,
    required this.pricePerMonth,
  });

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  int _currentStep = 0;
  int _durationMonths = 1;
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Complete Booking',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepper(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: StaggeredFadeIn(
                  key: ValueKey(_currentStep),
                  delay: const Duration(milliseconds: 100),
                  child: _buildCurrentStepContent(),
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.surfaceBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepIndicator(0, 'Details'),
          _buildStepLine(),
          _buildStepIndicator(1, 'Review'),
          _buildStepLine(),
          _buildStepIndicator(2, 'Payment'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    final isActive = _currentStep >= stepIndex;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.primary : AppTheme.surfaceBorder,
          ),
          alignment: Alignment.center,
          child: Text(
            (stepIndex + 1).toString(),
            style: GoogleFonts.plusJakartaSans(
              color: isActive ? Colors.white : AppTheme.textHint,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: isActive ? AppTheme.primary : AppTheme.textHint,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 12).copyWith(bottom: 24),
        color: AppTheme.surfaceBorder,
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Details();
      case 1:
        return _buildStep2Review();
      case 2:
        return _buildStep3Payment();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1Details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        _buildPropertyCard(),
        const SizedBox(height: 24),

        Text(
          'Check-in Date',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _checkInDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );
            if (date != null) {
              setState(() => _checkInDate = date);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_checkInDate.day}/${_checkInDate.month}/${_checkInDate.year}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Duration (Months)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildDurationButton(-1),
            Expanded(
              child: Text(
                '$_durationMonths Month${_durationMonths > 1 ? 's' : ''}',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            _buildDurationButton(1),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationButton(int change) {
    return InkWell(
      onTap: () {
        setState(() {
          _durationMonths = (_durationMonths + change).clamp(1, 12);
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        alignment: Alignment.center,
        child: Icon(
          change > 0 ? Icons.add_rounded : Icons.remove_rounded,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildPropertyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.primaryGlow(),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.apartment_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pgName,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.roomType,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Review() {
    final totalRent = widget.pricePerMonth * _durationMonths;
    final securityDeposit = widget.pricePerMonth; // 1 month deposit
    final grandTotal = totalRent + securityDeposit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Summary',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Column(
            children: [
              _buildReviewRow('PG Name', widget.pgName),
              const SizedBox(height: 12),
              _buildReviewRow('Room Type', widget.roomType),
              const SizedBox(height: 12),
              _buildReviewRow('Duration', '$_durationMonths Months'),
              const SizedBox(height: 12),
              _buildReviewRow(
                'Check-in',
                '${_checkInDate.day}/${_checkInDate.month}/${_checkInDate.year}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Payment Breakdown',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _buildPriceRow('Monthly Rent', widget.pricePerMonth),
              const SizedBox(height: 12),
              _buildPriceRow('Total Rent ($_durationMonths months)', totalRent),
              const SizedBox(height: 12),
              _buildPriceRow('Security Deposit', securityDeposit),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: AppTheme.surfaceBorder),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '₹${grandTotal.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Payment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        _buildPaymentOption(
          icon: Icons.account_balance_wallet_rounded,
          title: 'UPI / GPay / PhonePe',
          subtitle: 'Instant transfer via UPI apps',
          isSelected: true,
        ),
        const SizedBox(height: 16),
        _buildPaymentOption(
          icon: Icons.credit_card_rounded,
          title: 'Credit / Debit Card',
          subtitle: 'Visa, Mastercard, RuPay',
          isSelected: false,
        ),
        const SizedBox(height: 16),
        _buildPaymentOption(
          icon: Icons.account_balance_rounded,
          title: 'Net Banking',
          subtitle: 'All major Indian banks',
          isSelected: false,
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceBorder,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : AppTheme.backgroundLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle_rounded, color: AppTheme.primary),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppTheme.softShadow(opacity: 0.05),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  child: const Text('Back'),
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _handleNext,
              child: Text(_currentStep == 2 ? 'Pay Now' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() async {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      // Process payment and save booking
      final user = ref.read(authProvider).valueOrNull;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please login to book')));
        return;
      }

      final securityDeposit = widget.pricePerMonth;

      final booking = BookingModel(
        id: 'B${DateTime.now().millisecondsSinceEpoch}',
        pgId: widget.pgId,
        pgName: widget.pgName,
        userId: user.id,
        roomId: widget.roomId,
        roomType: widget.roomType,
        checkInDate: _checkInDate,
        durationMonths: _durationMonths,
        totalAmount: (widget.pricePerMonth * _durationMonths) + securityDeposit,
        amountPaid: securityDeposit, // Paying deposit upfront
        status: 'confirmed',
      );

      // Show processing dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentColor),
        ),
      );

      await ref.read(bookingNotifierProvider.notifier).createBooking(booking);

      if (mounted) {
        Navigator.pop(context); // close dialog
        context.go('/booking-success');
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';

class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends ConsumerState<ManagerDashboardScreen> {
  final List<Map<String, String>> _residents = [
    {'name': 'Rohan Sharma', 'room': 'Room 101B', 'phone': '9876543001', 'status': 'Rent Paid'},
    {'name': 'Aditya Patel', 'room': 'Room 102A', 'phone': '9876543002', 'status': 'Pending'},
    {'name': 'Sneha Rao', 'room': 'Room 104A', 'phone': '9876543003', 'status': 'Rent Paid'},
    {'name': 'Vikram Singh', 'room': 'Room 105C', 'phone': '9876543004', 'status': 'Rent Paid'},
    {'name': 'Kunal Sen', 'room': 'Room 108A', 'phone': '9876543005', 'status': 'Overdue'},
  ];

  final List<Map<String, String>> _complaints = [
    {'title': 'WiFi not working in Room 102', 'tenant': 'Aditya Patel', 'priority': 'High', 'status': 'Pending'},
    {'title': 'Water leakage in common bathroom', 'tenant': 'Sneha Rao', 'priority': 'Medium', 'status': 'In Progress'},
    {'title': 'AC remote missing', 'tenant': 'Kunal Sen', 'priority': 'Low', 'status': 'Pending'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: "Operations Hub",
        subtitle: "Manager dashboard & tasks",
        showBackButton: false,
        actionWidget: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Stats Banner ────────────────────────────
              StaggeredFadeIn(
                delay: const Duration(milliseconds: 180),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildOperationCard(
                        title: "Residents",
                        value: "38",
                        color: AppTheme.primary,
                        icon: Icons.people_alt_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildOperationCard(
                        title: "Active Complaints",
                        value: "03",
                        color: AppTheme.error,
                        icon: Icons.report_problem_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildOperationCard(
                        title: "Enquiries Today",
                        value: "09",
                        color: AppTheme.accentColor,
                        icon: Icons.mail_outline_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Active Resident Logs ────────────────────
              StaggeredFadeIn(
                delay: const Duration(milliseconds: 260),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.surfaceBorder),
                    boxShadow: AppTheme.softShadow(opacity: 0.03),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Resident Log',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Divider(color: AppTheme.dividerColor, height: 1),
                      const SizedBox(height: 8),
                      ...List.generate(_residents.length, (index) {
                        final resident = _residents[index];
                        return _buildResidentItem(resident);
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Complaints List ─────────────────────────
              StaggeredFadeIn(
                delay: const Duration(milliseconds: 340),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.surfaceBorder),
                    boxShadow: AppTheme.softShadow(opacity: 0.03),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complaints Registry',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Divider(color: AppTheme.dividerColor, height: 1),
                      const SizedBox(height: 8),
                      ...List.generate(_complaints.length, (index) {
                        final complaint = _complaints[index];
                        return _buildComplaintItem(complaint);
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperationCard({required String title, required String value, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: AppTheme.softShadow(opacity: 0.03),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildResidentItem(Map<String, String> resident) {
    Color statusColor;
    switch (resident['status']!.toLowerCase()) {
      case 'rent paid':
        statusColor = AppTheme.success;
        break;
      case 'pending':
        statusColor = AppTheme.warning;
        break;
      default:
        statusColor = AppTheme.error;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resident['name']!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    resident['room']!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              resident['status']!,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintItem(Map<String, String> complaint) {
    final bool isHigh = complaint['priority']!.toLowerCase() == 'high';
    final Color priorityColor = isHigh ? AppTheme.error : AppTheme.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.error_outline_rounded, size: 16, color: priorityColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint['title']!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      complaint['tenant']!,
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppTheme.textHint, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      'Priority: ${complaint['priority']}',
                      style: GoogleFonts.inter(fontSize: 11, color: priorityColor, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

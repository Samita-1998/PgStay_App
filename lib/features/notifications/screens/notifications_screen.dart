import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock notifications list
    final notifications = [
      {
        'title': 'Rent Reminder',
        'body': 'Your monthly rent for June is due in 3 days.',
        'time': '2 hours ago',
        'type': 'alert',
      },
      {
        'title': 'Booking Confirmed',
        'body': 'Your booking for Sunshine Co-Living has been confirmed!',
        'time': '1 day ago',
        'type': 'success',
      },
      {
        'title': 'Issue Resolved',
        'body': 'Maintenance issue "AC Not Working" has been marked as resolved.',
        'time': '3 days ago',
        'type': 'info',
      }
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24.0),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          
          IconData icon;
          Color iconColor;
          
          switch(notif['type']) {
            case 'alert':
              icon = Icons.warning_rounded;
              iconColor = AppTheme.warning;
              break;
            case 'success':
              icon = Icons.check_circle_rounded;
              iconColor = AppTheme.success;
              break;
            default:
              icon = Icons.info_rounded;
              iconColor = AppTheme.primary;
          }

          return StaggeredFadeIn(
            delay: Duration(milliseconds: 100 * index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceBorder),
                boxShadow: AppTheme.softShadow(opacity: 0.02),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif['title'] as String,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif['body'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notif['time'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textHint,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

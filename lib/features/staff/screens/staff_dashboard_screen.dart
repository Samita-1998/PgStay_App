import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/core/widgets/staggered_fade_in.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';

class StaffDashboardScreen extends ConsumerStatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  ConsumerState<StaffDashboardScreen> createState() =>
      _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends ConsumerState<StaffDashboardScreen> {
  final List<Map<String, dynamic>> _tasks = [
    {
      'title': 'Fix water leakage in Room 204 bath',
      'time': '9:30 AM',
      'completed': true,
    },
    {
      'title': 'Deliver AC remote to Kunal (108A)',
      'time': '11:00 AM',
      'completed': false,
    },
    {
      'title': 'General cleanup of common lounge area',
      'time': '2:00 PM',
      'completed': false,
    },
    {
      'title': 'Inspect laundry machine connection',
      'time': '4:30 PM',
      'completed': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final completedCount = _tasks.where((t) => t['completed'] == true).length;
    final totalCount = _tasks.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: "Task Workspace",
        subtitle: "Your assigned maintenance & schedules",
        showBackButton: false,
        pinnedSCurve: true,
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
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 110 + MediaQuery.of(context).padding.top + 32, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Completion Tracker ──────────────────────
              StaggeredFadeIn(
                delay: const Duration(milliseconds: 180),
                child: Container(
                  padding: const EdgeInsets.all(22.0),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
                    border: Border.all(color: AppTheme.surfaceBorder),
                    boxShadow: AppTheme.surfaceShadow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Task Progress",
                                style: AppTheme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$completedCount of $totalCount tasks completed",
                                style: AppTheme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSM,
                              ),
                            ),
                            child: Text(
                              '${((completedCount / totalCount) * 100).toInt()}%',
                              style: AppTheme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        child: LinearProgressIndicator(
                          value: completedCount / totalCount,
                          minHeight: 8,
                          backgroundColor: AppTheme.dividerColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Checklist Items ─────────────────────────
              StaggeredFadeIn(
                delay: const Duration(milliseconds: 260),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
                    border: Border.all(color: AppTheme.surfaceBorder),
                    boxShadow: AppTheme.softShadow(opacity: 0.03),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned Tasks Checklist',
                        style: AppTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Divider(color: AppTheme.dividerColor, height: 1),
                      const SizedBox(height: 8),
                      ...List.generate(_tasks.length, (index) {
                        final task = _tasks[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _tasks[index]['completed'] =
                                    !_tasks[index]['completed'];
                              });
                            },
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMD,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: task['completed']
                                    ? AppTheme.backgroundLight
                                    : AppTheme.surfaceWhite,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMD,
                                ),
                                border: Border.all(
                                  color: task['completed']
                                      ? Colors.transparent
                                      : AppTheme.surfaceBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: task['completed']
                                          ? AppTheme.accentColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusXS,
                                      ),
                                      border: Border.all(
                                        color: task['completed']
                                            ? Colors.transparent
                                            : AppTheme.textHint,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: task['completed']
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task['title']!,
                                          style: AppTheme.textTheme.labelLarge
                                              ?.copyWith(
                                                color: task['completed']
                                                    ? AppTheme.textSecondary
                                                    : AppTheme.textPrimary,
                                                decoration: task['completed']
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Schedule: ${task['time']}',
                                          style: AppTheme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
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
}

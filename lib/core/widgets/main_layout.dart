import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/auth/providers/auth_provider.dart';
import 'package:pgstay/core/providers/theme_provider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── Bottom nav items (no rent here) ─────────────────────────────────────────
  List<Map<String, dynamic>> _getNavItems(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return [
          {
            'path': '/home',
            'icon': Icons.dashboard_outlined,
            'activeIcon': Icons.dashboard,
            'label': 'Dashboard',
          },
          {
            'path': '/my-pgs',
            'icon': Icons.apartment_outlined,
            'activeIcon': Icons.apartment_rounded,
            'label': "My PG's",
          },
          {
            'path': '/vacancies',
            'icon': Icons.post_add_outlined,
            'activeIcon': Icons.post_add_rounded,
            'label': 'Vacancies',
          },
          {
            'path': '/profile',
            'icon': Icons.person_outline,
            'activeIcon': Icons.person,
            'label': 'Profile',
          },
        ];
      case 'manager':
        return [
          {
            'path': '/manager/dashboard',
            'icon': Icons.assessment_outlined,
            'activeIcon': Icons.assessment,
            'label': 'Operations',
          },
          {
            'path': '/profile',
            'icon': Icons.person_outline,
            'activeIcon': Icons.person,
            'label': 'Profile',
          },
        ];
      case 'employee':
      case 'staff':
        return [
          {
            'path': '/staff/dashboard',
            'icon': Icons.assignment_outlined,
            'activeIcon': Icons.assignment,
            'label': 'Tasks',
          },
          {
            'path': '/profile',
            'icon': Icons.person_outline,
            'activeIcon': Icons.person,
            'label': 'Profile',
          },
        ];
      default: // Tenant / 'user'
        return [
          {
            'path': '/home',
            'icon': Icons.explore_outlined,
            'activeIcon': Icons.explore,
            'label': 'Discover',
          },
          {
            'path': '/enquiries',
            'icon': Icons.bookmark_outline,
            'activeIcon': Icons.bookmark,
            'label': 'Enquiries',
          },
          {
            'path': '/profile',
            'icon': Icons.person_outline,
            'activeIcon': Icons.person,
            'label': 'Profile',
          },
        ];
    }
  }

  // ── Drawer items per role ───────────────────────────────────────────────────
  List<Map<String, dynamic>> _getDrawerItems(String role) {
    final common = <Map<String, dynamic>>[
      {
        'path': '/notifications',
        'icon': Icons.notifications_outlined,
        'label': 'Notifications',
      },
      {
        'path': '/complaints',
        'icon': Icons.report_problem_outlined,
        'label': 'Complaints',
      },
    ];

    switch (role.toLowerCase()) {
      case 'owner':
        return [
          {
            'path': '/owner-rent',
            'icon': Icons.receipt_long_outlined,
            'label': 'Rent Management',
          },
          {
            'path': '/owner-enquiries',
            'icon': Icons.question_answer_outlined,
            'label': 'Enquiries',
          },
          {
            'path': '/staff-tracker',
            'icon': Icons.people_outline,
            'label': 'Staff & Expense Tracker',
          },
          ...common,
        ];
      case 'manager':
        return [
          {
            'path': '/owner-rent',
            'icon': Icons.receipt_long_outlined,
            'label': 'Rent Management',
          },
          ...common,
        ];
      default: // Tenant / user / staff
        return [
          {
            'path': '/browse-posts',
            'icon': Icons.travel_explore_rounded,
            'label': "Browse PG's",
          },
          {
            'path': '/rent',
            'icon': Icons.receipt_long_outlined,
            'label': 'Rent Tracker',
          },
          ...common,
        ];
    }
  }

  int _calculateSelectedIndex(
    BuildContext context,
    List<Map<String, dynamic>> navItems,
  ) {
    final String location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < navItems.length; i++) {
      final String path = navItems[i]['path'];
      if (location.startsWith(path)) {
        return i;
      }
    }
    return -1;
  }

  void _onItemTapped(
    int index,
    BuildContext context,
    List<Map<String, dynamic>> navItems,
  ) {
    context.go(navItems[index]['path']);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;
    final String role = user?.role ?? 'user';
    final navItems = _getNavItems(role);
    final selectedIndex = _calculateSelectedIndex(context, navItems);
    final drawerItems = _getDrawerItems(role);
    final currentPath = GoRouterState.of(context).uri.path;
    final showBottomNav = selectedIndex != -1;

    return Scaffold(
      key: _scaffoldKey,
      body: widget.child,
      extendBody: true,
      // ── Drawer ────────────────────────────────────────────────────────────
      endDrawer: _buildDrawer(user, role, drawerItems, currentPath),
      // ── Bottom Nav ────────────────────────────────────────────────────────
      bottomNavigationBar: showBottomNav ? CurvedNavigationBar(
        index: selectedIndex,
        backgroundColor: Colors.transparent,
        color: AppTheme.primary,
        buttonBackgroundColor: AppTheme.primary,
        animationDuration: const Duration(milliseconds: 300),
        items: navItems.asMap().entries.map((entry) {
          final int idx = entry.key;
          final item = entry.value;
          final isSelected = selectedIndex == idx;
          return Icon(
            isSelected ? item['activeIcon'] : item['icon'],
            color: Colors.white,
            size: 25,
          );
        }).toList(),
        onTap: (index) {
          if (index != selectedIndex) {
            _onItemTapped(index, context, navItems);
          }
        },
      ) : null,
    );
  }

  // ── Drawer widget ─────────────────────────────────────────────────────────
  Widget _buildDrawer(
    dynamic user,
    String role,
    List<Map<String, dynamic>> items,
    String currentPath,
  ) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.78,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            bottomLeft: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                left: 24,
                right: 24,
                bottom: 24,
              ),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'User',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Menu items ────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: Text(
                      'MENU',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textHint,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  ...items.map((item) {
                    final isActive = currentPath == item['path'];
                    return _buildDrawerItem(
                      icon: item['icon'],
                      label: item['label'],
                      isActive: isActive,
                      onTap: () {
                        Navigator.of(context).pop(); // close drawer
                        if (item['path'] == '/logout') {
                          _showLogoutDialog();
                        } else {
                          context.go(item['path']);
                        }
                      },
                    );
                  }),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Divider(),
                  ),
                  _buildDrawerItem(
                    icon: ref.watch(themeProvider) == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    label: ref.watch(themeProvider) == ThemeMode.dark
                        ? 'Light Mode'
                        : 'Dark Mode',
                    isActive: false,
                    onTap: () {
                      final currentTheme = ref.read(themeProvider);
                      ref
                          .read(themeProvider.notifier)
                          .state = currentTheme == ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark;
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildDrawerItem(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    isActive: false,
                    isDestructive: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      _showLogoutDialog();
                    },
                  ),
                  // Add bottom padding so it can scroll past the bottom nav bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final Color itemColor = isDestructive
        ? AppTheme.error
        : isActive
        ? AppTheme.primary
        : AppTheme.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primary.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : isDestructive
                        ? AppTheme.error.withValues(alpha: 0.06)
                        : AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 20, color: itemColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: isDestructive
                          ? AppTheme.error
                          : isActive
                          ? AppTheme.primary
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (!isActive && !isDestructive)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppTheme.textHint.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textHint),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            child: Text(
              'Logout',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav item ───────────────────────────────────────────────────────
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required BuildContext context,
    required List<Map<String, dynamic>> navItems,
  }) {
    return GestureDetector(
      onTap: () => _onItemTapped(index, context, navItems),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                size: isSelected ? 24 : 22,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: isSelected ? 11 : 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontFamily: 'PlusJakartaSans',
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

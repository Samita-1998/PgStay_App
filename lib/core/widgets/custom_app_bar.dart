import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:pgstay/core/theme/app_theme.dart';

Widget _buildFlexibleContent({
  required BuildContext context,
  required String title,
  String? subtitle,
  required bool showBackButton,
  bool showLeading = true,
  bool centerTitle = false,
  bool pinnedSCurve = false,
  bool isCompact = false,
  VoidCallback? onLeadingPressed,
  Widget? actionWidget,
}) {
  bool isDashboard = !showBackButton && pinnedSCurve && !isCompact;
  bool isCompactNav = !showBackButton && pinnedSCurve && isCompact;
  bool isBottomNav = !showBackButton && !pinnedSCurve;
  bool isStandard = showBackButton;

  bool effectiveCenterTitle = isBottomNav || isStandard || isCompactNav
      ? true
      : centerTitle;

  Widget content = Container(
    decoration: pinnedSCurve
        ? null
        : BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF03045E), // Deep primary
                Color(0xFF3A3F96), // Lighter secondary
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF03045E).withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Content
            Align(
              alignment: effectiveCenterTitle
                  ? Alignment.center
                  : Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  left: !effectiveCenterTitle && showLeading ? 56.0 : 0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: effectiveCenterTitle
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    if (subtitle != null) ...[
                      Text(
                        subtitle,
                        textAlign: effectiveCenterTitle
                            ? TextAlign.center
                            : TextAlign.start,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      title,
                      textAlign: effectiveCenterTitle
                          ? TextAlign.center
                          : TextAlign.start,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Left Action
            if (showLeading)
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap:
                      onLeadingPressed ??
                      () {
                        if (showBackButton) {
                          context.pop();
                        } else {
                          Scaffold.of(context).openDrawer();
                        }
                      },
                  child: isDashboard
                      ? Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.menu_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 4,
                          ),
                          child: Icon(
                            isStandard
                                ? Icons.arrow_back_ios_new_rounded
                                : Icons.menu_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                ),
              ),
            // Right Action
            if (actionWidget != null)
              Align(alignment: Alignment.centerRight, child: actionWidget),
          ],
        ),
      ),
    ),
  );

  return content;
}

class AppBarBackgroundPainter extends CustomPainter {
  final bool hasSCurve;
  final bool isCompact;

  AppBarBackgroundPainter({this.hasSCurve = true, this.isCompact = false});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF03045E), Color(0xFF3A3F96)],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    final path = Path();

    if (!hasSCurve) {
      path.addRect(rect);
      canvas.drawPath(path, paint);
      return;
    }

    double bottomOffset = isCompact ? 30 : 45;
    double radius = isCompact ? 45 : 60;
    double topHeight = size.height - bottomOffset;

    path.lineTo(0, topHeight - radius);

    path.arcToPoint(
      Offset(radius, topHeight),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    path.lineTo(size.width - radius, topHeight);

    path.arcToPoint(
      Offset(size.width, size.height),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final bool showLeading;
  final bool centerTitle;
  final bool pinnedSCurve;
  final bool isCompact;
  final VoidCallback? onLeadingPressed;
  final Widget? actionWidget;

  const CustomSliverAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.showLeading = true,
    this.centerTitle = false,
    this.pinnedSCurve = false,
    this.isCompact = false,
    this.onLeadingPressed,
    this.actionWidget,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.backgroundLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      pinned: true,
      toolbarHeight: pinnedSCurve ? (isCompact ? 115 : 135) : 70,
      flexibleSpace: Builder(
        builder: (innerContext) => _buildFlexibleContent(
          context: innerContext,
          title: title,
          subtitle: subtitle,
          showBackButton: showBackButton,
          showLeading: showLeading,
          centerTitle: centerTitle,
          pinnedSCurve: pinnedSCurve,
          isCompact: isCompact,
          onLeadingPressed: onLeadingPressed,
          actionWidget: actionWidget,
        ),
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final bool showLeading;
  final bool centerTitle;
  final bool pinnedSCurve;
  final bool isCompact;
  final Color backgroundColor;
  final VoidCallback? onLeadingPressed;
  final Widget? actionWidget;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.showLeading = true,
    this.centerTitle = false,
    this.pinnedSCurve = false,
    this.isCompact = false,
    this.backgroundColor = AppTheme.backgroundLight,
    this.onLeadingPressed,
    this.actionWidget,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: pinnedSCurve ? (isCompact ? 120 : 150) : 70,
      flexibleSpace: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: AppBarBackgroundPainter(
                hasSCurve: pinnedSCurve,
                isCompact: isCompact,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: pinnedSCurve ? (isCompact ? 40 : 60) : 0,
            child: Builder(
              builder: (innerContext) => _buildFlexibleContent(
                context: innerContext,
                title: title,
                subtitle: subtitle,
                showBackButton: showBackButton,
                showLeading: showLeading,
                centerTitle: centerTitle,
                pinnedSCurve: pinnedSCurve,
                isCompact: isCompact,
                onLeadingPressed: onLeadingPressed,
                actionWidget: actionWidget,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(pinnedSCurve ? (isCompact ? 120 : 150) : 70);
}

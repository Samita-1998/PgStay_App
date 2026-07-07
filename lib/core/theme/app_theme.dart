import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Brand Core ──────────────────────────────────────────────────────────
  static const Color primary = Color.fromRGBO(3, 4, 94, 1.0);
  static const Color primaryDark = Color.fromRGBO(2, 3, 70, 1.0);

  static const Color primaryColor = primary;
  static const Color secondaryColor = Color.fromRGBO(58, 63, 150, 1.0);
  static const Color accentColor = Color.fromRGBO(96, 102, 208, 1.0);

  // ─── Surface Layers ──────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundColor = backgroundLight;

  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceColor = surfaceWhite;

  static const Color surfaceBorder = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFF3F4F6);

  // ─── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color.fromRGBO(3, 4, 94, 1.0);
  static const Color textSecondary = Color.fromRGBO(58, 63, 150, 1.0);
  static const Color textHint = Color(0xFF9CA3AF);

  // ─── Status ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color.fromRGBO(96, 102, 208, 1.0);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color.fromRGBO(3, 4, 94, 1.0), Color.fromRGBO(58, 63, 150, 1.0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [
      Color.fromRGBO(58, 63, 150, 1.0),
      Color.fromRGBO(96, 102, 208, 1.0),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color.fromRGBO(3, 4, 94, 1.0), Color.fromRGBO(2, 3, 70, 1.0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ); // ─── Premium Shadows ─────────────────────────────────────────────────────
  static List<BoxShadow> softShadow({
    double opacity = 0.05,
    double blur = 24,
    Offset offset = const Offset(0, 8),
  }) => [
    BoxShadow(
      color: primary.withOpacity(opacity),
      blurRadius: blur,
      spreadRadius: 0,
      offset: offset,
    ),
  ];

  static List<BoxShadow> primaryGlow({
    double opacity = 0.15,
    double blur = 16,
    Offset offset = const Offset(0, 4),
  }) => [
    BoxShadow(
      color: primary.withOpacity(opacity),
      blurRadius: blur,
      spreadRadius: 0,
      offset: offset,
    ),
  ];

  static List<BoxShadow> accentGlow({
    double opacity = 0.15,
    double blur = 12,
    Offset offset = const Offset(0, 4),
  }) => [
    BoxShadow(
      color: accentColor.withOpacity(opacity),
      blurRadius: blur,
      spreadRadius: 0,
      offset: offset,
    ),
  ];

  static List<BoxShadow> surfaceShadow = [
    BoxShadow(
      color: const Color(0xFF0A1931).withOpacity(0.04),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.grey.withOpacity(0.08),
      blurRadius: 12,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.grey.withOpacity(0.12),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  // ─── Spacing Constants ───────────────────────────────────────────────────
  static const double spacingXXS = 4.0;
  static const double spacingXS = 8.0;
  static const double spacingSM = 12.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ─── Border Radius Constants ─────────────────────────────────────────────
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusCircular = 100.0;

  // ─── Text Styles ─────────────────────────────────────────────────────────
  static TextTheme get textTheme {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.8,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.3,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textHint,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.2,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: textHint,
      ),
    );
  }

  // ─── Helper Methods ──────────────────────────────────────────────────────
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'success':
      case 'completed':
      case 'confirmed':
      case 'delivered':
        return success;
      case 'pending':
      case 'waiting':
        return warning;
      case 'inactive':
      case 'cancelled':
      case 'failed':
      case 'error':
        return error;
      case 'processing':
      case 'inprogress':
        return info;
      default:
        return textSecondary;
    }
  }

  static Color getStatusBackgroundColor(String status) {
    final color = getStatusColor(status);
    return color.withOpacity(0.1);
  }

  static EdgeInsets get screenPadding => const EdgeInsets.all(spacingMD);
  static EdgeInsets get screenPaddingHorizontal =>
      const EdgeInsets.symmetric(horizontal: spacingMD);
  static EdgeInsets get screenPaddingVertical =>
      const EdgeInsets.symmetric(vertical: spacingMD);

  // ─── Theme Data ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accentColor,
        surface: surfaceWhite,
        background: backgroundLight,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: textHint,
        outlineVariant: surfaceBorder,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          fontFamily: 'Inter',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLG),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: surfaceBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLG),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        hintStyle: GoogleFonts.inter(
          color: textHint,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: surfaceBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: surfaceBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: error, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
        margin: const EdgeInsets.only(bottom: spacingMD),
      ),
      dividerTheme: const DividerThemeData(color: dividerColor, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primary,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXXL)),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primary;
          }
          return null;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXS),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primary;
          }
          return null;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primary;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primary.withOpacity(0.5);
          }
          return null;
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceBorderDark = Color(0xFF334155);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accentColor,
        surface: surfaceDark,
        background: backgroundDark,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onSurfaceVariant: Color(0xFF94A3B8),
        outline: Color(0xFF64748B),
        outlineVariant: surfaceBorderDark,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          fontFamily: 'Inter',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLG),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: surfaceBorderDark, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLG),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.inter(
          color: const Color(0xFF94A3B8),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: const Color(0xFF94A3B8),
        suffixIconColor: const Color(0xFF94A3B8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: surfaceBorderDark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: surfaceBorderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: error, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
          side: const BorderSide(color: surfaceBorderDark, width: 1),
        ),
        margin: const EdgeInsets.only(bottom: spacingMD),
      ),
      dividerTheme: const DividerThemeData(color: surfaceBorderDark, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primary,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: Colors.white),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: const Color(0xFF94A3B8)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXXL)),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primary;
          }
          return null;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXS),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primary;
          }
          return null;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primary;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primary.withOpacity(0.5);
          }
          return null;
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// Extension for easy theme access in widgets
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  AppTheme get appTheme => AppTheme();
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  // Spacing shortcuts
  double get spacingXXS => AppTheme.spacingXXS;
  double get spacingXS => AppTheme.spacingXS;
  double get spacingSM => AppTheme.spacingSM;
  double get spacingMD => AppTheme.spacingMD;
  double get spacingLG => AppTheme.spacingLG;
  double get spacingXL => AppTheme.spacingXL;
  double get spacingXXL => AppTheme.spacingXXL;

  // Radius shortcuts
  double get radiusXS => AppTheme.radiusXS;
  double get radiusSM => AppTheme.radiusSM;
  double get radiusMD => AppTheme.radiusMD;
  double get radiusLG => AppTheme.radiusLG;
  double get radiusXL => AppTheme.radiusXL;
  double get radiusXXL => AppTheme.radiusXXL;

  // Color shortcuts
  Color get primaryColor => colorScheme.primary;
  Color get accentColor => colorScheme.secondary;
  Color get successColor => AppTheme.success;
  Color get errorColor => colorScheme.error;
  Color get warningColor => AppTheme.warning;
  Color get infoColor => AppTheme.info;
  Color get textPrimary => colorScheme.onSurface;
  Color get textSecondary => colorScheme.onSurfaceVariant;
  Color get textHint => colorScheme.outline;
  Color get backgroundLight => theme.scaffoldBackgroundColor;
  Color get surfaceWhite => colorScheme.surface;
  Color get surfaceBorder => colorScheme.outlineVariant;

  // Helper methods
  EdgeInsets get screenPadding => AppTheme.screenPadding;
  EdgeInsets get screenPaddingHorizontal => AppTheme.screenPaddingHorizontal;
  EdgeInsets get screenPaddingVertical => AppTheme.screenPaddingVertical;

  Color getStatusColor(String status) => AppTheme.getStatusColor(status);
  Color getStatusBackgroundColor(String status) =>
      AppTheme.getStatusBackgroundColor(status);

  List<BoxShadow> softShadow({double opacity = 0.05, double blur = 24}) =>
      AppTheme.softShadow(opacity: opacity, blur: blur);
  List<BoxShadow> primaryGlow({double opacity = 0.15, double blur = 16}) =>
      AppTheme.primaryGlow(opacity: opacity, blur: blur);
  List<BoxShadow> accentGlow({double opacity = 0.15, double blur = 12}) =>
      AppTheme.accentGlow(opacity: opacity, blur: blur);
}

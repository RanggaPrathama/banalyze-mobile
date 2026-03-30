import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banalyze/core/constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── LIGHT THEME ──
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textPrimary,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: _textTheme(
        AppColors.textPrimary,
        AppColors.textSecondary,
        AppColors.textHint,
      ),
      appBarTheme: _appBarTheme(AppColors.background, AppColors.textPrimary),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: _elevatedButtonTheme(),
      navigationBarTheme: _navBarTheme(
        AppColors.white,
        AppColors.textPrimary,
        AppColors.navInactive,
        AppColors.navActive,
      ),
    );
  }

  // ── DARK THEME ──
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.darkBackground,
        secondary: AppColors.primaryDark,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
      ),
      textTheme: _textTheme(
        AppColors.darkTextPrimary,
        AppColors.darkTextSecondary,
        AppColors.darkTextHint,
      ),
      appBarTheme: _appBarTheme(
        AppColors.darkBackground,
        AppColors.darkTextPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: _elevatedButtonTheme(),
      navigationBarTheme: _navBarTheme(
        AppColors.darkSurface,
        AppColors.darkTextPrimary,
        AppColors.darkNavInactive,
        AppColors.darkNavActive,
      ),
    );
  }

  // ── Shared helpers ──

  static TextTheme _textTheme(Color primary, Color secondary, Color hint) {
    return GoogleFonts.poppinsTextTheme().copyWith(
      headlineLarge: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: GoogleFonts.poppins(fontSize: 16, color: primary),
      bodyMedium: GoogleFonts.poppins(fontSize: 14, color: secondary),
      bodySmall: GoogleFonts.poppins(fontSize: 12, color: hint),
    );
  }

  static AppBarTheme _appBarTheme(Color bg, Color fg) {
    return AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
      iconTheme: IconThemeData(color: fg),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static NavigationBarThemeData _navBarTheme(
    Color bg,
    Color activeLabelColor,
    Color inactiveColor,
    Color activeIconColor,
  ) {
    return NavigationBarThemeData(
      backgroundColor: bg,
      elevation: 0,
      height: 64,
      indicatorColor: AppColors.primary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: activeLabelColor,
          );
        }
        return GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: inactiveColor,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: activeIconColor, size: 24);
        }
        return IconThemeData(color: inactiveColor, size: 24);
      }),
    );
  }
}

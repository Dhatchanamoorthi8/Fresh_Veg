import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_typography.dart';

/// Vegora Premium Design System Theme
///
/// Implements Poppins for modern, friendly English grocery shopping
/// and Noto Sans Tamil for native, high-fidelity Tamil script rendering.
class AppTheme {
  AppTheme._();

  static const String englishFontFamily = AppTypography.englishFontFamily;
  static const String tamilFontFamily = AppTypography.tamilFontFamily;

  static List<String> fallbackFonts({bool isTamil = false}) =>
      AppTypography.fallbackFonts(isTamil: isTamil);

  static ThemeData get lightTheme => getTheme();

  static ThemeData getTheme({Locale? locale}) {
    final isTamil = locale?.languageCode == 'ta';
    final activeFontFamily = AppTypography.fontFamily(isTamil: isTamil);
    final activeFallbacks = AppTypography.fallbackFonts(isTamil: isTamil);
    final lineHeight = AppTypography.lineHeight(isTamil: isTamil);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.primaryDark,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurface: AppColors.textPrimary,
      outline: AppColors.border,
      outlineVariant: AppColors.borderDark,
      error: AppColors.error,
      onError: Colors.white,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: activeFontFamily,
      fontFamilyFallback: activeFallbacks,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: isTamil ? 0 : -0.3,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
          height: lineHeight,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
      ),
      textTheme: TextTheme(
        // Display Headings (28-32 px, Bold 700 / SemiBold 600)
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: isTamil ? 0 : -0.6,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
          height: lineHeight,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: isTamil ? 0 : -0.4,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
          height: lineHeight,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: isTamil ? 0 : -0.3,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
          height: lineHeight,
        ),

        // Screen & Section Headings (18-28 px, SemiBold 600)
        headlineLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          letterSpacing: isTamil ? 0 : -0.4,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
          height: lineHeight,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: isTamil ? 0 : -0.2,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
          height: lineHeight,
        ),
        headlineSmall: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          letterSpacing: isTamil ? 0 : -0.1,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
          height: lineHeight,
        ),

        // Section & Card Titles (15-20 px)
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          letterSpacing: isTamil ? 0 : -0.2,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
          height: lineHeight,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: isTamil ? 0 : -0.1,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
          height: lineHeight,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
          height: lineHeight,
        ),

        // Body Text (14-16 px, Regular 400)
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
          height: lineHeight + 0.05,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
          height: lineHeight + 0.05,
        ),
        bodySmall: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
          height: lineHeight,
        ),

        // Buttons & Labels (11-16 px, SemiBold 600 / Medium 500)
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: isTamil ? 0 : 0.1,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
          height: lineHeight,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          color: AppColors.textSecondary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
          height: lineHeight,
        ),
        labelSmall: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          letterSpacing: isTamil ? 0 : 0.1,
          color: AppColors.textMuted,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
          height: lineHeight,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: activeFontFamily,
            fontFamilyFallback: activeFallbacks,
            height: lineHeight,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: activeFontFamily,
            fontFamilyFallback: activeFallbacks,
            height: lineHeight,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: activeFontFamily,
            fontFamilyFallback: activeFallbacks,
            height: lineHeight,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
        ),
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primaryContainer,
        side: const BorderSide(color: AppColors.border, width: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: activeFontFamily,
          fontFamilyFallback: activeFallbacks,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1.2),
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      ),
    );
  }
}

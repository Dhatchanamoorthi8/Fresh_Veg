import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Vegora Premium Design System Theme
class AppTheme {
  AppTheme._();

  static const String tamilFontFamily = 'NotoSansTamil';
  static const List<String> fallbackFonts = [
    tamilFontFamily,
    'Inter',
    'Roboto',
    'sans-serif',
  ];

  static ThemeData get lightTheme => getTheme();

  static ThemeData getTheme({Locale? locale}) {
    final isTamil = locale?.languageCode == 'ta';
    final activeFontFamily = isTamil ? tamilFontFamily : null;
    final lineHeight = isTamil ? 1.38 : 1.25;

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
      fontFamilyFallback: fallbackFonts,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
          height: lineHeight,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
          height: lineHeight,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
          height: lineHeight,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
          height: lineHeight,
        ),
        headlineLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
          height: lineHeight,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
          height: lineHeight,
        ),
        headlineSmall: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
          height: lineHeight,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
          height: lineHeight,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
          height: lineHeight,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
          height: lineHeight,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
          height: lineHeight + 0.1,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
          height: lineHeight + 0.1,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
          height: lineHeight,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: AppColors.textPrimary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
          height: lineHeight,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: AppColors.textSecondary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
          height: lineHeight,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: AppColors.textMuted,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
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
            fontFamilyFallback: fallbackFonts,
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: activeFontFamily,
            fontFamilyFallback: fallbackFonts,
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
            fontFamilyFallback: fallbackFonts,
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
          fontWeight: FontWeight.normal,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primaryContainer,
        side: const BorderSide(color: AppColors.border, width: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
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
          fontFamilyFallback: fallbackFonts,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

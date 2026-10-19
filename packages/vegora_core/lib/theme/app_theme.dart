import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String tamilFontFamily = 'NotoSansTamil';
  static const List<String> fallbackFonts = [tamilFontFamily, 'Roboto', 'sans-serif'];

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
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurface: AppColors.textPrimary,
      outline: AppColors.border,
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
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          fontFamily: activeFontFamily,
          fontFamilyFallback: fallbackFonts,
          height: lineHeight,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: activeFontFamily, fontFamilyFallback: fallbackFonts, height: lineHeight),
        displayMedium: TextStyle(fontFamily: activeFontFamily, fontFamilyFallback: fallbackFonts, height: lineHeight),
        displaySmall: TextStyle(fontFamily: activeFontFamily, fontFamilyFallback: fallbackFonts, height: lineHeight),
        headlineLarge: TextStyle(fontFamily: activeFontFamily, fontFamilyFallback: fallbackFonts, height: lineHeight),
        headlineMedium: TextStyle(fontFamily: activeFontFamily, fontFamilyFallback: fallbackFonts, height: lineHeight),
        headlineSmall: TextStyle(fontFamily: activeFontFamily, fontFamilyFallback: fallbackFonts, height: lineHeight),
        titleLarge: TextStyle(fontFamily: activeFontFamily, fontFamilyFallback: fallbackFonts, height: lineHeight, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontFamily: activeFontFamily, fontFamilyFallback: fallbackFonts, height: lineHeight, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontFamily: activeFontFamily, fontFamilyFallback: fallbackFonts, height: lineHeight, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontFamily: activeFontFamily, fontFamilyFallback: fallbackFonts, height: lineHeight),
        bodyMedium: TextStyle(fontFamily: activeFontFamily, fontFamilyFallback: fallbackFonts, height: lineHeight),
        bodySmall: TextStyle(fontFamily: activeFontFamily, fontFamilyFallback: fallbackFonts, height: lineHeight),
        labelLarge: TextStyle(fontFamily: activeFontFamily, fontFamilyFallback: fallbackFonts, height: lineHeight, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontFamily: activeFontFamily, fontFamilyFallback: fallbackFonts, height: lineHeight),
        labelSmall: TextStyle(fontFamily: activeFontFamily, fontFamilyFallback: fallbackFonts, height: lineHeight),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
          side: const BorderSide(color: AppColors.primary, width: 1.5),
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
        fillColor: AppColors.surface,
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
          borderSide: const BorderSide(color: AppColors.statusCancelled),
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
        side: BorderSide.none,
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
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
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

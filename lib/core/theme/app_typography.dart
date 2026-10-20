import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Vegora Premium Typography System
///
/// Implements Poppins for modern, friendly English grocery shopping
/// and Noto Sans Tamil for native, high-fidelity Tamil script rendering.
class AppTypography {
  AppTypography._();

  static const String englishFontFamily = 'Poppins';
  static const String tamilFontFamily = 'NotoSansTamil';

  /// Resolves the primary font family for the specified language
  static String fontFamily({bool isTamil = false}) =>
      isTamil ? tamilFontFamily : englishFontFamily;

  /// Resolves font fallback list for mixed-script rendering without missing glyphs
  static List<String> fallbackFonts({bool isTamil = false}) => isTamil
      ? const [englishFontFamily, 'Roboto', 'sans-serif']
      : const [tamilFontFamily, 'Roboto', 'sans-serif'];

  /// Calibrated line height for script metrics (Tamil requires higher line height)
  static double lineHeight({bool isTamil = false}) => isTamil ? 1.40 : 1.25;

  // ---------------------------------------------------------------------------
  // Premium Typography Scale
  // ---------------------------------------------------------------------------

  /// Splash screen brand: 30-34px, Bold 700
  static TextStyle splashBrand({
    Color color = AppColors.textPrimary,
    bool isTamil = false,
    double? fontSize,
    FontWeight? fontWeight,
  }) => TextStyle(
    fontFamily: fontFamily(isTamil: isTamil),
    fontFamilyFallback: fallbackFonts(isTamil: isTamil),
    fontSize: fontSize ?? 32,
    fontWeight: fontWeight ?? FontWeight.w700,
    letterSpacing: isTamil ? 0 : -0.6,
    height: lineHeight(isTamil: isTamil),
    color: color,
  );

  /// Main screen heading: 24-28px, SemiBold 600
  static TextStyle screenHeading({
    Color color = AppColors.textPrimary,
    bool isTamil = false,
    double? fontSize,
    FontWeight? fontWeight,
  }) => TextStyle(
    fontFamily: fontFamily(isTamil: isTamil),
    fontFamilyFallback: fallbackFonts(isTamil: isTamil),
    fontSize: fontSize ?? 24,
    fontWeight: fontWeight ?? FontWeight.w600,
    letterSpacing: isTamil ? 0 : -0.4,
    height: lineHeight(isTamil: isTamil),
    color: color,
  );

  /// Section heading: 18-22px, SemiBold 600
  static TextStyle sectionHeading({
    Color color = AppColors.textPrimary,
    bool isTamil = false,
    double? fontSize,
    FontWeight? fontWeight,
  }) => TextStyle(
    fontFamily: fontFamily(isTamil: isTamil),
    fontFamilyFallback: fallbackFonts(isTamil: isTamil),
    fontSize: fontSize ?? 19,
    fontWeight: fontWeight ?? FontWeight.w600,
    letterSpacing: isTamil ? 0 : -0.2,
    height: lineHeight(isTamil: isTamil),
    color: color,
  );

  /// Product name: 14-16px, Medium 500
  static TextStyle productName({
    Color color = AppColors.textPrimary,
    bool isTamil = false,
    double? fontSize,
    FontWeight? fontWeight,
  }) => TextStyle(
    fontFamily: fontFamily(isTamil: isTamil),
    fontFamilyFallback: fallbackFonts(isTamil: isTamil),
    fontSize: fontSize ?? 15,
    fontWeight: fontWeight ?? FontWeight.w500,
    letterSpacing: isTamil ? 0 : -0.1,
    height: lineHeight(isTamil: isTamil),
    color: color,
  );

  /// Product price: 17-20px, SemiBold 600 (tabular numerals)
  static TextStyle productPrice({
    Color color = AppColors.textPrimary,
    bool isTamil = false,
    double? fontSize,
    FontWeight? fontWeight,
  }) => TextStyle(
    fontFamily: englishFontFamily, // Always use Poppins numerals for prices
    fontFamilyFallback: fallbackFonts(isTamil: isTamil),
    fontSize: fontSize ?? 18,
    fontWeight: fontWeight ?? FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.2,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color,
  );

  /// Promotional price: 16-18px, Bold 700
  static TextStyle promoPrice({
    Color color = AppColors.primary,
    bool isTamil = false,
    double? fontSize,
    FontWeight? fontWeight,
  }) => TextStyle(
    fontFamily: englishFontFamily,
    fontFamilyFallback: fallbackFonts(isTamil: isTamil),
    fontSize: fontSize ?? 17,
    fontWeight: fontWeight ?? FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.2,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: color,
  );

  /// Strike-through original price
  static TextStyle originalPrice({
    Color color = AppColors.textMuted,
    bool isTamil = false,
    double? fontSize,
    FontWeight? fontWeight,
  }) => TextStyle(
    fontFamily: englishFontFamily,
    fontFamilyFallback: fallbackFonts(isTamil: isTamil),
    fontSize: fontSize ?? 13,
    fontWeight: fontWeight ?? FontWeight.w400,
    decoration: TextDecoration.lineThrough,
    color: color,
  );

  /// Body text: 14-16px, Regular 400
  static TextStyle body({
    Color color = AppColors.textPrimary,
    bool isTamil = false,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
  }) => TextStyle(
    fontFamily: fontFamily(isTamil: isTamil),
    fontFamilyFallback: fallbackFonts(isTamil: isTamil),
    fontSize: fontSize ?? 14,
    fontWeight: fontWeight ?? FontWeight.w400,
    letterSpacing: isTamil ? 0 : -0.1,
    height: height ?? (lineHeight(isTamil: isTamil) + 0.05),
    color: color,
  );

  /// Button text: 14-16px, SemiBold 600
  static TextStyle button({
    Color color = Colors.white,
    bool isTamil = false,
    double? fontSize,
    FontWeight? fontWeight,
  }) => TextStyle(
    fontFamily: fontFamily(isTamil: isTamil),
    fontFamilyFallback: fallbackFonts(isTamil: isTamil),
    fontSize: fontSize ?? 15,
    fontWeight: fontWeight ?? FontWeight.w600,
    letterSpacing: isTamil ? 0 : 0.1,
    height: lineHeight(isTamil: isTamil),
    color: color,
  );

  /// Input field text: 14-16px, Regular 400
  static TextStyle input({
    Color color = AppColors.textPrimary,
    bool isTamil = false,
    double? fontSize,
    FontWeight? fontWeight,
  }) => TextStyle(
    fontFamily: fontFamily(isTamil: isTamil),
    fontFamilyFallback: fallbackFonts(isTamil: isTamil),
    fontSize: fontSize ?? 15,
    fontWeight: fontWeight ?? FontWeight.w400,
    letterSpacing: 0,
    height: lineHeight(isTamil: isTamil),
    color: color,
  );

  /// Form label: 12-14px, Medium 500
  static TextStyle formLabel({
    Color color = AppColors.textPrimary,
    bool isTamil = false,
    double? fontSize,
    FontWeight? fontWeight,
  }) => TextStyle(
    fontFamily: fontFamily(isTamil: isTamil),
    fontFamilyFallback: fallbackFonts(isTamil: isTamil),
    fontSize: fontSize ?? 13,
    fontWeight: fontWeight ?? FontWeight.w500,
    letterSpacing: 0,
    height: lineHeight(isTamil: isTamil),
    color: color,
  );

  /// Supporting text: 12-13px, Regular 400
  static TextStyle supporting({
    Color color = AppColors.textSecondary,
    bool isTamil = false,
    double? fontSize,
    FontWeight? fontWeight,
  }) => TextStyle(
    fontFamily: fontFamily(isTamil: isTamil),
    fontFamilyFallback: fallbackFonts(isTamil: isTamil),
    fontSize: fontSize ?? 12.5,
    fontWeight: fontWeight ?? FontWeight.w400,
    letterSpacing: 0,
    height: lineHeight(isTamil: isTamil),
    color: color,
  );

  /// Navigation label: 11-13px, Medium 500
  static TextStyle navLabel({
    Color color = AppColors.textSecondary,
    bool isTamil = false,
    double? fontSize,
    FontWeight? fontWeight,
  }) => TextStyle(
    fontFamily: fontFamily(isTamil: isTamil),
    fontFamilyFallback: fallbackFonts(isTamil: isTamil),
    fontSize: fontSize ?? 12,
    fontWeight: fontWeight ?? FontWeight.w500,
    letterSpacing: 0.1,
    height: lineHeight(isTamil: isTamil),
    color: color,
  );

  /// Small badge / tag: 10-12px, Medium 500
  static TextStyle badge({
    Color color = AppColors.primary,
    bool isTamil = false,
    double? fontSize,
    FontWeight? fontWeight,
  }) => TextStyle(
    fontFamily: fontFamily(isTamil: isTamil),
    fontFamilyFallback: fallbackFonts(isTamil: isTamil),
    fontSize: fontSize ?? 11,
    fontWeight: fontWeight ?? FontWeight.w600,
    letterSpacing: isTamil ? 0 : 0.2,
    height: lineHeight(isTamil: isTamil),
    color: color,
  );

  /// Small badge alias
  static TextStyle smallBadge({
    Color color = AppColors.primary,
    bool isTamil = false,
    double? fontSize,
    FontWeight? fontWeight,
  }) => badge(
    color: color,
    isTamil: isTamil,
    fontSize: fontSize,
    fontWeight: fontWeight,
  );
}

import 'package:flutter/material.dart';

/// Vegora Premium Color System
///
/// Refined green-and-white visual identity for high-end fresh grocery shopping.
/// Built with accessibility, natural organic tones, and high-contrast readability.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Core Brand Greens
  // ---------------------------------------------------------------------------
  /// Primary brand green: Fresh natural green (#278447)
  static const Color primary = Color(0xFF278447);

  /// Dark green: Deep botanical green (#185C35)
  static const Color primaryDark = Color(0xFF185C35);

  /// Light green: Soft fresh green (#E8F5E9)
  static const Color primaryLight = Color(0xFFE8F5E9);

  /// Primary container background: Soft fresh green (#E8F5E9)
  static const Color primaryContainer = Color(0xFFE8F5E9);

  /// Text / icon on primary container: Deep botanical green (#185C35)
  static const Color onPrimaryContainer = Color(0xFF185C35);

  // ---------------------------------------------------------------------------
  // Backgrounds & Surfaces
  // ---------------------------------------------------------------------------
  /// Pale green background: Natural off-white green (#F5F9F4)
  static const Color background = Color(0xFFF5F9F4);

  /// Main background & cards: Clean white (#FFFFFF)
  static const Color surface = Color(0xFFFFFFFF);

  /// Subtle elevated surface or pill container: Pale natural green (#F5F9F4)
  static const Color surfaceVariant = Color(0xFFF5F9F4);

  /// Divider & borders: Soft neutral grey (#E6EBE6)
  static const Color border = Color(0xFFE6EBE6);
  static const Color divider = Color(0xFFE6EBE6);
  static const Color borderDark = Color(0xFFCBD5CD);

  // ---------------------------------------------------------------------------
  // Typography Colors
  // ---------------------------------------------------------------------------
  /// Primary text: Deep charcoal (#202820)
  static const Color textPrimary = Color(0xFF202820);

  /// Secondary text: Muted grey-green (#68756B)
  static const Color textSecondary = Color(0xFF68756B);

  /// Muted captions and placeholders: Soft neutral (#8E9B91)
  static const Color textMuted = Color(0xFF8E9B91);

  // ---------------------------------------------------------------------------
  // Semantic Accents & Feedback
  // ---------------------------------------------------------------------------
  /// Success: Accessible green (#218653)
  static const Color success = Color(0xFF218653);
  static const Color successContainer = Color(0xFFE6F4EA);

  /// Warning / Urgent Sales: Warm amber (#C47B12)
  static const Color warning = Color(0xFFC47B12);
  static const Color warningContainer = Color(0xFFFEF3E2);

  /// Error / Destructive: Accessible red (#C83F49)
  static const Color error = Color(0xFFC83F49);
  static const Color errorContainer = Color(0xFFFDE8E9);

  /// Subtle secondary accent: Warm amber (#C47B12)
  static const Color secondary = Color(0xFFC47B12);
  static const Color secondaryLight = Color(0xFFFEF3E2);
  static const Color secondaryDark = Color(0xFF9E5F09);
  static const Color accent = Color(0xFF278447);

  // ---------------------------------------------------------------------------
  // Neutral Scale (Slate-Green Tinted)
  // ---------------------------------------------------------------------------
  static const Color neutral50 = Color(0xFFF8FAF8);
  static const Color neutral100 = Color(0xFFF2F6F2);
  static const Color neutral200 = Color(0xFFE6EBE6);
  static const Color neutral300 = Color(0xFFCBD5CD);
  static const Color neutral400 = Color(0xFF9AA89E);
  static const Color neutral500 = Color(0xFF68756B);
  static const Color neutral600 = Color(0xFF4C574F);
  static const Color neutral700 = Color(0xFF353E37);
  static const Color neutral800 = Color(0xFF252C26);
  static const Color neutral900 = Color(0xFF141915);

  // ---------------------------------------------------------------------------
  // Order Lifecycle Status Colors (Restrained, Professional)
  // ---------------------------------------------------------------------------
  static const Color statusNew = Color(0xFF1D5EA8); // Muted navy blue
  static const Color statusAccepted = Color(0xFF185C35); // Deep botanical green
  static const Color statusPreparing = Color(0xFFC47B12); // Warm amber
  static const Color statusReadyForPickup = Color(0xFF6A449E); // Muted violet
  static const Color statusOutForDelivery = Color(0xFF0D7E68); // Deep teal
  static const Color statusDelivered = Color(0xFF218653); // Accessible green
  static const Color statusCancelled = Color(0xFFC83F49); // Accessible red
  static const Color statusRejected = Color(0xFFC83F49); // Accessible red
}

/// Vegora Global Spacing Scale
class AppSpacing {
  AppSpacing._();

  /// 4px: very small spacing
  static const double xs = 4.0;

  /// 8px: compact spacing
  static const double sm = 8.0;

  /// 12px: small spacing
  static const double md = 12.0;

  /// 16px: standard spacing
  static const double lg = 16.0;

  /// 20px: medium spacing
  static const double xl = 20.0;

  /// 24px: section spacing
  static const double xxl = 24.0;

  /// 32px: large spacing
  static const double xxxl = 32.0;

  /// 44px: major layout separation
  static const double huge = 44.0;
}

/// Vegora Corner Radii Scale
class AppRadii {
  AppRadii._();

  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 14.0;
  static const double xl = 18.0;
  static const double xxl = 24.0;
  static const double full = 999.0;

  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius roundedXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius roundedFull = BorderRadius.all(
    Radius.circular(full),
  );
}

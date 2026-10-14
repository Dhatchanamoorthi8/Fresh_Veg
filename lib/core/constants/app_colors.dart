import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Vegora Brand Greens (from Official Branding Board)
  static const Color primary = Color(0xFF0B6B3A); // Deep Forest Green (#0B6B3A)
  static const Color primaryDark = Color(0xFF074826);
  static const Color primaryLight = Color(
    0xFF4CAF50,
  ); // Fresh Accent Green (#4CAF50)
  static const Color primaryContainer = Color(
    0xFFE8F5E9,
  ); // Mint Background (#E8F5E9)
  static const Color onPrimaryContainer = Color(0xFF0B6B3A);

  // Secondary & Accents
  static const Color secondary = Color(
    0xFFFF8A00,
  ); // Vibrant Carrot Orange (#FF8A00)
  static const Color secondaryLight = Color(0xFFFFE0B2);
  static const Color secondaryDark = Color(0xFFE65100);
  static const Color accent = Color(0xFFFF8A00); // Vibrant Carrot Orange

  // Backgrounds & Neutrals
  static const Color background = Color(
    0xFFF7FAF5,
  ); // Subtle Mint/Organic White (#F7FAF5)
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F0);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFFCBD5E1);
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  // Error & Alert
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);

  // Typography Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status Colors for Order Workflow
  static const Color statusNew = Color(0xFF2563EB); // Royal Blue
  static const Color statusAccepted = Color(0xFF6366F1); // Indigo
  static const Color statusPreparing = Color(0xFFD97706); // Amber
  static const Color statusReadyForPickup = Color(0xFF8B5CF6); // Violet
  static const Color statusOutForDelivery = Color(0xFF0D9488); // Teal
  static const Color statusDelivered = Color(0xFF16A34A); // Emerald
  static const Color statusCancelled = Color(0xFFE11D48); // Rose
  static const Color statusRejected = Color(0xFFDC2626); // Crimson
}

import 'package:flutter/material.dart';

/// Semantic Color Tokens for TindaGrid
/// Follows the design specifications in ui_ux_design.md
class AppColors {
  AppColors._();

  // Primary Emerald (Money In, Success, Cash, Safe Status)
  static const Color primary = Color(0xFF059669);
  static const Color primaryDark = Color(0xFF10B981);
  static const Color primaryLight = Color(0xFFD1FAE5);

  // GCash Blue (E-Wallet, Digital Payments, Floats, OCR)
  static const Color gcash = Color(0xFF007DFE);
  static const Color gcashDark = Color(0xFF38BDF8);
  static const Color gcashLight = Color(0xFFE0F2FE);

  // Utang Coral / Red (Receivables, Supplier Payables, Low Stock Alert)
  static const Color alert = Color(0xFFDC2626);
  static const Color alertDark = Color(0xFFF87171);
  static const Color alertLight = Color(0xFFFEE2E2);

  // Suki Amber (Pending, Caution, Due Soon)
  static const Color warning = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Light Mode Surfaces & Text
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Dark Mode Surfaces & Text (OLED optimized)
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color borderDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
}

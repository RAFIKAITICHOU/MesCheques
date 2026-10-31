import 'package:flutter/material.dart';

class AppColors {
  // Main brand colors
  static const Color primary = Color(0xFF1E4FD8);      // Deep blue
  static const Color primaryDark = Color(0xFF153CB5);
  static const Color primaryLight = Color(0xFFEEF2FF);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF5F7FA);   // Very light grey
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  // Status colors
  static const Color inStock = Color(0xFFF59E0B);      // Orange / Amber for "En stock"
  static const Color inStockBg = Color(0xFFFEF3C7);
  static const Color used = Color(0xFF16A34A);         // Green for "Utilisé"
  static const Color usedBg = Color(0xFFDCFCE7);

  // Danger & Accents
  static const Color danger = Color(0xFFDC2626);       // Red for delete / alert
  static const Color dangerBg = Color(0xFFFEE2E2);

  // Text
  static const Color textPrimary = Color(0xFF111827);  // Dark slate
  static const Color textSecondary = Color(0xFF6B7280);// Medium grey
  static const Color textMuted = Color(0xFF9CA3AF);

  // Borders & Dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Convenience aliases
  static const Color cardBackground = card;
  static const Color accentDanger = danger;
  static const Color accentWarning = inStock;
  static const Color textHint = textMuted;
}

class AppConstants {
  static const String appName = 'MesCheques';
  static const String currency = 'DH';
  static const int trashRetentionDays = 15;
  static const int purgedRetentionDays = 90;
  static const String backupExtension = 'mcheques';
  static const int backupVersion = 3;
  static const int dbVersion = 5;
  static const int maxImagesPerCheck = 5;
}

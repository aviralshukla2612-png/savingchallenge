import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette - Deep Emerald / Teal
  static const Color primary = Color(0xFF006D5B);
  static const Color primaryLight = Color(0xFF00897B);
  static const Color primaryDark = Color(0xFF004D40);
  static const Color accent = Color(0xFF00BFA5);

  // Background & Surfaces (Light)
  static const Color backgroundLight = Color(0xFFF7F9F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFEFF3F2);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Background & Surfaces (Dark)
  static const Color backgroundDark = Color(0xFF101716);
  static const Color surfaceDark = Color(0xFF1A2322);
  static const Color surfaceVariantDark = Color(0xFF24302E);
  static const Color cardDark = Color(0xFF1C2725);

  // Status & Financial Indicators
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Neutrals
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF2E3D3A);

  // Category Accent Colors
  static const Color cashColor = Color(0xFF10B981);
  static const Color bankColor = Color(0xFF3B82F6);
  static const Color upiColor = Color(0xFF8B5CF6);
  static const Color cardColor = Color(0xFFF59E0B);
  static const Color otherColor = Color(0xFF64748B);

  static Color getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return cashColor;
      case 'bank':
        return bankColor;
      case 'upi':
        return upiColor;
      case 'card':
        return cardColor;
      default:
        return otherColor;
    }
  }
}

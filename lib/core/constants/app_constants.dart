import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'أقرب جامع';
  static const Duration splashDuration = Duration(seconds: 2);

  // ─── Design Tokens ──────────────────────────────────────────
  // Primary: deep emerald green (Islamic modern)
  static const Color primaryColor = Color(0xFF056C46);
  static const Color primaryDark = Color(0xFF034A30);
  static const Color primaryLight = Color(0xFF0A8F5C);

  // Accent: golden copper
  static const Color accentGold = Color(0xFFC89B3C);
  static const Color accentGoldLight = Color(0xFFDDB868);

  // Backgrounds
  static const Color creamBackground = Color(0xFFF8F9FA);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Status
  static const Color onlineGreen = Color(0xFF4CAF50);
  static const Color offlineOrange = Color(0xFFFF9800);

  // Map preview
  static const Color mapBackground = Color(0xFFE8F0EC);
  static const Color mapGridLine = Color(0xFFD0DCD4);
  static const Color mapRoad = Color(0xFFC5D1C9);
  static const Color userDotColor = Color(0xFF2196F3);

  // Walking speed: ~5 km/h average
  static const double walkingSpeedKmH = 5.0;

  // Border radius
  static const double sheetRadius = 30.0;
}

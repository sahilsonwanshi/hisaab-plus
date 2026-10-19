import 'package:flutter/material.dart';

/// Semantic Design Tokens for Hisaab Plus
/// Supports both OLED Dark Mode and Clean Fintech Light Mode.
class AppColors {
  final bool isDark;

  // Background Canvas & Surfaces
  final Color bg;
  final Color surface;
  final Color surfaceSecondary;
  final Color surfaceHighlight;

  // Borders & Dividers
  final Color border;
  final Color borderSubtle;
  final Color divider;

  // Typography
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Positive Flow (Lena / Income)
  final Color greenAccent;
  final Color greenPillBg;
  final Color greenPillBorder;
  final Color greenText;

  // Negative Flow (Dena / Expense)
  final Color redAccent;
  final Color redPillBg;
  final Color redPillBorder;
  final Color redText;

  // Secondary Accents
  final Color blueAccent;
  final Color amberAccent;

  // Navigation & Interactive Elements
  final Color navBarBg;
  final Color navBarBorder;
  final Color plusButtonBg;
  final Color plusButtonIcon;
  final BoxShadow cardShadow;

  const AppColors({
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.surfaceSecondary,
    required this.surfaceHighlight,
    required this.border,
    required this.borderSubtle,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.greenAccent,
    required this.greenPillBg,
    required this.greenPillBorder,
    required this.greenText,
    required this.redAccent,
    required this.redPillBg,
    required this.redPillBorder,
    required this.redText,
    required this.blueAccent,
    required this.amberAccent,
    required this.navBarBg,
    required this.navBarBorder,
    required this.plusButtonBg,
    required this.plusButtonIcon,
    required this.cardShadow,
  });

  /// 100% Preserved Deep OLED Dark Theme
  static const AppColors dark = AppColors(
    isDark: true,
    bg: Color(0xFF000000),
    surface: Color(0xFF111115),
    surfaceSecondary: Color(0xFF18181D),
    surfaceHighlight: Color(0xFF22222A),
    border: Color(0x1FFFFFFF), // 12% white
    borderSubtle: Color(0x0FFFFFFF), // 6% white
    divider: Color(0x14FFFFFF), // 8% white
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA1A1AA),
    textMuted: Color(0xFF71717A),
    greenAccent: Color(0xFF00E676),
    greenPillBg: Color(0x1F00E676),
    greenPillBorder: Color(0x4D00E676),
    greenText: Color(0xFF00E676),
    redAccent: Color(0xFFFF5252),
    redPillBg: Color(0x1FFF5252),
    redPillBorder: Color(0x4DFF5252),
    redText: Color(0xFFFF5252),
    blueAccent: Color(0xFF38BDF8),
    amberAccent: Color(0xFFF59E0B),
    navBarBg: Color(0x66000000), // 40% black
    navBarBorder: Color(0x1FFFFFFF),
    plusButtonBg: Color(0xFFFFFFFF),
    plusButtonIcon: Color(0xFF000000),
    cardShadow: BoxShadow(
      color: Color(0x66000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  );

  /// Clean High-Contrast Fintech Light Theme
  static const AppColors light = AppColors(
    isDark: false,
    bg: Color(0xFFF8FAFC), // Slate 50
    surface: Color(0xFFFFFFFF), // Pure crisp white
    surfaceSecondary: Color(0xFFF1F5F9), // Slate 100
    surfaceHighlight: Color(0xFFE2E8F0), // Slate 200
    border: Color(0xFFE2E8F0), // Slate 200
    borderSubtle: Color(0xFFF1F5F9),
    divider: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A), // Slate 900
    textSecondary: Color(0xFF475569), // Slate 600
    textMuted: Color(0xFF94A3B8), // Slate 400
    greenAccent: Color(0xFF059669), // Emerald 600
    greenPillBg: Color(0xFFECFDF5), // Emerald 50
    greenPillBorder: Color(0xFFA7F3D0), // Emerald 200
    greenText: Color(0xFF047857), // Emerald 700
    redAccent: Color(0xFFE11D48), // Rose 600
    redPillBg: Color(0xFFFFF1F2), // Rose 50
    redPillBorder: Color(0xFFFECDD3), // Rose 200
    redText: Color(0xFFBE123C), // Rose 700
    blueAccent: Color(0xFF0284C7), // Sky 600
    amberAccent: Color(0xFFD97706), // Amber 600
    navBarBg: Color(0xD9FFFFFF), // 85% translucent white
    navBarBorder: Color(0xFFCBD5E1), // Slate 300
    plusButtonBg: Color(0xFF0F172A), // Slate 900
    plusButtonIcon: Color(0xFFFFFFFF),
    cardShadow: BoxShadow(
      color: Color(0x0F0F172A), // Subtle elevation shadow
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  );

  /// Resolves the current theme tokens based on BuildContext
  static AppColors of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  }
}

/// Handy extension on [BuildContext] to access [AppColors] effortlessly.
extension AppColorsExtension on BuildContext {
  AppColors get colors => AppColors.of(this);
}

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// OLED Dark Theme (Default)
  static ThemeData get darkTheme {
    const colors = AppColors.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.bg,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00E676),
        onPrimary: Colors.black,
        surface: Color(0xFF111115),
        onSurface: Colors.white,
        error: Color(0xFFFF5252),
        onError: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF000000),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF16161A),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x1FFFFFFF), width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF141418),
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Color(0xFF141418),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF111115),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x1FFFFFFF), width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x14FFFFFF),
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Clean High-Contrast Fintech Light Theme
  static ThemeData get lightTheme {
    const colors = AppColors.light;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.bg,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF059669),
        onPrimary: Colors.white,
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF0F172A),
        error: Color(0xFFE11D48),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 1,
      ),
    );
  }
}

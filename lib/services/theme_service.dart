import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const String _settingsBoxName = 'settings_box';
  static const String _themeKey = 'theme_mode';

  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  ThemeMode get currentThemeMode => themeModeNotifier.value;

  /// Initializes theme from stored Hive settings (defaults to dark)
  Future<void> initialize() async {
    try {
      Box settingsBox;
      if (Hive.isBoxOpen(_settingsBoxName)) {
        settingsBox = Hive.box(_settingsBoxName);
      } else {
        settingsBox = await Hive.openBox(_settingsBoxName);
      }

      final String? savedMode = settingsBox.get(_themeKey) as String?;

      switch (savedMode) {
        case 'light':
          themeModeNotifier.value = ThemeMode.light;
          break;
        case 'system':
          themeModeNotifier.value = ThemeMode.system;
          break;
        case 'dark':
        default:
          themeModeNotifier.value = ThemeMode.dark;
          break;
      }
    } catch (e) {
      debugPrint("ThemeService initialize error: $e");
      themeModeNotifier.value = ThemeMode.dark;
    }

    updateSystemOverlay(themeModeNotifier.value);
  }

  /// Sets and persists new theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;

    try {
      Box settingsBox;
      if (Hive.isBoxOpen(_settingsBoxName)) {
        settingsBox = Hive.box(_settingsBoxName);
      } else {
        settingsBox = await Hive.openBox(_settingsBoxName);
      }

      String stringValue = 'dark';
      if (mode == ThemeMode.light) {
        stringValue = 'light';
      } else if (mode == ThemeMode.system) {
        stringValue = 'system';
      }

      await settingsBox.put(_themeKey, stringValue);
    } catch (e) {
      debugPrint("ThemeService persist error: $e");
    }

    updateSystemOverlay(mode);
  }

  /// Helper to determine if dark mode is active in the current context
  bool isDarkMode(BuildContext context) {
    if (themeModeNotifier.value == ThemeMode.dark) return true;
    if (themeModeNotifier.value == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  /// Dynamically updates status bar and navigation bar brightness
  void updateSystemOverlay(ThemeMode mode) {
    final bool isDark = mode == ThemeMode.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor:
            isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }
}

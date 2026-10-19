import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab_plus/theme/app_colors.dart';
import 'package:hisaab_plus/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppColors Tests', () {
    test('AppColors.dark has proper OLED values', () {
      const dark = AppColors.dark;
      expect(dark.isDark, isTrue);
      expect(dark.bg, const Color(0xFF000000));
      expect(dark.textPrimary, const Color(0xFFFFFFFF));
      expect(dark.plusButtonBg, const Color(0xFFFFFFFF));
      expect(dark.plusButtonIcon, const Color(0xFF000000));
    });

    test('AppColors.light has proper high-contrast values', () {
      const light = AppColors.light;
      expect(light.isDark, isFalse);
      expect(light.bg, const Color(0xFFF8FAFC));
      expect(light.textPrimary, const Color(0xFF0F172A));
      expect(light.surface, const Color(0xFFFFFFFF));
      expect(light.plusButtonBg, const Color(0xFF0F172A));
      expect(light.plusButtonIcon, const Color(0xFFFFFFFF));
    });

    test('AppTheme generates valid ThemeData for both modes', () {
      final darkTheme = AppTheme.darkTheme;
      final lightTheme = AppTheme.lightTheme;

      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF000000));

      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.scaffoldBackgroundColor, const Color(0xFFF8FAFC));
    });

    testWidgets('BuildContext.colors resolves AppColors.dark and AppColors.light correctly', (tester) async {
      late AppColors resolvedDark;
      late AppColors resolvedLight;

      await tester.pumpWidget(
        Theme(
          data: AppTheme.darkTheme,
          child: Builder(
            builder: (context) {
              resolvedDark = context.colors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolvedDark.isDark, isTrue);
      expect(resolvedDark.bg, const Color(0xFF000000));

      await tester.pumpWidget(
        Theme(
          data: AppTheme.lightTheme,
          child: Builder(
            builder: (context) {
              resolvedLight = context.colors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolvedLight.isDark, isFalse);
      expect(resolvedLight.bg, const Color(0xFFF8FAFC));
    });
  });
}

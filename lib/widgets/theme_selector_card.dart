import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/theme_service.dart';
import '../theme/app_colors.dart';

class ThemeSelectorCard extends StatelessWidget {
  const ThemeSelectorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, currentMode, _) {
        return Container(
          decoration: BoxDecoration(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.35)
                : colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.border,
              width: 1,
            ),
            boxShadow: colors.isDark ? [] : [colors.cardShadow],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    currentMode == ThemeMode.light
                        ? Icons.wb_sunny_rounded
                        : currentMode == ThemeMode.dark
                            ? Icons.nightlight_round
                            : Icons.brightness_auto_rounded,
                    color: currentMode == ThemeMode.light
                        ? colors.amberAccent
                        : colors.blueAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "App Theme",
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    currentMode == ThemeMode.light
                        ? "Light Mode"
                        : currentMode == ThemeMode.dark
                            ? "Dark (OLED)"
                            : "System Auto",
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.borderSubtle,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    _buildOption(
                      context: context,
                      mode: ThemeMode.light,
                      currentMode: currentMode,
                      label: "Light",
                      icon: Icons.wb_sunny_outlined,
                      activeIcon: Icons.wb_sunny_rounded,
                      activeColor: const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 4),
                    _buildOption(
                      context: context,
                      mode: ThemeMode.dark,
                      currentMode: currentMode,
                      label: "Dark",
                      icon: Icons.dark_mode_outlined,
                      activeIcon: Icons.dark_mode_rounded,
                      activeColor: const Color(0xFF818CF8),
                    ),
                    const SizedBox(width: 4),
                    _buildOption(
                      context: context,
                      mode: ThemeMode.system,
                      currentMode: currentMode,
                      label: "Auto",
                      icon: Icons.brightness_auto_outlined,
                      activeIcon: Icons.brightness_auto_rounded,
                      activeColor: const Color(0xFF0284C7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required Color activeColor,
  }) {
    final bool isSelected = currentMode == mode;
    final colors = context.colors;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
            ThemeService.instance.setThemeMode(mode);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (colors.isDark ? const Color(0xFF27272E) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: colors.isDark ? 0.3 : 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 15,
                color: isSelected ? activeColor : colors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colors.textPrimary : colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

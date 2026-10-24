import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class FloatingOledNavBar extends StatefulWidget {
  final int activeTab;
  final Function(int) onTabSelected;
  final VoidCallback onAddPressed;

  const FloatingOledNavBar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    required this.onAddPressed,
  });

  @override
  State<FloatingOledNavBar> createState() => _FloatingOledNavBarState();
}

class _FloatingOledNavBarState extends State<FloatingOledNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handlePlusTap() {
    HapticFeedback.lightImpact();
    _animController.forward().then((_) {
      if (mounted) _animController.reverse();
    });
    widget.onAddPressed();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Positioned(
      left: 14,
      right: 14,
      bottom: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Frosted Glass 3-Tab Capsule Nav
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      height: 62,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.navBarBg,
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(
                          color: colors.isDark
                              ? colors.navBarBorder
                              : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.isDark
                                ? Colors.black.withValues(alpha: 0.40)
                                : const Color(0x0C0F172A),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(context, 0, Icons.home_rounded, "Home"),
                          _buildNavItem(context, 1, Icons.menu_book_rounded, "Khata"),
                          _buildNavItem(context, 2, Icons.person_rounded, "Profile"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 2. Simple, Fast, Responsive Floating '+' Button
              GestureDetector(
                onTap: _handlePlusTap,
                behavior: HitTestBehavior.opaque,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      gradient: colors.isDark
                          ? null
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF059669),
                                Color(0xFF047857),
                              ],
                            ),
                      color: colors.isDark ? colors.plusButtonBg : null,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.isDark
                            ? Colors.transparent
                            : const Color(0xFF34D399).withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.isDark
                              ? Colors.black.withValues(alpha: 0.45)
                              : const Color(0x3D059669),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        if (colors.isDark)
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.20),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                      ],
                    ),
                    child: Center(
                      child: RotationTransition(
                        turns: _rotationAnimation,
                        child: Icon(
                          Icons.add_rounded,
                          color: colors.plusButtonIcon,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final bool isSelected = widget.activeTab == index;
    final colors = context.colors;

    return GestureDetector(
      onTap: () => widget.onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (colors.isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : colors.textPrimary.withValues(alpha: 0.08))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: isSelected
              ? Border.all(
                  color: colors.isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : colors.textPrimary.withValues(alpha: 0.12),
                  width: 1,
                )
              : Border.all(color: Colors.transparent),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? colors.textPrimary : colors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colors.textPrimary : colors.textMuted,
                height: 1.1,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

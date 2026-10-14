import 'dart:ui';
import 'package:flutter/material.dart';

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

  static const Color textMuted = Color(0xFFA1A1AA);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
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
    widget.onAddPressed();
    _animController.forward().then((_) {
      if (mounted) _animController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                        color: Colors.black.withValues(alpha: 0.40),
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.40),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(0, Icons.home_rounded, "Home"),
                          _buildNavItem(1, Icons.menu_book_rounded, "Khata"),
                          _buildNavItem(2, Icons.person_rounded, "Profile"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 2. Smooth Responsive Floating '+' Button
              GestureDetector(
                onTap: _handlePlusTap,
                behavior: HitTestBehavior.opaque,
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        height: 58,
                        width: 58,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
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
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.black,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = widget.activeTab == index;

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
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: isSelected
              ? Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1)
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
                color: isSelected ? Colors.white : textMuted,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : textMuted,
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

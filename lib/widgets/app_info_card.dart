import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import 'custom_toast.dart';

class AppInfoCard extends StatefulWidget {
  const AppInfoCard({super.key});

  @override
  State<AppInfoCard> createState() => _AppInfoCardState();
}

class _AppInfoCardState extends State<AppInfoCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: colors.glassCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.glassCardBorder,
              width: 1.2,
            ),
            boxShadow: colors.isDark ? [] : [colors.cardShadow],
          ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _isExpanded = !_isExpanded);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: (colors.isDark
                                ? const Color(0xFF0F291C)
                                : colors.greenPillBg)
                            .withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: colors.greenAccent,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "About Hisaab+",
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _isExpanded ? "Hide" : "Details",
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colors.textMuted,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                      height: 1,
                      color: colors.divider,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Build Version",
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.isDark
                              ? const Color(0xFF1B2A1E)
                              : colors.greenPillBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "v4.4.4",
                          style: TextStyle(
                            color: colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Lead Developer",
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                      Text(
                        "Sahil Sonwanshi",
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Architecture",
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                      Text(
                        "100% Offline (Hive NoSQL)",
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(
                        const ClipboardData(text: "sahilsonwanshi94@gmail.com"),
                      );
                      AppToast.show(
                        context,
                        title: "Email support copied!",
                        type: ToastType.success,
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : colors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.alternate_email_rounded,
                            size: 14,
                            color: colors.blueAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "sahilsonwanshi94@gmail.com",
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.copy_rounded,
                            color: colors.textMuted,
                            size: 13,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
        ),
      ),
    );
  }
}

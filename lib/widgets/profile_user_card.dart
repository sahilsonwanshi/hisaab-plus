import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/app_colors.dart';

class ProfileUserCard extends StatelessWidget {
  final GoogleSignInAccount? googleAccount;
  final VoidCallback onTap;

  const ProfileUserCard({
    super.key,
    required this.googleAccount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool isSignedIn = googleAccount != null;
    final String displayName =
        googleAccount?.displayName?.trim().isNotEmpty == true
            ? googleAccount!.displayName!
            : "Sahil Sonwanshi";
    final String email = googleAccount?.email ?? "";
    final String initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : "S";

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: colors.glassCardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.glassCardBorder,
              width: 1.2,
            ),
            boxShadow: colors.isDark ? [] : [colors.cardShadow],
          ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Clean Initial Monogram
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSignedIn
                        ? (colors.isDark
                            ? const Color(0xFF0F291C)
                            : colors.greenPillBg)
                        : colors.surfaceSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSignedIn
                          ? colors.greenPillBorder
                          : colors.border,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: isSignedIn
                          ? (colors.isDark ? colors.greenAccent : colors.greenText)
                          : colors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // User Name & Account Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSignedIn
                                  ? (colors.isDark
                                      ? const Color(0xFF0B291A)
                                      : colors.greenPillBg)
                                  : colors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isSignedIn ? "PRO" : "OFFLINE",
                              style: TextStyle(
                                color: isSignedIn
                                    ? (colors.isDark
                                        ? colors.greenAccent
                                        : colors.greenText)
                                    : colors.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isSignedIn ? email : "Local Storage Account",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Clean Text-only Action Button (No icons)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (isSignedIn ? colors.blueAccent : colors.surfaceHighlight)
                        .withValues(alpha: colors.isDark ? 0.12 : 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isSignedIn ? colors.blueAccent : colors.border)
                          .withValues(alpha: colors.isDark ? 0.25 : 0.6),
                    ),
                  ),
                  child: Text(
                    isSignedIn ? "Backup" : "Sync",
                    style: TextStyle(
                      color: isSignedIn ? colors.blueAccent : colors.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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

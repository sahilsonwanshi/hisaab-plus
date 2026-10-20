import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProfileCompactStats extends StatelessWidget {
  final int netBalance;
  final int totalLena;
  final int totalDena;
  final int lenaCount;
  final int denaCount;
  final int personalKharchaTotal;
  final VoidCallback onAddPersonalKharcha;

  const ProfileCompactStats({
    super.key,
    required this.netBalance,
    required this.totalLena,
    required this.totalDena,
    required this.lenaCount,
    required this.denaCount,
    required this.personalKharchaTotal,
    required this.onAddPersonalKharcha,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool isNetPositive = netBalance >= 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.glassCardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.glassCardBorder,
              width: 1.2,
            ),
            boxShadow: colors.isDark ? [] : [colors.cardShadow],
          ),
      child: Row(
        children: [
          // 1. Lena Hai
          Expanded(
            child: _buildColumn(
              context: context,
              label: "LENA HAI",
              amount: "+₹$totalLena",
              count: "$lenaCount log",
              color: colors.isDark ? colors.greenAccent : colors.greenText,
            ),
          ),

          _buildDivider(context),

          // 2. Dena Hai
          Expanded(
            child: _buildColumn(
              context: context,
              label: "DENA HAI",
              amount: "-₹$totalDena",
              count: "$denaCount log",
              color: colors.isDark ? colors.redAccent : colors.redText,
            ),
          ),

          _buildDivider(context),

          // 3. Net Balance
          Expanded(
            child: _buildColumn(
              context: context,
              label: "NET BALANCE",
              amount: "${isNetPositive ? '+₹' : '-₹'}${netBalance.abs()}",
              count: isNetPositive ? "Favour Me" : "Dena Baaki",
              color: isNetPositive ? (colors.isDark ? colors.greenAccent : colors.greenText) : (colors.isDark ? colors.redAccent : colors.redText),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: colors.divider,
    );
  }

  Widget _buildColumn({
    required BuildContext context,
    required String label,
    required String amount,
    required String count,
    required Color color,
  }) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          count,
          style: TextStyle(
            color: colors.textSecondary.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

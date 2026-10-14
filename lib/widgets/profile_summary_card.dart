import 'dart:math';
import 'package:flutter/material.dart';

class ProfileSummaryCard extends StatelessWidget {
  final int netBalance;
  final int totalLena;
  final int totalDena;
  final int lenaCount;
  final int denaCount;
  final double greenFrac;
  final double redFrac;
  final VoidCallback onSyncTap;
  final VoidCallback onAddKharchaTap;

  static const Color greenAccent = Color(0xFF00E676);
  static const Color greenPillBg = Color(0xFF0B291A);
  static const Color redAccent = Color(0xFFFF5252);
  static const Color redPillBg = Color(0xFF2E1215);
  static const Color textMuted = Color(0xFFA1A1AA);

  const ProfileSummaryCard({
    super.key,
    required this.netBalance,
    required this.totalLena,
    required this.totalDena,
    required this.lenaCount,
    required this.denaCount,
    required this.greenFrac,
    required this.redFrac,
    required this.onSyncTap,
    required this.onAddKharchaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Radial Ring Circle
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(96, 96),
                      painter: NetRadialChartPainter(
                        greenFraction: greenFrac,
                        redFraction: redFrac,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "NET",
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${netBalance >= 0 ? '+₹' : '-₹'}${netBalance.abs()}",
                          style: TextStyle(
                            color: netBalance >= 0 ? greenAccent : redAccent,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),

              // Lena & Dena Rows
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Lena Hai",
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: greenPillBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "$lenaCount log",
                            style: const TextStyle(
                              color: greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "₹$totalLena.00",
                      style: const TextStyle(
                        color: greenAccent,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Dena Hai",
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: redPillBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "$denaCount log",
                            style: const TextStyle(
                              color: redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "₹$totalDena.00",
                      style: const TextStyle(
                        color: redAccent,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Bottom Action Buttons (Drive Sync & Kharcha)
          Row(
            children: [
              InkWell(
                onTap: onSyncTap,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.cloud_sync_rounded,
                        color: Color(0xFF38BDF8),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Drive Sync",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onAddKharchaTap,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 17,
                        color: Colors.black,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Kharcha",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Dual-Arc Radial Chart Painter
class NetRadialChartPainter extends CustomPainter {
  final double greenFraction;
  final double redFraction;

  const NetRadialChartPainter({
    required this.greenFraction,
    required this.redFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;
    const strokeWidth = 8.0;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, trackPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);

    final greenPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    final redPaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    const startAngle = -pi / 2;
    const gap = 0.28;

    final greenSweep = max(0.0, (2 * pi * greenFraction) - gap);
    final redSweep = max(0.0, (2 * pi * redFraction) - gap);

    if (greenFraction > 0.05) {
      canvas.drawArc(rect, startAngle, greenSweep, false, greenPaint);
    }

    if (redFraction > 0.05) {
      canvas.drawArc(
        rect,
        startAngle + greenSweep + gap,
        redSweep,
        false,
        redPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant NetRadialChartPainter oldDelegate) =>
      oldDelegate.greenFraction != greenFraction ||
      oldDelegate.redFraction != redFraction;
}

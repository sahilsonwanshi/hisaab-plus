import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'custom_toast.dart';

class AppInfoCard extends StatefulWidget {
  const AppInfoCard({super.key});

  @override
  State<AppInfoCard> createState() => _AppInfoCardState();
}

class _AppInfoCardState extends State<AppInfoCard> {
  bool _isExpanded = false;

  static const Color greenAccent = Color(0xFF00E676);
  static const Color textMuted = Color(0xFFA1A1AA);
  static const Color textMutedDark = Color(0xFF71717A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
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
                        color: const Color(0xFF0F291C).withValues(alpha: 0.70),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: greenAccent,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "About Hisaab+",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _isExpanded ? "Hide" : "Details",
                      style: const TextStyle(
                        color: textMutedDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: textMutedDark,
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
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Build Version",
                        style: TextStyle(color: textMuted, fontSize: 11.5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B2A1E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "v4.4.2",
                          style: TextStyle(
                            color: greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Lead Developer",
                        style: TextStyle(color: textMuted, fontSize: 11.5),
                      ),
                      Text(
                        "Sahil Sonwanshi",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Architecture",
                        style: TextStyle(color: textMuted, fontSize: 11.5),
                      ),
                      Text(
                        "100% Offline (Hive NoSQL)",
                        style: TextStyle(
                          color: Colors.white,
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.alternate_email_rounded,
                            size: 14,
                            color: Color(0xFF38BDF8),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "sahilsonwanshi94@gmail.com",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.copy_rounded,
                            color: textMutedDark,
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
    );
  }
}

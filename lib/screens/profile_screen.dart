import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/friend_model.dart';
import '../widgets/custom_toast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // OLED Luxury Dark Theme Palette
  static const Color oledBg = Color(0xFF000000);
  static const Color cardSurface = Color(0xFF141416);
  static const Color cardSurfaceLight = Color(0xFF1E1E22);
  static const Color greenAccent = Color(0xFF00E676);
  static const Color redAccent = Color(0xFFFF5252);
  static const Color textMuted = Color(0xFF888890);
  static const Color textMutedDark = Color(0xFF55555C);
  static const Color borderCustom = Color(0xFF222226);

  bool _isDevCardExpanded = false;

  late Box<FriendModel> _friendsBox;

  @override
  void initState() {
    super.initState();
    _friendsBox = Hive.box<FriendModel>('friends_box');
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: oledBg,
      body: SafeArea(
        child: Column(
          children: [
            // =========================================================
            // 1. FIXED TOP GUEST USER CARD (No Phone, No Expand Icon)
            // =========================================================
            Container(
              color: oledBg,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderCustom),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: cardSurfaceLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Guest #8941",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "Offline Ledger Mode",
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =========================================================
            // 2. SCROLLABLE BODY (CLEAN & MINIMAL)
            // =========================================================
            Expanded(
              child: ValueListenableBuilder<Box<FriendModel>>(
                valueListenable: _friendsBox.listenable(),
                builder: (context, box, _) {
                  int totalLena = 0;
                  int totalDena = 0;

                  for (var friend in box.values) {
                    if (friend.type == 'lena' && friend.balance > 0) {
                      totalLena += friend.balance;
                    } else if (friend.type == 'dena' && friend.balance > 0) {
                      totalDena += friend.balance;
                    }
                  }

                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: greenAccent,
                    backgroundColor: cardSurfaceLight,
                    displacement: 20,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Financial Overview (Lena Hai / Dena Hai)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardSurface,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: borderCustom),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Lena Hai",
                                            style: TextStyle(
                                              color: textMuted,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_downward_rounded,
                                            color: greenAccent,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "₹$totalLena",
                                        style: const TextStyle(
                                          color: greenAccent,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        "Net Receivable",
                                        style: TextStyle(
                                          color: textMutedDark,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardSurface,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: borderCustom),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Dena Hai",
                                            style: TextStyle(
                                              color: textMuted,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_upward_rounded,
                                            color: redAccent,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "₹$totalDena",
                                        style: const TextStyle(
                                          color: redAccent,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        "Net Payable",
                                        style: TextStyle(
                                          color: textMutedDark,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Google Drive Cloud Backup Card
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: cardSurface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: borderCustom),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0F2618),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.cloud_done_rounded,
                                      color: greenAccent,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Google Drive Backup",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        "COMING SOON: Auto backup to Drive",
                                        style: TextStyle(
                                          color: textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    AppToast.show(
                                      context,
                                      title: "Local database sync safe hai!",
                                      type: ToastType.success,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.sync_rounded,
                                        size: 14,
                                        color: Colors.black,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "Sync",
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // DEVELOPER INFO WITH EXPANDABLE DETAILS
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardSurface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _isDevCardExpanded
                                    ? greenAccent.withValues(alpha: 0.3)
                                    : borderCustom,
                              ),
                            ),
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isDevCardExpanded = !_isDevCardExpanded;
                                    });
                                  },
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: cardSurfaceLight,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: borderCustom,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.code_rounded,
                                            color: greenAccent,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Text(
                                                  "HISAAB",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.1,
                                                  ),
                                                ),
                                                const Text(
                                                  "+",
                                                  style: TextStyle(
                                                    color: greenAccent,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 7,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF1B2A1E,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: greenAccent
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    "v4.4.1",
                                                    style: TextStyle(
                                                      color: greenAccent,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            const Text(
                                              "Developed by Sahil Sonwanshi",
                                              style: TextStyle(
                                                color: textMuted,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: cardSurfaceLight,
                                          shape: BoxShape.circle,
                                        ),
                                        child: AnimatedRotation(
                                          turns: _isDevCardExpanded ? 0.5 : 0.0,
                                          duration: const Duration(
                                            milliseconds: 250,
                                          ),
                                          child: const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: textMuted,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isDevCardExpanded) ...[
                                  const SizedBox(height: 16),
                                  const Divider(height: 1, color: borderCustom),
                                  const SizedBox(height: 14),
                                  _buildContactTile(
                                    icon: Icons.alternate_email_rounded,
                                    title: "Email Support",
                                    value: "sahilsonwanshi94@gmail.com",
                                    iconColor: const Color(0xFF38BDF8),
                                    onTap: () {
                                      Clipboard.setData(
                                        const ClipboardData(
                                          text: "sahilsonwanshi94@gmail.com",
                                        ),
                                      );
                                      AppToast.show(
                                        context,
                                        title: "Email copied!",
                                        type: ToastType.success,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cardSurfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderCustom),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded, color: textMutedDark, size: 16),
          ],
        ),
      ),
    );
  }
}

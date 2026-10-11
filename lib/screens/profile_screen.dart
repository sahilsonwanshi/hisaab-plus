import 'dart:ui';

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

  // OLED Palette
  static const Color oledBg = Color(0xFF000000);
  static const Color greenAccent = Color(0xFF00E676);
  static const Color redAccent = Color(0xFFFF5252);
  static const Color textMuted = Color(0xFF888890);
  static const Color textMutedDark = Color(0xFF55555C);
  static const Color borderCustom = Color(0xFF222226);

  bool _isDevCardExpanded = false;

  late Box<FriendModel> _friendsBox;
  late Box<Map> _personalBox;

  @override
  void initState() {
    super.initState();
    _friendsBox = Hive.box<FriendModel>('friends_box');
    _personalBox = Hive.box<Map>('personal_expenses_box');
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) setState(() {});
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'chai':
        return Icons.local_cafe_rounded;
      case 'kirana':
        return Icons.shopping_cart_rounded;
      case 'khana':
      case 'lunch':
      case 'dinner':
        return Icons.restaurant_rounded;
      case 'medical':
        return Icons.medical_services_rounded;
      case 'icecream':
      case 'treat':
        return Icons.icecream_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'chai':
        return const Color(0xFFF59E0B);
      case 'kirana':
        return const Color(0xFF06B6D4);
      case 'khana':
      case 'lunch':
      case 'dinner':
        return const Color(0xFFF97316);
      case 'medical':
        return const Color(0xFF38BDF8);
      case 'icecream':
      case 'treat':
        return const Color(0xFFFB923C);
      default:
        return const Color(0xFF10B981);
    }
  }

  void _openAddExpenseModal() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final subNoteCtrl = TextEditingController();
    String selectedCat = 'Chai';
    String selectedMode = 'UPI';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Personal Kharcha Add Karein",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Title (jaise: Chai & Nashta, Kirana)",
                  hintStyle: const TextStyle(color: textMuted, fontSize: 12.5),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.40),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  prefixText: "₹ ",
                  prefixStyle: const TextStyle(
                    color: greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: "Amount (₹)",
                  hintStyle: const TextStyle(color: textMuted, fontSize: 12.5),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.40),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subNoteCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Sub-note (jaise: Tapri par Sahil ke sath)",
                  hintStyle: const TextStyle(color: textMuted, fontSize: 12.5),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.40),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children:
                      [
                        'Chai',
                        'Kirana',
                        'Khana',
                        'Medical',
                        'Icecream',
                        'Other',
                      ].map((cat) {
                        final isSel = selectedCat == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSel,
                            selectedColor: const Color(0xFF047857),
                            backgroundColor: Colors.black.withOpacity(0.35),
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : textMuted,
                              fontSize: 11.5,
                              fontWeight: isSel
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                            onSelected: (val) =>
                                setMState(() => selectedCat = cat),
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: ['UPI', 'Cash', 'GPay', 'Credit Card'].map((mode) {
                  final isSel = selectedMode == mode;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(mode),
                      selected: isSel,
                      selectedColor: const Color(0xFF1E293B),
                      backgroundColor: Colors.black.withOpacity(0.35),
                      labelStyle: TextStyle(
                        color: isSel ? const Color(0xFF38BDF8) : textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (val) => setMState(() => selectedMode = mode),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    final amt = int.tryParse(amountCtrl.text.trim()) ?? 0;
                    if (amt <= 0 || titleCtrl.text.trim().isEmpty) return;

                    final now = DateTime.now();
                    final timeLabel =
                        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

                    _personalBox.add({
                      "title": titleCtrl.text.trim(),
                      "sub": subNoteCtrl.text.trim(),
                      "amount": amt,
                      "category": selectedCat,
                      "mode": selectedMode,
                      "time": timeLabel,
                      "timestamp": now.millisecondsSinceEpoch,
                    });

                    Navigator.pop(ctx);
                    AppToast.show(
                      context,
                      title: "Personal kharcha add ho gaya!",
                      type: ToastType.success,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Save Kharcha",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
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

  void _deletePersonalExpense(dynamic key, String title) {
    _personalBox.delete(key);
    AppToast.show(
      context,
      title: "'$title' delete ho gaya!",
      type: ToastType.error,
    );
  }

  void _confirmDeleteExpense(dynamic key, Map item) {
    final title = item["title"] ?? "Kharcha";
    final amount = item["amount"] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: redAccent, size: 22),
            SizedBox(width: 8),
            Text(
              "Kharcha Delete Karein?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "Kya aap sach mein '$title' (-₹$amount) ko delete karna chahte hain?",
          style: const TextStyle(color: textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deletePersonalExpense(key, title);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              "Delete",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: oledBg,
      body: Stack(
        children: [
          // 1. Spiderman Artwork Background Layer
          Positioned.fill(
            child: Opacity(
              opacity: 0.40,
              child: Image.asset(
                'assets/images/profile_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),

          // 2. Soft Gradient Overlay for Contrast & Readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.60),
                  ],
                ),
              ),
            ),
          ),

          // 3. Main Profile View
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: greenAccent,
              backgroundColor: const Color(0xFF1C1C1F),
              displacement: 20,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================================================
                    // 1. ALL-IN-ONE MASTER GLASS CARD
                    // =========================================================
                    ValueListenableBuilder<Box<FriendModel>>(
                      valueListenable: _friendsBox.listenable(),
                      builder: (context, box, _) {
                        int totalLena = 0;
                        int totalDena = 0;

                        for (var friend in box.values) {
                          if (friend.type == 'lena' && friend.balance > 0) {
                            totalLena += friend.balance;
                          } else if (friend.type == 'dena' &&
                              friend.balance > 0) {
                            totalDena += friend.balance;
                          }
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(
                              0.38,
                            ), // Translucent Glass
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: Column(
                            children: [
                              // (A) Profile / Guest Header
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.10),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.15),
                                        ),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Guest #8941",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            "Offline Ledger Mode",
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Divider(
                                height: 1,
                                color: Colors.white.withOpacity(0.08),
                              ),

                              // (B) Lena Hai & Dena Hai Compact Cards
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    // Lena Hai
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.35),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.08,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Lena Hai",
                                                  style: TextStyle(
                                                    color: Colors.white60,
                                                    fontSize: 11.5,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_downward_rounded,
                                                  color: greenAccent,
                                                  size: 14,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "₹$totalLena",
                                              style: const TextStyle(
                                                color: greenAccent,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              "Net Receivable",
                                              style: TextStyle(
                                                color: textMutedDark,
                                                fontSize: 9.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Dena Hai
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.35),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.08,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Dena Hai",
                                                  style: TextStyle(
                                                    color: Colors.white60,
                                                    fontSize: 11.5,
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_upward_rounded,
                                                  color: redAccent,
                                                  size: 14,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "₹$totalDena",
                                              style: const TextStyle(
                                                color: redAccent,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              "Net Payable",
                                              style: TextStyle(
                                                color: textMutedDark,
                                                fontSize: 9.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // (C) Google Drive Backup Row
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  0,
                                  14,
                                  14,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.35),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F2618)
                                              .withOpacity(0.8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.cloud_done_rounded,
                                            color: greenAccent,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Google Drive Backup",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(height: 1),
                                            Text(
                                              "Auto backup to Drive",
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontSize: 10.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          AppToast.show(
                                            context,
                                            title:
                                                "Local database sync safe hai!",
                                            type: ToastType.success,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.sync_rounded,
                                          size: 13,
                                          color: Colors.black,
                                        ),
                                        label: const Text(
                                          "Sync",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          elevation: 0,
                                          minimumSize: Size.zero,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Divider(
                                height: 1,
                                color: Colors.white.withOpacity(0.08),
                              ),

                              // (D) Developer Branding Row (Expandable inside Master Card)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 11,
                                ),
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isDevCardExpanded =
                                              !_isDevCardExpanded;
                                        });
                                      },
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.code_rounded,
                                            color: greenAccent,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            "HISAAB+",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1B2A1E),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              "v4.4.2",
                                              style: TextStyle(
                                                color: greenAccent,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          const Text(
                                            "by Sahil Sonwanshi",
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          AnimatedRotation(
                                            turns: _isDevCardExpanded
                                                ? 0.5
                                                : 0.0,
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            child: const Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: Colors.white60,
                                              size: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_isDevCardExpanded) ...[
                                      const SizedBox(height: 12),
                                      _buildContactTile(
                                        icon: Icons.alternate_email_rounded,
                                        title: "Email Support",
                                        value: "sahilsonwanshi94@gmail.com",
                                        iconColor: const Color(0xFF38BDF8),
                                        onTap: () {
                                          Clipboard.setData(
                                            const ClipboardData(
                                              text:
                                                  "sahilsonwanshi94@gmail.com",
                                            ),
                                          );
                                          AppToast.show(
                                            context,
                                            title: "Email copied!",
                                            type: ToastType.success,
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // =========================================================
                    // 2. KHUD KA KHARCHA GLASS CARD
                    // =========================================================
                    ValueListenableBuilder<Box<Map>>(
                      valueListenable: _personalBox.listenable(),
                      builder: (context, pBox, _) {
                        final keys = pBox.keys.toList();
                        final items = pBox.values.toList();
                        final int totalKharcha = items.fold(
                          0,
                          (sum, e) =>
                              sum + ((e["amount"] as num?)?.toInt() ?? 0),
                        );

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(
                              0.38,
                            ), // Translucent Glass
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header + Button
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "KHUD KA KHARCHA",
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "₹$totalKharcha.00",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _openAddExpenseModal,
                                    icon: const Icon(
                                      Icons.add,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      "Kharcha",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black.withOpacity(
                                        0.35,
                                      ),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: Colors.white.withOpacity(0.15),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              if (items.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      "Abhi tak koi personal kharcha nahi hai.\n'+ Kharcha' par click karke add karein!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: items.length,
                                  itemBuilder: (ctx, idx) {
                                    final rawKey = keys[idx];
                                    final item = items[idx];
                                    final bool isLast = idx == items.length - 1;

                                    final cat =
                                        item["category"]?.toString() ?? "Chai";
                                    final catColor = _getCategoryColor(cat);
                                    final catIcon = _getCategoryIcon(cat);

                                    return IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          SizedBox(
                                            width: 44,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 14,
                                              ),
                                              child: Text(
                                                item["time"] ?? "00:00",
                                                style: const TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Column(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: catColor.withOpacity(
                                                    0.20,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: catColor.withOpacity(
                                                      0.65,
                                                    ),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Icon(
                                                  catIcon,
                                                  size: 14,
                                                  color: catColor,
                                                ),
                                              ),
                                              if (!isLast)
                                                Expanded(
                                                  child: Container(
                                                    width: 1.5,
                                                    color: Colors.white
                                                        .withOpacity(0.12),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: GestureDetector(
                                              onLongPress: () {
                                                _confirmDeleteExpense(
                                                  rawKey,
                                                  item,
                                                );
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.35),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.08),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            item["title"] ??
                                                                "Kharcha",
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize:
                                                                      13.5,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Text(
                                                            item["sub"]?.isNotEmpty ==
                                                                    true
                                                                ? item["sub"]
                                                                : cat,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white60,
                                                                  fontSize: 11,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                        Text(
                                                          "-₹${item['amount']}",
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    redAccent,
                                                                fontSize: 13.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          item["mode"] ?? "UPI",
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white38,
                                                                fontSize: 10,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded, color: textMutedDark, size: 14),
          ],
        ),
      ),
    );
  }
}

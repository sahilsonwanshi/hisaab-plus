import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/friend_model.dart';
import '../widgets/custom_toast.dart';
import '../widgets/smooth_route.dart';
import 'entry_form_screen.dart';
import 'hisab_chat.dart';

class DostKhataScreen extends StatefulWidget {
  const DostKhataScreen({super.key});

  @override
  State<DostKhataScreen> createState() => _DostKhataScreenState();
}

class _DostKhataScreenState extends State<DostKhataScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _activeFilter = "Sabhi";
  String _searchQuery = "";

  static const Color oledBg = Color(0xFF000000);
  static const Color cardSurface = Color(0xFF131315);
  static const Color cardSurfaceLight = Color(0xFF1C1C1F);
  static const Color cardSurfaceElevated = Color(0xFF1E1E22);
  static const Color greenAccent = Color(0xFF00E676);
  static const Color greenPillBg = Color(0xFF0B291A);
  static const Color redAccent = Color(0xFFFF5252);
  static const Color redPillBg = Color(0xFF2E1215);
  static const Color textMuted = Color(0xFF888890);
  static const Color textMutedDark = Color(0xFF55555C);

  static const List<String> availableTags = [
    'College',
    'Roommate',
    'Office',
    'Business',
    'Personal',
  ];

  late Box<FriendModel> _friendsBox;

  @override
  void initState() {
    super.initState();
    _friendsBox = Hive.box<FriendModel>('friends_box');
  }

  void _openChat(dynamic key, FriendModel dost) {
    Navigator.push(
      context,
      SmoothOledRoute(
        page: HisabChatScreen(
          friendKey: key,
          friendName: dost.name,
          netAmount: dost.balance.toString(),
          isLena: dost.type == 'lena',
        ),
      ),
    );
  }

  void _openNayaKhata() {
    Navigator.push(
      context,
      SmoothOledRoute(
        page: EntryFormView(
          entryType: 1,
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // Khata list me dost par long-press karne par direct delete / clear modal
  void _showKhataOptionsBottomSheet(dynamic key, FriendModel dost) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: greenAccent,
                ),
                title: Text(
                  dost.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "₹${dost.balance} net • ${dost.history.length} transactions",
                  style: const TextStyle(color: textMuted, fontSize: 12),
                ),
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(
                  Icons.cleaning_services_rounded,
                  color: Colors.amber,
                ),
                title: const Text(
                  "Clear Chat History",
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  "Sare statement delete karein aur balance ₹0 karein",
                  style: TextStyle(color: textMuted, fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(bCtx);
                  setState(() {
                    dost.history.clear();
                    dost.balance = 0;
                    dost.type = "settled";
                    dost.lastMessage = "Chat cleared";
                    dost.lastDate = "Aaj";
                  });
                  dost.save();
                  AppToast.show(
                    context,
                    title: "${dost.name} ki chat clear ho gayi!",
                    type: ToastType.warning,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: redAccent,
                ),
                title: const Text(
                  "Delete Pura Khata",
                  style: TextStyle(
                    color: redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Dost aur record list se permanent hatayein",
                  style: TextStyle(color: textMuted, fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(bCtx);
                  dost.delete();
                  AppToast.show(
                    context,
                    title: "${dost.name} ka khata delete ho gaya!",
                    type: ToastType.error,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
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
            // 1. FIXED STICKY TOP BAR
            // =========================================================
            Container(
              color: oledBg,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 14, left: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "HISAAB",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(width: 3),
                        Text(
                          "+",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: cardSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val.trim()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                              ),
                              decoration: const InputDecoration(
                                hintText: "Search dost, khata...",
                                hintStyle: TextStyle(
                                  color: textMuted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              "|",
                              style: TextStyle(
                                color: textMutedDark,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // =========================================================
            // 2. SCROLLABLE BODY WITH REFRESH INDICATOR
            // =========================================================
            Expanded(
              child: ValueListenableBuilder<Box<FriendModel>>(
                valueListenable: _friendsBox.listenable(),
                builder: (context, box, _) {
                  final allFriends = box.values.toList();
                  final allKeys = box.keys.toList();

                  int totalLena = 0;
                  int totalDena = 0;
                  int lenaCount = 0;
                  int denaCount = 0;

                  for (var f in allFriends) {
                    if (f.type == 'lena' && f.balance > 0) {
                      totalLena += f.balance;
                      lenaCount++;
                    } else if (f.type == 'dena' && f.balance > 0) {
                      totalDena += f.balance;
                      denaCount++;
                    }
                  }

                  final int netBalance = totalLena - totalDena;
                  final int combinedTotal = totalLena + totalDena;
                  final double greenFrac = combinedTotal == 0
                      ? 0.5
                      : (totalLena / combinedTotal);
                  final double redFrac = combinedTotal == 0
                      ? 0.5
                      : (totalDena / combinedTotal);

                  // Filter Chips
                  final List<Map<String, dynamic>> filterChips = [
                    {
                      "id": "Sabhi",
                      "label": "Sabhi",
                      "count": allFriends.length,
                      "color": null,
                      "isTag": false,
                    },
                    {
                      "id": "Lena Hai",
                      "label": "Lena Hai",
                      "count": lenaCount,
                      "color": greenAccent,
                      "isTag": false,
                    },
                    {
                      "id": "Dena Hai",
                      "label": "Dena Hai",
                      "count": denaCount,
                      "color": redAccent,
                      "isTag": false,
                    },
                  ];

                  for (var tag in availableTags) {
                    final count = allFriends
                        .where(
                          (d) =>
                              d.desc.toLowerCase().contains(tag.toLowerCase()),
                        )
                        .length;
                    if (count > 0) {
                      filterChips.add({
                        "id": tag,
                        "label": tag,
                        "count": count,
                        "color": const Color(0xFF38BDF8),
                        "isTag": true,
                      });
                    }
                  }

                  final List<MapEntry<dynamic, FriendModel>> filteredList = [];
                  for (int i = 0; i < allFriends.length; i++) {
                    final friend = allFriends[i];
                    final key = allKeys[i];

                    final nameMatches =
                        friend.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        friend.desc.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        );
                    if (!nameMatches) continue;

                    if (_activeFilter == "Lena Hai" &&
                        (friend.type != 'lena' || friend.balance <= 0)) {
                      continue;
                    }
                    if (_activeFilter == "Dena Hai" &&
                        (friend.type != 'dena' || friend.balance <= 0)) {
                      continue;
                    }

                    if (_activeFilter != "Sabhi" &&
                        _activeFilter != "Lena Hai" &&
                        _activeFilter != "Dena Hai") {
                      if (!friend.desc.toLowerCase().contains(
                        _activeFilter.toLowerCase(),
                      )) {
                        continue;
                      }
                    }

                    filteredList.add(MapEntry(key, friend));
                  }

                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: greenAccent,
                    backgroundColor: cardSurfaceElevated,
                    displacement: 20,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Net Ledger Ring Card
                          Container(
                            padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                            decoration: BoxDecoration(
                              color: cardSurface,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.04),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF151518),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.04,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CustomPaint(
                                            size: const Size(96, 96),
                                            painter: _NetRadialChartPainter(
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
                                                  color: Color(0xFF888890),
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "${netBalance >= 0 ? '+₹' : '-₹'}${netBalance.abs()}",
                                                style: TextStyle(
                                                  color: netBalance >= 0
                                                      ? greenAccent
                                                      : redAccent,
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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: greenPillBg,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: redPillBg,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                                const SizedBox(height: 22),
                                Row(
                                  children: [
                                    Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cardSurfaceLight,
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.credit_card_outlined,
                                            color: textMuted,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "${allFriends.length} Dost",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    InkWell(
                                      onTap: _openNayaKhata,
                                      borderRadius: BorderRadius.circular(24),
                                      child: Container(
                                        height: 44,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.person_add_alt_1_rounded,
                                              size: 16,
                                              color: Colors.black,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              "+ Naya Khata",
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
                          ),

                          const SizedBox(height: 18),

                          // Category Filter Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: filterChips.map((chip) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildFilterChip(
                                    id: chip["id"] as String,
                                    label: chip["label"] as String,
                                    count: chip["count"] as int,
                                    dotColor: chip["color"] as Color?,
                                    isTag: chip["isTag"] as bool,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Section Title
                          const Text(
                            "Active Dost",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Active Dost Ledger List
                          if (filteredList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  "Koi dost nahi mila",
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...filteredList.map((entry) {
                              final key = entry.key;
                              final dost = entry.value;
                              final isLena = dost.type == 'lena';
                              final isSettled =
                                  dost.balance == 0 || dost.type == 'settled';

                              String status;
                              if (isSettled) {
                                status = "₹0 chukta";
                              } else if (isLena) {
                                status = "+₹${dost.balance} lena";
                              } else {
                                status = "-₹${dost.balance} dena";
                              }

                              return _buildDostTile(
                                initials: _getInitials(dost.name),
                                name: dost.name,
                                desc: dost.desc.isNotEmpty
                                    ? dost.desc
                                    : "Khata",
                                time: dost.lastDate.isNotEmpty
                                    ? dost.lastDate
                                    : "Aaj",
                                amount: "${dost.balance}.00",
                                status: status,
                                isLena: isLena,
                                isSettled: isSettled,
                                onTap: () => _openChat(key, dost),
                                onLongPress: () =>
                                    _showKhataOptionsBottomSheet(key, dost),
                              );
                            }),
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

  Widget _buildFilterChip({
    required String id,
    required String label,
    required int count,
    required Color? dotColor,
    required bool isTag,
  }) {
    final bool isSelected = _activeFilter == id;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isTag ? const Color(0xFF0369A1) : const Color(0xFF222228))
              : (isTag ? const Color(0xFF0C1929) : cardSurface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isTag ? const Color(0xFF38BDF8) : Colors.white24)
                : (isTag
                      ? const Color(0xFF0284C7).withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.04)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTag) ...[
              Icon(
                Icons.tag_rounded,
                size: 12,
                color: isSelected ? Colors.white : const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 4),
            ] else if (dotColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ] else if (isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isTag ? const Color(0xFF38BDF8) : textMuted),
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "$count",
              style: TextStyle(
                color: isSelected ? Colors.white70 : textMutedDark,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDostTile({
    required String initials,
    required String name,
    required String desc,
    required String time,
    required String amount,
    required String status,
    required bool isLena,
    required bool isSettled,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    final Color badgeColor = isSettled
        ? textMuted
        : (isLena ? greenAccent : redAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1E1E22),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "$desc • $time",
                        style: const TextStyle(color: textMuted, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹$amount",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NetRadialChartPainter extends CustomPainter {
  final double greenFraction;
  final double redFraction;

  _NetRadialChartPainter({
    required this.greenFraction,
    required this.redFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;
    const strokeWidth = 8.0;

    final trackPaint = Paint()
      ..color = const Color(0xFF1B1B20)
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
  bool shouldRepaint(covariant _NetRadialChartPainter oldDelegate) =>
      oldDelegate.greenFraction != greenFraction ||
      oldDelegate.redFraction != redFraction;
}

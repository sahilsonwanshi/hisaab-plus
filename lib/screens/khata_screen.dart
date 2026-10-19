import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/friend_model.dart';
import '../widgets/custom_toast.dart';
import '../widgets/smooth_route.dart';
import '../theme/app_colors.dart';
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

  void _showKhataOptionsBottomSheet(dynamic key, FriendModel dost) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: colors.border),
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
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: colors.isDark ? colors.greenAccent : colors.greenText,
                ),
                title: Text(
                  dost.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "₹${dost.balance} net • ${dost.history.length} transactions",
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              ),
              Divider(color: colors.border),
              ListTile(
                leading: const Icon(
                  Icons.cleaning_services_rounded,
                  color: Colors.amber,
                ),
                title: Text(
                  "Clear Chat History",
                  style: TextStyle(color: colors.textPrimary),
                ),
                subtitle: Text(
                  "Sare statement delete karein aur balance ₹0 karein",
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
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
                leading: Icon(
                  Icons.delete_forever_rounded,
                  color: colors.redText,
                ),
                title: Text(
                  "Delete Pura Khata",
                  style: TextStyle(
                    color: colors.redText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Dost aur record list se permanent hatayein",
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
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
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        children: [
          if (colors.isDark) ...[
            // 1. Spiderman Background Image Layer (Dark Mode Only)
            Positioned.fill(
              child: Opacity(
                opacity: 0.40,
                child: Image.asset(
                  'assets/images/khata_screen_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),

            // 2. Ambient Gradient Tint for Contrast
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.30),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Fixed Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 14, left: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "HISAAB",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "+",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: colors.isDark ? colors.greenAccent : colors.greenText,
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
                            color: colors.isDark
                                ? Colors.black.withValues(alpha: 0.38)
                                : colors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: colors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: colors.textMuted,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  onChanged: (val) =>
                                      setState(() => _searchQuery = val.trim()),
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 12.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Search dost, khata...",
                                    hintStyle: TextStyle(
                                      color: colors.textMuted,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _searchQuery = ""),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: colors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Body
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
                          "color": colors.isDark ? colors.greenAccent : colors.greenText,
                          "isTag": false,
                        },
                        {
                          "id": "Dena Hai",
                          "label": "Dena Hai",
                          "count": denaCount,
                          "color": colors.isDark ? colors.redAccent : colors.redText,
                          "isTag": false,
                        },
                      ];

                      for (var tag in availableTags) {
                        final count = allFriends
                            .where(
                              (d) => d.desc.toLowerCase().contains(
                                tag.toLowerCase(),
                              ),
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

                      final List<MapEntry<dynamic, FriendModel>> filteredList =
                          [];
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
                        color: colors.isDark ? colors.greenAccent : colors.greenText,
                        backgroundColor: colors.surface,
                        displacement: 20,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Glassy Net Ledger Card
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  20,
                                  18,
                                  18,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: colors.border,
                                  ),
                                  boxShadow: colors.isDark ? [] : [colors.cardShadow],
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
                                            color: colors.surfaceSecondary,
                                            border: Border.all(
                                              color: colors.border,
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
                                                  colors: colors,
                                                ),
                                              ),
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "NET",
                                                    style: TextStyle(
                                                      color: colors.textMuted,
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 0.8,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "${netBalance >= 0 ? '+₹' : '-₹'}${netBalance.abs()}",
                                                    style: TextStyle(
                                                      color: netBalance >= 0
                                                          ? (colors.isDark ? colors.greenAccent : colors.greenText)
                                                          : (colors.isDark ? colors.redAccent : colors.redText),
                                                      fontSize: 15.5,
                                                      fontWeight:
                                                          FontWeight.w900,
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
                                                    decoration:
                                                        BoxDecoration(
                                                          color: colors.isDark ? colors.greenAccent : colors.greenText,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "Lena Hai",
                                                    style: TextStyle(
                                                      color: colors.textMuted,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                                      color: colors.greenPillBg,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      "$lenaCount log",
                                                      style: TextStyle(
                                                        color: colors.greenText,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                "₹$totalLena.00",
                                                style: TextStyle(
                                                  color: colors.isDark ? colors.greenAccent : colors.greenText,
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
                                                    decoration:
                                                        BoxDecoration(
                                                          color: colors.isDark ? colors.redAccent : colors.redText,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "Dena Hai",
                                                    style: TextStyle(
                                                      color: colors.textMuted,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                                      color: colors.redPillBg,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      "$denaCount log",
                                                      style: TextStyle(
                                                        color: colors.redText,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                "₹$totalDena.00",
                                                style: TextStyle(
                                                  color: colors.isDark ? colors.redAccent : colors.redText,
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
                                    Row(
                                      children: [
                                        Container(
                                          height: 42,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.surfaceSecondary,
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                            border: Border.all(
                                              color: colors.border,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.credit_card_outlined,
                                                color: colors.textMuted,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "${allFriends.length} Dost",
                                                style: TextStyle(
                                                  color: colors.textPrimary,
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
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          child: Container(
                                            height: 42,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colors.isDark ? Colors.white : const Color(0xFF0F172A),
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .person_add_alt_1_rounded,
                                                  size: 16,
                                                  color: colors.isDark ? Colors.black : Colors.white,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  "+ Naya Khata",
                                                  style: TextStyle(
                                                    color: colors.isDark ? Colors.black : Colors.white,
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

                              // Filter Pills
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: filterChips.map((chip) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _buildFilterChip(
                                        colors: colors,
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

                              const SizedBox(height: 22),

                              Text(
                                "Active Dost",
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 12),

                              if (filteredList.isEmpty)
                                allFriends.isEmpty
                                    ? Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 24,
                                        ),
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: colors.surface,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: colors.border,
                                          ),
                                          boxShadow: colors.isDark ? [] : [colors.cardShadow],
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: colors.greenPillBg,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.people_outline_rounded,
                                                color: colors.greenText,
                                                size: 32,
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            Text(
                                              "Aapka Khata Khali Hai",
                                              style: TextStyle(
                                                color: colors.textPrimary,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "Dosto ke sath len-den ka hisaab clear aur safe rakhne ke liye pehla dost jodein.",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: colors.textMuted,
                                                fontSize: 12.5,
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 18),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: colors.isDark ? colors.greenAccent : colors.greenText,
                                                foregroundColor: colors.isDark ? Colors.black : Colors.white,
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                              ),
                                              icon: const Icon(
                                                Icons.person_add_alt_1_rounded,
                                                size: 18,
                                              ),
                                              label: const Text(
                                                "Pehla Dost Jodein",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              onPressed: _openNayaKhata,
                                            ),
                                          ],
                                        ),
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 40,
                                        ),
                                        child: Center(
                                          child: Text(
                                            _searchQuery.isNotEmpty
                                                ? "'$_searchQuery' naam ka koi dost nahi mila"
                                                : "Koi dost nahi mila",
                                            style: TextStyle(
                                              color: colors.textMuted,
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
                                      dost.balance == 0 ||
                                      dost.type == 'settled';

                                  String status;
                                  if (isSettled) {
                                    status = "₹0 chukta";
                                  } else if (isLena) {
                                    status = "+₹${dost.balance} lena";
                                  } else {
                                    status = "-₹${dost.balance} dena";
                                  }

                                  return _buildDostTile(
                                    colors: colors,
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
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required AppColors colors,
    required String id,
    required String label,
    required int count,
    required Color? dotColor,
    required bool isTag,
  }) {
    final bool isSelected = _activeFilter == id;
    final Color selectedBg = colors.isDark ? Colors.white : const Color(0xFF0F172A);
    final Color selectedFg = colors.isDark ? Colors.black : Colors.white;

    Color unselectedBg;
    BorderSide unselectedBorder;
    Color unselectedFg;

    if (isTag) {
      unselectedBg = colors.isDark
          ? const Color(0xFF0C1929).withValues(alpha: 0.65)
          : const Color(0xFFE0F2FE);
      unselectedBorder = BorderSide(
        color: colors.isDark
            ? const Color(0xFF0284C7).withValues(alpha: 0.4)
            : const Color(0xFFBAE6FD),
      );
      unselectedFg = colors.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    } else {
      unselectedBg = colors.surfaceSecondary;
      unselectedBorder = BorderSide(color: colors.border);
      unselectedFg = colors.textMuted;
    }

    return GestureDetector(
      onTap: () => setState(() => _activeFilter = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.fromBorderSide(
            isSelected ? BorderSide(color: selectedBg) : unselectedBorder,
          ),
          boxShadow: (!isSelected && !colors.isDark) ? [colors.cardShadow] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTag) ...[
              Icon(
                Icons.tag_rounded,
                size: 12,
                color: isSelected ? selectedFg : unselectedFg,
              ),
              const SizedBox(width: 4),
            ] else if (dotColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? selectedFg : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ] else if (isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selectedFg,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedFg : unselectedFg,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "$count",
              style: TextStyle(
                color: isSelected
                    ? selectedFg.withValues(alpha: 0.8)
                    : colors.textMuted,
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
    required AppColors colors,
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
        ? colors.textMuted
        : (isLena
            ? (colors.isDark ? colors.greenAccent : colors.greenText)
            : (colors.isDark ? colors.redAccent : colors.redText));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: colors.isDark ? [] : [colors.cardShadow],
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surfaceSecondary,
                    border: Border.all(color: colors.border),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: colors.textPrimary,
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
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "$desc • $time",
                        style: TextStyle(color: colors.textSecondary, fontSize: 11),
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
                      style: TextStyle(
                        color: colors.textPrimary,
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
  final AppColors colors;

  _NetRadialChartPainter({
    required this.greenFraction,
    required this.redFraction,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;
    const strokeWidth = 8.0;

    final trackPaint = Paint()
      ..color = colors.isDark
          ? Colors.white.withValues(alpha: 0.08)
          : colors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, trackPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);

    final greenPaint = Paint()
      ..color = colors.isDark ? colors.greenAccent : colors.greenText
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    final redPaint = Paint()
      ..color = colors.isDark ? colors.redAccent : colors.redText
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
      oldDelegate.redFraction != redFraction ||
      oldDelegate.colors != colors;
}

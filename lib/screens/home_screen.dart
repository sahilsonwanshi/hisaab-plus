import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/friend_model.dart';
import '../models/transaction_model.dart';
import '../widgets/custom_toast.dart';
import '../widgets/smooth_route.dart';
import 'entry_form_screen.dart';
import 'hisab_chat.dart';
import 'khata_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onTabChange;
  final VoidCallback? onOpenEntry;

  const HomeScreen({super.key, this.onTabChange, this.onOpenEntry});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const Color oledBg = Color(0xFF000000);
  static const Color cardSurface = Color(0xFF131315);
  static const Color cardSurfaceElevated = Color(0xFF1E1E22);
  static const Color greenAccent = Color(0xFF00E676);
  static const Color greenPillBg = Color(0xFF0B291A);
  static const Color redAccent = Color(0xFFFF5252);
  static const Color redPillBg = Color(0xFF2E1215);
  static const Color textMuted = Color(0xFF888890);
  static const Color textMutedDark = Color(0xFF55555C);
  static const Color borderCustom = Color(0xFF242429);

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  late Box<TransactionModel> _transBox;
  late Box<FriendModel> _friendsBox;

  late DateTime _selectedDate;
  bool _isAllDateSelected = false;

  @override
  void initState() {
    super.initState();
    _transBox = Hive.box<TransactionModel>('transactions_box');
    _friendsBox = Hive.box<FriendModel>('friends_box');
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDisplayDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final dateOnly = DateTime(dt.year, dt.month, dt.day);
    if (dateOnly == today) {
      return "Today (${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year})";
    } else if (dateOnly == yesterday) {
      return "Yesterday (${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year})";
    }
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  // BUG 4 FIX: friendKey lookup & live sync
  void _openChat(String name, int amount, bool isLena) {
    dynamic matchedKey;
    for (var entry in _friendsBox.toMap().entries) {
      if (entry.value.name.trim().toLowerCase() == name.trim().toLowerCase()) {
        matchedKey = entry.key;
        break;
      }
    }

    Navigator.push(
      context,
      SmoothOledRoute(
        page: HisabChatScreen(
          friendKey: matchedKey,
          friendName: name,
          netAmount: amount.toString(),
          isLena: isLena,
        ),
      ),
    );
  }

  void _openKhata() {
    if (widget.onTabChange != null) {
      widget.onTabChange!(1);
    } else {
      Navigator.push(context, SmoothOledRoute(page: const DostKhataScreen()));
    }
  }

  void _openNayaKharcha() {
    if (widget.onOpenEntry != null) {
      widget.onOpenEntry!();
    } else {
      Navigator.push(
        context,
        SmoothOledRoute(
          page: EntryFormView(
            entryType: 0,
            onClose: () => Navigator.pop(context),
          ),
        ),
      );
    }
  }

  void _deleteTransaction(TransactionModel tx) {
    final title = tx.title;
    tx.delete();
    AppToast.show(
      context,
      title: "'$title' delete ho gaya!",
      type: ToastType.error,
    );
  }

  void _showTransactionActionSheet(
    TransactionModel tx,
    bool isLena,
    bool isKharcha,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: borderCustom),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "₹${tx.amount} • ${tx.subtitle}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: cardSurfaceElevated,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderCustom),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: textMuted,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: borderCustom),
                const SizedBox(height: 10),
                if (!isKharcha)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: greenPillBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.open_in_new_rounded,
                        color: greenAccent,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      "Open Hisaab Chat",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      "Is dost ki complete chat & ledger kholein",
                      style: TextStyle(color: textMuted, fontSize: 11),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openChat(tx.title, tx.amount, isLena);
                    },
                  ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: redPillBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: redAccent,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    "Delete Record",
                    style: TextStyle(
                      color: redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    "Is hisaab ko local ledger se hata dein",
                    style: TextStyle(color: textMuted, fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteTransaction(tx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return "Aaj • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    }
    return "${dt.day}/${dt.month}/${dt.year}";
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
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bool isFutureDisabled = _isSameDay(_selectedDate, today);

    return Scaffold(
      backgroundColor: oledBg,
      body: SafeArea(
        child: Column(
          children: [
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val.trim();
                                });
                              },
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                              ),
                              decoration: InputDecoration(
                                hintText: "Search dost, kharcha...",
                                hintStyle: const TextStyle(
                                  color: textMuted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () {
                                          _searchCtrl.clear();
                                          setState(() => _searchQuery = "");
                                        },
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: textMuted,
                                        ),
                                      )
                                    : null,
                                suffixIconConstraints: const BoxConstraints(
                                  minHeight: 18,
                                  minWidth: 18,
                                ),
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
                          Theme(
                            data: Theme.of(context)
                                .copyWith(cardColor: const Color(0xFF1E1E22)),
                            child: PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                size: 18,
                                color: textMuted,
                              ),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              onSelected: (value) {
                                if (value == "settings") {
                                  AppToast.show(
                                    context,
                                    title: "Settings jald aa raha hai!",
                                    type: ToastType.info,
                                  );
                                } else if (value == "sync") {
                                  AppToast.show(
                                    context,
                                    title: "Data device memory me safe hai!",
                                    type: ToastType.success,
                                  );
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem(
                                  value: "sync",
                                  height: 38,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.sync_rounded,
                                        size: 16,
                                        color: greenAccent,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "Sync State",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: "settings",
                                  height: 38,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.settings_outlined,
                                        size: 16,
                                        color: textMuted,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "Settings",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
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
                      ValueListenableBuilder(
                        valueListenable: _friendsBox.listenable(),
                        builder: (context, Box<FriendModel> fBox, _) {
                          int totalLena = 0;
                          int totalDena = 0;

                          for (var friend in fBox.values) {
                            if (friend.type == 'lena') {
                              totalLena += friend.balance;
                            } else if (friend.type == 'dena') {
                              totalDena += friend.balance;
                            }
                          }

                          int dateLena = 0;
                          int dateDena = 0;

                          for (var tx in _transBox.values) {
                            if (_isAllDateSelected ||
                                _isSameDay(tx.date, _selectedDate)) {
                              if (tx.type == 'lena') {
                                dateLena += tx.amount;
                              } else if (tx.type == 'dena') {
                                dateDena += tx.amount;
                              }
                            }
                          }

                          return Container(
                            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Lena Hai (Receivable)",
                                      style: TextStyle(
                                        color: textMuted,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "₹$totalLena",
                                          style: const TextStyle(
                                            color: greenAccent,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: greenPillBg,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            "+₹$dateLena",
                                            style: const TextStyle(
                                              color: greenAccent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Dena Hai (Payable)",
                                      style: TextStyle(
                                        color: textMuted,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "₹$totalDena",
                                          style: const TextStyle(
                                            color: redAccent,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: redPillBg,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            "-₹$dateDena",
                                            style: const TextStyle(
                                              color: redAccent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: _openKhata,
                                        borderRadius: BorderRadius.circular(26),
                                        child: Container(
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: cardSurfaceElevated,
                                            borderRadius: BorderRadius.circular(
                                              26,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Khata",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              Icon(
                                                Icons.arrow_outward_rounded,
                                                size: 14,
                                                color: Colors.white70,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: InkWell(
                                        onTap: _openNayaKharcha,
                                        borderRadius: BorderRadius.circular(26),
                                        child: Container(
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              26,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Naya Kharcha",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(
                                                Icons.add_rounded,
                                                size: 18,
                                                color: Colors.black,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "Hisaab History",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: cardSurfaceElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderCustom),
                                ),
                                child: Text(
                                  _isAllDateSelected
                                      ? "All History"
                                      : "Daily View",
                                  style: const TextStyle(
                                    color: greenAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: _openKhata,
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    "All Khata",
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<Box<TransactionModel>>(
                        valueListenable: _transBox.listenable(),
                        builder: (context, box, _) {
                          final allTx = box.values.toList().reversed.toList();

                          final filtered = allTx.where((tx) {
                            if (!_isAllDateSelected &&
                                !_isSameDay(tx.date, _selectedDate)) {
                              return false;
                            }
                            if (_searchQuery.isEmpty) return true;
                            final q = _searchQuery.toLowerCase();
                            return tx.title.toLowerCase().contains(q) ||
                                tx.subtitle.toLowerCase().contains(q);
                          }).toList();

                          return Column(
                            children: [
                              if (filtered.isEmpty)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 36,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardSurface,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.04,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.event_note_rounded,
                                        size: 30,
                                        color: textMutedDark,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _isAllDateSelected
                                            ? "Abhi tak koi entry nahi hai"
                                            : "Is din ka koi hisaab nahi hai",
                                        style: const TextStyle(
                                          color: textMuted,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final tx = filtered[index];
                                    final isLena = tx.type == 'lena';
                                    final isKharcha = tx.type == 'kharcha';

                                    String status;
                                    Color statusColor;

                                    if (isKharcha) {
                                      status = "Kharcha";
                                      statusColor = textMuted;
                                    } else if (isLena) {
                                      status = "+₹${tx.amount} lena";
                                      statusColor = greenAccent;
                                    } else {
                                      status = "-₹${tx.amount} dena";
                                      statusColor = redAccent;
                                    }

                                    return _buildHistoryTile(
                                      initials: _getInitials(tx.title),
                                      name: tx.title,
                                      timeOrDesc:
                                          "${_formatDate(tx.date)} • ${tx.subtitle}",
                                      amount: "₹${tx.amount}",
                                      status: status,
                                      statusColor: statusColor,
                                      onTap: () {
                                        if (!isKharcha) {
                                          _openChat(
                                            tx.title,
                                            tx.amount,
                                            isLena,
                                          );
                                        }
                                      },
                                      onLongPress: () {
                                        _showTransactionActionSheet(
                                          tx,
                                          isLena,
                                          isKharcha,
                                        );
                                      },
                                    );
                                  },
                                ),
                              const SizedBox(height: 10),
                              _buildBottomDateController(isFutureDisabled),
                            ],
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
      ),
    );
  }

  Widget _buildBottomDateController(bool isFutureDisabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderCustom),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isAllDateSelected = false;
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardSurfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCustom),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: greenAccent,
                        onPrimary: Colors.black,
                        surface: cardSurfaceElevated,
                        onSurface: Colors.white,
                      ),
                      dialogBackgroundColor: cardSurface,
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _isAllDateSelected = false;
                  _selectedDate = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                  );
                });
              }
            },
            child: Column(
              children: [
                Text(
                  _isAllDateSelected
                      ? "Showing All Records"
                      : _formatDisplayDate(_selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Tap to choose calendar date",
                  style: TextStyle(color: textMutedDark, fontSize: 10),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAllDateSelected = !_isAllDateSelected;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isAllDateSelected
                        ? greenPillBg
                        : cardSurfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isAllDateSelected
                          ? greenAccent.withValues(alpha: 0.6)
                          : borderCustom,
                    ),
                  ),
                  child: Text(
                    "All",
                    style: TextStyle(
                      color: _isAllDateSelected ? greenAccent : textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: isFutureDisabled || _isAllDateSelected
                    ? null
                    : () {
                        setState(() {
                          _selectedDate = _selectedDate.add(
                            const Duration(days: 1),
                          );
                        });
                      },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isFutureDisabled || _isAllDateSelected
                        ? Colors.transparent
                        : cardSurfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFutureDisabled || _isAllDateSelected
                          ? Colors.transparent
                          : borderCustom,
                    ),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: isFutureDisabled || _isAllDateSelected
                        ? textMutedDark
                        : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile({
    required String initials,
    required String name,
    required String timeOrDesc,
    required String amount,
    required String status,
    required Color statusColor,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
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
                  width: 42,
                  height: 42,
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
                        fontSize: 12,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        timeOrDesc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
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
                        color: statusColor,
                        fontSize: 10,
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

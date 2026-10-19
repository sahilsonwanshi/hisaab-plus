
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/friend_model.dart';
import '../models/transaction_model.dart';
import '../widgets/custom_toast.dart';
import '../widgets/smooth_route.dart';
import 'entry_form_screen.dart';
import 'hisab_chat.dart';
import 'khata_screen.dart';
import '../theme/app_colors.dart';

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

  static const Color greenAccent = Color(0xFF00E676);
  static const Color greenPillBg = Color(0xFF0B291A);
  static const Color textMuted = Color(0xFF888890);
  static const Color textMutedDark = Color(0xFF55555C);

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
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: colors.border),
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
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "₹${tx.amount} • ${tx.subtitle}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textMuted,
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
                          color: colors.surfaceSecondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.border),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: colors.textMuted,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: colors.border),
                const SizedBox(height: 10),
                if (!isKharcha)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.greenPillBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.open_in_new_rounded,
                        color: colors.greenText,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      "Open Hisaab Chat",
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      "Is dost ki complete chat & ledger kholein",
                      style: TextStyle(color: colors.textMuted, fontSize: 11),
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
                      color: colors.redPillBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: colors.redText,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    "Delete Record",
                    style: TextStyle(
                      color: colors.redText,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    "Is hisaab ko local ledger se hata dein",
                    style: TextStyle(color: colors.textMuted, fontSize: 11),
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
    final colors = context.colors;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bool isFutureDisabled = _isSameDay(_selectedDate, today);

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. PINNED FULLSCREEN WALLPAPER (home_bg.png) - Dark mode only
          if (colors.isDark)
            Positioned.fill(
              child: Opacity(
                opacity: 0.42,
                child: Image.asset(
                  'assets/images/home_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),

          // 2. SOFT AMBIENT GRADIENT OVERLAY
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors.isDark
                      ? [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.20),
                          Colors.black.withValues(alpha: 0.65),
                        ]
                      : [
                          colors.bg.withValues(alpha: 0.6),
                          colors.bg,
                        ],
                  stops: const [0.0, 0.40, 1.0],
                ),
              ),
            ),
          ),

          // 3. MAIN FOREGROUND CONTENT
          SafeArea(
            child: Column(
              children: [
                // =========================================================
                // TOP BAR (GLASS SEARCH & OPTIONS)
                // =========================================================
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
                                color: colors.greenAccent,
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
                                : colors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: colors.border,
                            ),
                            boxShadow: colors.isDark ? [] : [colors.cardShadow],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: colors.textMuted,
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
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 12.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Search dost, kharcha...",
                                    hintStyle: TextStyle(
                                      color: colors.textMuted,
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
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 16,
                                              color: colors.textMuted,
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
                                data: Theme.of(
                                  context,
                                ).copyWith(cardColor: colors.surface),
                                child: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    size: 18,
                                    color: textMuted,
                                  ),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(color: colors.border),
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
                                        title:
                                            "Data device memory me safe hai!",
                                        type: ToastType.success,
                                      );
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    PopupMenuItem(
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
                                              color: colors.textPrimary,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
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
                                              color: colors.textPrimary,
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

                // =========================================================
                // SCROLLABLE BODY
                // =========================================================
                Expanded(
                  child: RefreshIndicator(
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
                          // Glass Net Receivable / Payable Card
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
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  22,
                                  20,
                                  20,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.isDark
                                      ? Colors.black.withValues(alpha: 0.38)
                                      : colors.surface,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: colors.border,
                                  ),
                                  boxShadow: colors.isDark
                                      ? []
                                      : [colors.cardShadow],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Lena Hai (Receivable)",
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "₹$totalLena",
                                              style: TextStyle(
                                                color: colors.isDark ? colors.greenAccent : colors.greenText,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: colors.isDark
                                                    ? const Color(0xFF0B291A).withValues(alpha: 0.8)
                                                    : colors.greenPillBg,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: colors.greenPillBorder,
                                                ),
                                              ),
                                              child: Text(
                                                "+₹$dateLena",
                                                style: TextStyle(
                                                  color: colors.greenText,
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
                                        Text(
                                          "Dena Hai (Payable)",
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "₹$totalDena",
                                              style: TextStyle(
                                                color: colors.isDark ? colors.redAccent : colors.redText,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: colors.isDark
                                                    ? const Color(0xFF2E1215).withValues(alpha: 0.8)
                                                    : colors.redPillBg,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: colors.redPillBorder,
                                                ),
                                              ),
                                              child: Text(
                                                "-₹$dateDena",
                                                style: TextStyle(
                                                  color: colors.redText,
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
                                            borderRadius: BorderRadius.circular(
                                              26,
                                            ),
                                            child: Container(
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: colors.isDark
                                                    ? Colors.black.withValues(alpha: 0.35)
                                                    : colors.surfaceSecondary,
                                                borderRadius:
                                                    BorderRadius.circular(26),
                                                border: Border.all(
                                                  color: colors.border,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "Khata",
                                                    style: TextStyle(
                                                      color: colors.textPrimary,
                                                      fontSize: 13.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  SizedBox(width: 5),
                                                  Icon(
                                                    Icons.arrow_outward_rounded,
                                                    size: 14,
                                                    color: colors.textSecondary,
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
                                            borderRadius: BorderRadius.circular(
                                              26,
                                            ),
                                            child: Container(
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: colors.plusButtonBg,
                                                borderRadius:
                                                    BorderRadius.circular(26),
                                                boxShadow: colors.isDark
                                                    ? []
                                                    : [colors.cardShadow],
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "Naya Kharcha",
                                                    style: TextStyle(
                                                      color: colors.plusButtonIcon,
                                                      fontSize: 13.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.add_rounded,
                                                    size: 18,
                                                    color: colors.plusButtonIcon,
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

                          // Header Row (Hisaab History)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Hisaab History",
                                    style: TextStyle(
                                      color: colors.textPrimary,
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
                                      color: colors.isDark ? Colors.black.withValues(alpha: 0.35) : colors.surfaceSecondary,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: colors.border,
                                      ),
                                    ),
                                    child: Text(
                                      _isAllDateSelected
                                          ? "All History"
                                          : "Daily View",
                                      style: TextStyle(
                                        color: colors.isDark ? colors.greenAccent : colors.greenText,
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
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        "All Khata",
                                        style: TextStyle(
                                          color: colors.textMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                        color: colors.textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // History List & Date Controller
                          ValueListenableBuilder<Box<TransactionModel>>(
                            valueListenable: _transBox.listenable(),
                            builder: (context, box, _) {
                              final allTx = box.values
                                  .toList()
                                  .reversed
                                  .toList();

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
                                        vertical: 32,
                                        horizontal: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.surface,
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: colors.border,
                                        ),
                                        boxShadow: colors.isDark ? [] : [colors.cardShadow],
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: colors.surfaceSecondary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.receipt_long_rounded,
                                              size: 28,
                                              color: colors.textMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            _isAllDateSelected
                                                ? "Abhi tak koi entry nahi hai"
                                                : "Is din ka koi hisaab nahi hai",
                                            style: TextStyle(
                                              color: colors.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _isAllDateSelected
                                                ? "Apna pehla len-den ya kharcha note karne ke liye button dabayein."
                                                : "Kisi aur tareekh ko chunein ya naya hisaab likhein.",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: colors.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (widget.onOpenEntry != null) ...[
                                            const SizedBox(height: 16),
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: colors.textPrimary,
                                                side: BorderSide(
                                                  color: colors.border,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 10,
                                                ),
                                              ),
                                              icon: Icon(
                                                Icons.add_rounded,
                                                size: 16,
                                                color: colors.isDark ? colors.greenAccent : colors.greenText,
                                              ),
                                              label: const Text(
                                                "Naya Hisaab Likhein",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              onPressed: widget.onOpenEntry,
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                  else
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final tx = filtered[index];
                                        final isLena = tx.type == 'lena';
                                        final isKharcha = tx.type == 'kharcha';

                                        String status;
                                        Color statusColor;

                                        if (isKharcha) {
                                          status = "Kharcha";
                                          statusColor = colors.textMuted;
                                        } else if (isLena) {
                                          status = "+₹${tx.amount} lena";
                                          statusColor = colors.isDark ? colors.greenAccent : colors.greenText;
                                        } else {
                                          status = "-₹${tx.amount} dena";
                                          statusColor = colors.isDark ? colors.redAccent : colors.redText;
                                        }

                                        return _buildHistoryTile(
                                          colors: colors,
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
                                  _buildBottomDateController(colors, isFutureDisabled),
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
        ],
      ),
    );
  }

  // Date Controller at the Bottom
  Widget _buildBottomDateController(AppColors colors, bool isFutureDisabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.isDark ? Colors.black.withValues(alpha: 0.38) : colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: colors.isDark ? [] : [colors.cardShadow],
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
                color: colors.isDark ? Colors.white.withValues(alpha: 0.08) : colors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: colors.textPrimary,
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
                    data: colors.isDark
                        ? ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: greenAccent,
                              onPrimary: Colors.black,
                              surface: Color(0xFF1E1E22),
                              onSurface: Colors.white,
                            ),
                            dialogTheme: const DialogThemeData(
                              backgroundColor: Color(0xFF16161A),
                            ),
                          )
                        : ThemeData.light().copyWith(
                            colorScheme: ColorScheme.light(
                              primary: colors.greenText,
                              onPrimary: Colors.white,
                              surface: colors.surface,
                              onSurface: colors.textPrimary,
                            ),
                            dialogTheme: DialogThemeData(
                              backgroundColor: colors.surface,
                            ),
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
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Tap to choose calendar date",
                  style: TextStyle(color: colors.textMuted, fontSize: 10),
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
                        ? (colors.isDark ? greenPillBg : colors.greenPillBg)
                        : (colors.isDark ? Colors.white.withValues(alpha: 0.08) : colors.surfaceSecondary),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isAllDateSelected
                          ? (colors.isDark ? greenAccent.withValues(alpha: 0.6) : colors.greenPillBorder)
                          : colors.border,
                    ),
                  ),
                  child: Text(
                    "All",
                    style: TextStyle(
                      color: _isAllDateSelected
                          ? (colors.isDark ? greenAccent : colors.greenText)
                          : colors.textMuted,
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
                        : (colors.isDark ? Colors.white.withValues(alpha: 0.08) : colors.surfaceSecondary),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFutureDisabled || _isAllDateSelected
                          ? Colors.transparent
                          : colors.border,
                    ),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: isFutureDisabled || _isAllDateSelected
                        ? (colors.isDark ? textMutedDark : colors.border)
                        : colors.textPrimary,
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

  // Transaction History Tile
  Widget _buildHistoryTile({
    required AppColors colors,
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
        color: colors.isDark ? Colors.black.withValues(alpha: 0.35) : colors.surface,
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
                  width: 42,
                  height: 42,
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
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        timeOrDesc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.textSecondary, fontSize: 11),
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

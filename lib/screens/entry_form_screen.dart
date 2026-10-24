import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/friend_model.dart';
import '../models/transaction_model.dart';
import '../models/entry_form_state.dart';
import '../services/hisaab_entry_service.dart';
import '../widgets/custom_toast.dart';
import '../widgets/entry_form_widgets.dart';
import '../widgets/expense_filter_bar.dart';
import '../widgets/whatsapp_receipt_sheet.dart';
import '../theme/app_colors.dart';

class EntryFormView extends StatefulWidget {
  final int entryType;
  final int? initialTabIndex; // 0: Dost, 1: Personal
  final VoidCallback onClose;

  const EntryFormView({
    super.key,
    required this.entryType,
    this.initialTabIndex,
    required this.onClose,
  });

  @override
  State<EntryFormView> createState() => _EntryFormViewState();
}

class _EntryFormViewState extends State<EntryFormView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late Box<FriendModel> _friendsBox;
  late Box<TransactionModel> _transBox;
  late Box<String> _tagsBox;
  late Box<Map> _personalBox;
  late HisaabEntryService _entryService;

  late EntryFormStateData _stateData;

  late PageController _pageController;
  late int _currentSlideIndex; // 0: Dost, 1: Personal

  // Personal Kharcha Date Filtering & Pagination (like Profile page)
  String _personalActiveDateFilter = "all";
  DateTime? _personalSelectedCustomDate;
  static const int _personalPageSize = 6;
  int _personalDisplayLimit = _personalPageSize;

  late ScrollController _friendsScrollCtrl;
  late ScrollController _personalScrollCtrl;
  bool _isBottomDockVisible = true;

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _newFriendNameCtrl = TextEditingController();
  final TextEditingController _newFriendPhoneCtrl = TextEditingController();
  final TextEditingController _newFriendNoteCtrl = TextEditingController();

  final TextEditingController _personalTitleCtrl = TextEditingController();
  final TextEditingController _personalAmountCtrl = TextEditingController();
  String _personalSelectedCat = 'Chai';
  String _personalSelectedMode = 'UPI';

  final List<Map<String, dynamic>> _paymentOptions = [
    {'name': 'UPI', 'icon': Icons.account_balance_wallet_rounded},
    {'name': 'Cash', 'icon': Icons.payments_rounded},
    {'name': 'ATM', 'icon': Icons.credit_card_rounded},
  ];

  final List<String> _personalCategories = [
    'Chai',
    'Kirana',
    'Khana',
    'Medical',
    'Icecream',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _friendsBox = Hive.box<FriendModel>('friends_box');
    _transBox = Hive.box<TransactionModel>('transactions_box');
    _tagsBox = Hive.box<String>('tags_box');
    _personalBox = Hive.box<Map>('personal_expenses_box');

    final int startTab =
        widget.initialTabIndex ?? (widget.entryType == 2 ? 1 : 0);
    _currentSlideIndex = startTab;
    _pageController = PageController(initialPage: startTab);
    _friendsScrollCtrl = ScrollController();
    _personalScrollCtrl = ScrollController();

    _friendsScrollCtrl.addListener(_onScroll);
    _personalScrollCtrl.addListener(_onScroll);

    _entryService = HisaabEntryService(
      friendsBox: _friendsBox,
      transBox: _transBox,
    );

    if (_tagsBox.isEmpty) {
      _tagsBox.addAll(['Personal', 'Business', 'College']);
    }

    _stateData = EntryFormStateData(
      txType: widget.entryType == 2 ? 'liya' : 'diya',
      selectedTag: null,
      selectedFriendKey: null,
      availableTags: _tagsBox.values.toList(),
    );
  }

  void _onScroll() {
    final activeCtrl = _currentSlideIndex == 0
        ? _friendsScrollCtrl
        : _personalScrollCtrl;
    if (!activeCtrl.hasClients) return;

    if (activeCtrl.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isBottomDockVisible) {
        setState(() => _isBottomDockVisible = false);
      }
    } else if (activeCtrl.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isBottomDockVisible) {
        setState(() => _isBottomDockVisible = true);
      }
    }
  }

  @override
  void dispose() {
    _friendsScrollCtrl.removeListener(_onScroll);
    _personalScrollCtrl.removeListener(_onScroll);
    _friendsScrollCtrl.dispose();
    _personalScrollCtrl.dispose();
    _pageController.dispose();
    _searchCtrl.dispose();
    _noteCtrl.dispose();
    _amountCtrl.dispose();
    _newFriendNameCtrl.dispose();
    _newFriendPhoneCtrl.dispose();
    _newFriendNoteCtrl.dispose();
    _personalTitleCtrl.dispose();
    _personalAmountCtrl.dispose();
    super.dispose();
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

  void _confirmDeletePersonalExpense(dynamic key, Map item) {
    final colors = context.colors;
    final title = item["title"] ?? "Kharcha";
    final amount = item["amount"] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.border),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: colors.redAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              "Kharcha Delete Karein?",
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "Kya aap '$title' (-₹$amount) ko delete karna chahte hain?",
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _personalBox.delete(key);
              AppToast.show(
                context,
                title: "'$title' delete ho gaya!",
                type: ToastType.error,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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

  void _switchSlide(int index) {
    if (_currentSlideIndex == index) return;
    setState(() {
      _currentSlideIndex = index;
      _isBottomDockVisible = true;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleAddNewFriend() {
    final name = _newFriendNameCtrl.text.trim();
    if (name.isEmpty) {
      AppToast.show(
        context,
        title: "Kripya dost ka naam likhein!",
        type: ToastType.warning,
      );
      return;
    }

    final key = _entryService.addNewFriend(
      name: name,
      phone: _newFriendPhoneCtrl.text.trim(),
      note: _newFriendNoteCtrl.text.trim(),
      tag: _stateData.selectedTag ?? "",
    );

    setState(() {
      _stateData.selectedFriendKey = key;
      _newFriendNameCtrl.clear();
      _newFriendPhoneCtrl.clear();
      _newFriendNoteCtrl.clear();
      _stateData.selectedTag = null;
      _stateData.isAddAccordionOpen = false;
    });

    AppToast.show(
      context,
      title: "$name ko list mein jod diya gaya!",
      type: ToastType.success,
    );
  }

  Future<void> _handleSaveSingleFriendHisaab() async {
    final int amount = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      AppToast.show(
        context,
        title: "Kripya valid amount darj karein!",
        type: ToastType.warning,
      );
      return;
    }

    if (_stateData.selectedFriendKey == null) {
      AppToast.show(
        context,
        title: "Kripya kisi ek dost ko chunein!",
        type: ToastType.warning,
      );
      return;
    }

    final noteText = _noteCtrl.text.trim();
    final friendKey = _stateData.selectedFriendKey;
    final txType = _stateData.txType;
    final FriendModel? friend =
        friendKey != null ? _friendsBox.get(friendKey) : null;

    await _entryService.saveSingleFriendTransaction(
      friendKey: friendKey,
      amount: amount,
      txType: txType,
      note: noteText,
      paymentMode: _stateData.selectedPaymentMode,
    );

    _amountCtrl.clear();
    _noteCtrl.clear();

    if (!mounted) return;
    FocusScope.of(context).unfocus();

    AppToast.show(
      context,
      title: "₹$amount ka hisaab safalta se jod diya gaya!",
      type: ToastType.success,
    );

    if (friend != null && mounted) {
      await WhatsAppReceiptSheet.show(
        context: context,
        friend: friend,
        amount: amount,
        txType: txType,
        note: noteText,
      );
    }

    if (mounted) {
      widget.onClose();
    }
  }

  void _handleSavePersonalKharcha() {
    final int amt = int.tryParse(_personalAmountCtrl.text.trim()) ?? 0;
    final String title = _personalTitleCtrl.text.trim().isNotEmpty
        ? _personalTitleCtrl.text.trim()
        : _personalSelectedCat;

    if (amt <= 0) {
      AppToast.show(
        context,
        title: "Kripya valid amount likhein!",
        type: ToastType.warning,
      );
      return;
    }

    final now = DateTime.now();
    final timeLabel =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    _personalBox.add({
      "title": title,
      "sub": _personalSelectedCat,
      "amount": amt,
      "category": _personalSelectedCat,
      "mode": _personalSelectedMode,
      "time": timeLabel,
      "timestamp": now.millisecondsSinceEpoch,
    });

    _personalTitleCtrl.clear();
    _personalAmountCtrl.clear();
    FocusScope.of(context).unfocus();

    AppToast.show(
      context,
      title: "₹$amt ka personal kharcha note ho gaya!",
      type: ToastType.success,
    );
    widget.onClose();
  }

  void _showPaymentModeSheet({required bool isPersonal}) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: colors.border),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.isDark ? Colors.white24 : colors.divider,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "Payment Mode Chunein",
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ..._paymentOptions.map((opt) {
                  final currentMode = isPersonal
                      ? _personalSelectedMode
                      : _stateData.selectedPaymentMode;
                  final isSelected = currentMode == opt['name'];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    leading: Icon(
                      opt['icon'] as IconData,
                      color: isSelected ? colors.greenAccent : colors.textSecondary,
                      size: 20,
                    ),
                    title: Text(
                      opt['name'] as String,
                      style: TextStyle(
                        color: isSelected ? colors.greenAccent : colors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: colors.greenAccent,
                            size: 18,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        if (isPersonal) {
                          _personalSelectedMode = opt['name'] as String;
                        } else {
                          _stateData.selectedPaymentMode =
                              opt['name'] as String;
                        }
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return "Today";
    if (checkDate == yesterday) return "Yesterday";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  bool _matchesPersonalDateFilter(DateTime itemDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(itemDate.year, itemDate.month, itemDate.day);

    if (_personalActiveDateFilter == "all") return true;
    if (_personalActiveDateFilter == "today") return checkDate == today;
    if (_personalActiveDateFilter == "yesterday") return checkDate == yesterday;
    if (_personalActiveDateFilter == "custom" &&
        _personalSelectedCustomDate != null) {
      final customDate = DateTime(
        _personalSelectedCustomDate!.year,
        _personalSelectedCustomDate!.month,
        _personalSelectedCustomDate!.day,
      );
      return checkDate == customDate;
    }
    return true;
  }

  Future<void> _pickPersonalCustomDate() async {
    final colors = context.colors;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _personalSelectedCustomDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: (colors.isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: colors.isDark
                ? ColorScheme.dark(
                    primary: colors.greenAccent,
                    onPrimary: Colors.black,
                    surface: colors.surface,
                    onSurface: colors.textPrimary,
                  )
                : ColorScheme.light(
                    primary: colors.greenAccent,
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
        _personalSelectedCustomDate = picked;
        _personalActiveDateFilter = "custom";
        _personalDisplayLimit = _personalPageSize;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            EntryTopNavHeader(
              activeTab: _currentSlideIndex,
              onTabSwitch: _switchSlide,
              onBack: widget.onClose,
            ),
            Expanded(
              child: Stack(
                children: [
                  PageView(
                    controller: _pageController,
                    physics: const PageScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    onPageChanged: (idx) {
                      setState(() {
                        _currentSlideIndex = idx;
                        _isBottomDockVisible = true;
                      });
                    },
                    children: [
                      _buildFriendsPageView(),
                      _buildPersonalExpensePageView(),
                    ],
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    bottom: _isBottomDockVisible ? -60 : 18,
                    right: 18,
                    child: GestureDetector(
                      onTap: () => setState(() => _isBottomDockVisible = true),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.isDark
                              ? Colors.black.withValues(alpha: 0.85)
                              : colors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.greenAccent,
                            width: 1.5,
                          ),
                          boxShadow: [
                            colors.isDark
                                ? BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                : colors.cardShadow,
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: colors.greenAccent,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 0: DOST HISAAB PAGE (Now properly wrapped with Street BG)
  // -------------------------------------------------------------
  Widget _buildFriendsPageView() {
    final colors = context.colors;
    return Stack(
      children: [
        // 1. Street Lamp Rainy BG Image (Dark Mode Only)
        if (colors.isDark)
          Positioned.fill(
            child: Opacity(
              opacity: 0.45,
              child: Image.asset(
                'assets/images/friends_select_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),

        // 2. Soft Ambient Gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors.isDark
                    ? [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.60),
                      ]
                    : const [
                        Color(0xFFF8FAFC),
                        Color(0xFFF1F5F9),
                      ],
                stops: colors.isDark ? const [0.0, 0.45, 1.0] : const [0.0, 1.0],
              ),
            ),
          ),
        ),

        // 3. Main Dost Content
        ValueListenableBuilder<Box<FriendModel>>(
          valueListenable: _friendsBox.listenable(),
          builder: (context, box, _) {
            final allFriends = box.values.toList();
            final allKeys = box.keys.toList();

            final totalCount = allFriends.length;
            final lenaCount = allFriends
                .where((f) => f.type == 'lena' && f.balance > 0)
                .length;
            final denaCount = allFriends
                .where((f) => f.type == 'dena' && f.balance > 0)
                .length;

            final List<FilterItem> filterItems = [
              FilterItem(
                id: 'all',
                label: 'Sabhi',
                count: totalCount,
                type: 'all',
              ),
              FilterItem(
                id: 'lena',
                label: 'Lena Hai',
                count: lenaCount,
                type: 'lena',
              ),
              FilterItem(
                id: 'dena',
                label: 'Dena Hai',
                count: denaCount,
                type: 'dena',
              ),
            ];

            for (var tag in _stateData.availableTags) {
              final count = allFriends
                  .where(
                    (f) => f.desc.toLowerCase().contains(tag.toLowerCase()),
                  )
                  .length;
              if (count > 0) {
                filterItems.add(
                  FilterItem(id: tag, label: tag, count: count, type: 'tag'),
                );
              }
            }

            final query = _searchCtrl.text.trim().toLowerCase();
            final List<MapEntry<dynamic, FriendModel>> filteredEntries = [];

            for (int i = 0; i < allFriends.length; i++) {
              final friend = allFriends[i];
              final key = allKeys[i];

              if (_stateData.activeFilter == 'lena' &&
                  (friend.type != 'lena' || friend.balance <= 0)) {
                continue;
              }
              if (_stateData.activeFilter == 'dena' &&
                  (friend.type != 'dena' || friend.balance <= 0)) {
                continue;
              }

              if (_stateData.activeFilter != 'all' &&
                  _stateData.activeFilter != 'lena' &&
                  _stateData.activeFilter != 'dena') {
                if (!friend.desc.toLowerCase().contains(
                  _stateData.activeFilter.toLowerCase(),
                )) {
                  continue;
                }
              }

              if (query.isNotEmpty) {
                final matchName = friend.name.toLowerCase().contains(query);
                final matchDesc = friend.desc.toLowerCase().contains(query);
                if (!matchName && !matchDesc) continue;
              }

              filteredEntries.add(MapEntry(key, friend));
            }

            String activeFriendName = "Koi dost select karein";
            String activeFriendBalance = "Khata Chunein";
            bool isPositiveBalance = true;
            final hasSelected = _stateData.selectedFriendKey != null;

            if (hasSelected) {
              final FriendModel? f = _friendsBox.get(
                _stateData.selectedFriendKey,
              );
              if (f != null) {
                activeFriendName = f.name;
                final isLena = f.type == 'lena';
                isPositiveBalance = isLena;
                activeFriendBalance =
                    "${isLena ? '+₹' : '-₹'}${f.balance} ${isLena ? 'lena' : 'dena'}";
              }
            }

            return Column(
              children: [
                EntrySearchBarAndFilters(
                  searchCtrl: _searchCtrl,
                  activeFilter: _stateData.activeFilter,
                  filterList: filterItems,
                  onFilterChanged: (filter) =>
                      setState(() => _stateData.activeFilter = filter),
                  onSearchChanged: () => setState(() {}),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    controller: _friendsScrollCtrl,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    children: [
                      AddFriendAccordionWidget(
                        isOpen: _stateData.isAddAccordionOpen,
                        onToggle: () => setState(
                          () => _stateData.isAddAccordionOpen =
                              !_stateData.isAddAccordionOpen,
                        ),
                        nameCtrl: _newFriendNameCtrl,
                        phoneCtrl: _newFriendPhoneCtrl,
                        noteCtrl: _newFriendNoteCtrl,
                        selectedTag: _stateData.selectedTag,
                        tags: _stateData.availableTags,
                        onTagSelected: (tag) =>
                            setState(() => _stateData.selectedTag = tag),
                        onCustomTagAdded: (newTag) {
                          setState(() {
                            if (!_tagsBox.values.contains(newTag)) {
                              _tagsBox.add(newTag);
                            }
                            _stateData.availableTags = _tagsBox.values.toList();
                            _stateData.selectedTag = newTag;
                          });
                          AppToast.show(
                            context,
                            title: "'$newTag' tag permanent add ho gaya!",
                            type: ToastType.success,
                          );
                        },
                        onCancel: () {
                          _newFriendNameCtrl.clear();
                          _newFriendPhoneCtrl.clear();
                          _newFriendNoteCtrl.clear();
                          setState(() => _stateData.isAddAccordionOpen = false);
                        },
                        onSubmit: _handleAddNewFriend,
                      ),
                      const SizedBox(height: 10),
                      if (filteredEntries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: Text(
                              "Koi dost nahi mila",
                              style: TextStyle(color: colors.textMuted, fontSize: 12),
                            ),
                          ),
                        )
                      else
                        ...filteredEntries.map((entry) {
                          final key = entry.key;
                          final friend = entry.value;
                          final isSelected =
                              _stateData.selectedFriendKey == key;
                          return SelectableFriendCardWidget(
                            friendKey: key,
                            friend: friend,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _stateData.selectedFriendKey = null;
                                } else {
                                  _stateData.selectedFriendKey = key;
                                }
                              });
                            },
                          );
                        }),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 240),
                  crossFadeState: _isBottomDockVisible
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: EntryBottomDockWidget(
                        activeFriendName: activeFriendName,
                        activeBalance: activeFriendBalance,
                        isPositive: isPositiveBalance,
                        hasSelectedFriend: hasSelected,
                        noteCtrl: _noteCtrl,
                        amountCtrl: _amountCtrl,
                        selectedPaymentMode: _stateData.selectedPaymentMode,
                        txType: _stateData.txType,
                        onPaymentModeTap: () =>
                            _showPaymentModeSheet(isPersonal: false),
                        onTxTypeChanged: (type) =>
                            setState(() => _stateData.txType = type),
                        onSave: _handleSaveSingleFriendHisaab,
                        onClosePage: widget.onClose,
                      ),
                    ),
                  ),
                  secondChild: const SizedBox(
                    width: double.infinity,
                    height: 0,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 1: PERSONAL KHARCHA PAGE (Clean Card + Right Aligned Amount)
  // -------------------------------------------------------------
  Widget _buildPersonalExpensePageView() {
    final colors = context.colors;
    return Stack(
      children: [
        if (colors.isDark)
          Positioned.fill(
            child: Opacity(
              opacity: 0.55,
              child: Image.asset(
                'assets/images/personal_kharcha_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors.isDark
                    ? [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.50),
                      ]
                    : const [
                        Color(0xFFF8FAFC),
                        Color(0xFFF1F5F9),
                      ],
                stops: colors.isDark ? const [0.0, 0.45, 1.0] : const [0.0, 1.0],
              ),
            ),
          ),
        ),
        Column(
          children: [
            Expanded(
              child: ValueListenableBuilder<Box<Map>>(
                valueListenable: _personalBox.listenable(),
                builder: (context, pBox, _) {
                  final rawKeys = pBox.keys.toList().reversed.toList();
                  final rawItems = pBox.values.toList().reversed.toList();

                  final List<MapEntry<dynamic, Map>> allFilteredItems = [];
                  for (int i = 0; i < rawItems.length; i++) {
                    final item = rawItems[i];
                    final k = rawKeys[i];
                    final ts =
                        item["timestamp"] as int? ??
                        DateTime.now().millisecondsSinceEpoch;
                    final itemDate =
                        DateTime.fromMillisecondsSinceEpoch(ts);
                    if (!_matchesPersonalDateFilter(itemDate)) {
                      continue;
                    }
                    allFilteredItems.add(MapEntry(k, item));
                  }

                  final int filteredTotal = allFilteredItems.fold(
                    0,
                    (sum, e) =>
                        sum + ((e.value["amount"] as num?)?.toInt() ?? 0),
                  );

                  final paginatedItems = allFilteredItems
                      .take(_personalDisplayLimit)
                      .toList();
                  final bool hasMore =
                      allFilteredItems.length > _personalDisplayLimit;

                  final Map<String, List<MapEntry<dynamic, Map>>>
                  groupedExpenses = {};
                  for (var entry in paginatedItems) {
                    final item = entry.value;
                    final ts =
                        item["timestamp"] as int? ??
                        DateTime.now().millisecondsSinceEpoch;
                    final dateKey = _formatDateHeader(
                      DateTime.fromMillisecondsSinceEpoch(ts),
                    );
                    groupedExpenses
                        .putIfAbsent(dateKey, () => [])
                        .add(entry);
                  }

                  return ListView(
                    controller: _personalScrollCtrl,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: [
                      // TOP CARD: AMOUNT ON THE RIGHT SIDE OF THE TEXT
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: colors.glassCardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colors.glassCardBorder,
                                width: 1.2,
                              ),
                              boxShadow: colors.isDark ? [] : [colors.cardShadow],
                            ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "KHUD KA KHARCHA",
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.9,
                              ),
                            ),
                            Text(
                              "₹$filteredTotal.00",
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Organized Day Filter Bar (Like Profile Page)
                      ExpenseFilterBar(
                        activeDateFilter: _personalActiveDateFilter,
                        selectedCustomDate: _personalSelectedCustomDate,
                        onDateFilterChanged: (newFilter) {
                          setState(() {
                            _personalActiveDateFilter = newFilter;
                            _personalSelectedCustomDate = null;
                            _personalDisplayLimit = _personalPageSize;
                          });
                        },
                        onPickCustomDate: _pickPersonalCustomDate,
                        onClearCustomDate: () {
                          setState(() {
                            _personalActiveDateFilter = "all";
                            _personalSelectedCustomDate = null;
                            _personalDisplayLimit = _personalPageSize;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      if (allFilteredItems.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          alignment: Alignment.center,
                          child: Text(
                            _personalActiveDateFilter == "all"
                                ? "Abhi tak koi kharcha add nahi kiya gaya hai.\nNiche diye dock se turant add karein!"
                                : "Chune gaye filter me koi kharcha nahi mila.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        ...groupedExpenses.entries.expand((entry) {
                          final dateLabel = entry.key;
                          final groupList = entry.value;

                          return [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.isDark
                                          ? Colors.black.withValues(alpha: 0.40)
                                          : colors.surfaceSecondary,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: colors.border,
                                      ),
                                    ),
                                    child: Text(
                                      dateLabel,
                                      style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: colors.divider,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...groupList.map((entryItem) {
                              final rawKey = entryItem.key;
                              final item = entryItem.value;
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
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(
                                          item["time"] ?? "00:00",
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: catColor.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: catColor.withValues(alpha: 0.65),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Icon(
                                            catIcon,
                                            size: 13,
                                            color: catColor,
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            width: 1.5,
                                            color: colors.divider,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: GestureDetector(
                                        onLongPress: () {
                                          _confirmDeletePersonalExpense(
                                            rawKey,
                                            item,
                                          );
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.isDark
                                                ? Colors.black.withValues(alpha: 0.35)
                                                : colors.surface,
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            border: Border.all(
                                              color: colors.border,
                                            ),
                                            boxShadow: colors.isDark ? null : [colors.cardShadow],
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item["title"] ??
                                                          "Kharcha",
                                                      style: TextStyle(
                                                        color: colors.textPrimary,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      item["sub"]?.isNotEmpty ==
                                                              true
                                                          ? item["sub"]
                                                          : cat,
                                                      style: TextStyle(
                                                        color: colors.textSecondary,
                                                        fontSize: 10.5,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    "-₹${item['amount']}",
                                                    style: TextStyle(
                                                      color: colors.redAccent,
                                                      fontSize: 13.5,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    item["mode"] ?? "UPI",
                                                    style: TextStyle(
                                                      color: colors.textMuted,
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                            }),
                          ];
                        }),

                      // View More Button
                      if (hasMore) ...[
                        const SizedBox(height: 14),
                        Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _personalDisplayLimit += _personalPageSize;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.isDark
                                      ? Colors.black.withValues(alpha: 0.45)
                                      : colors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: colors.border,
                                  ),
                                  boxShadow: colors.isDark ? null : [colors.cardShadow],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "View More",
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: colors.greenAccent,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  );
                },
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 240),
              crossFadeState: _isBottomDockVisible
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    decoration: BoxDecoration(
                      color: colors.isDark
                          ? Colors.black.withValues(alpha: 0.30)
                          : colors.surface,
                      border: Border(
                        top: BorderSide(
                          color: colors.border,
                          width: 1,
                        ),
                      ),
                      boxShadow: colors.isDark ? null : [colors.cardShadow],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 8,
                            left: 2,
                            right: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Category: ",
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  Text(
                                    _personalSelectedCat,
                                    style: TextStyle(
                                      color: colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "Wallet / $_personalSelectedMode",
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 44,
                          padding: const EdgeInsets.only(left: 12, right: 6),
                          decoration: BoxDecoration(
                            color: colors.isDark
                                ? Colors.black.withValues(alpha: 0.40)
                                : colors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: colors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                color: colors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _personalTitleCtrl,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Title (Chai, Kirana, Petrol, Lunch)...",
                                    hintStyle: TextStyle(
                                      color: colors.textMuted,
                                      fontSize: 12,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    _showPaymentModeSheet(isPersonal: true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : colors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: colors.border,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: colors.greenAccent,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _personalSelectedMode,
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: colors.textSecondary,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _personalCategories.map((cat) {
                              final isSel = _personalSelectedCat == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _personalSelectedCat = cat,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? colors.greenPillBg
                                          : (colors.isDark
                                              ? Colors.black.withValues(alpha: 0.35)
                                              : colors.surfaceSecondary),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSel
                                            ? colors.greenPillBorder
                                            : colors.border,
                                      ),
                                    ),
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        color: isSel
                                            ? colors.greenText
                                            : colors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: isSel
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.isDark
                                      ? Colors.black.withValues(alpha: 0.40)
                                      : colors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: colors.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      "₹",
                                      style: TextStyle(
                                        color: colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _personalAmountCtrl,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: "Amount",
                                          hintStyle: TextStyle(
                                            color: colors.textMuted,
                                            fontSize: 13,
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.isDark ? Colors.white : colors.greenAccent,
                                  foregroundColor: colors.isDark ? Colors.black : Colors.white,
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _handleSavePersonalKharcha,
                                child: Row(
                                  children: [
                                    Text(
                                      "Save",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: colors.isDark ? Colors.black : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.check_rounded,
                                      color: colors.isDark ? Colors.black : Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: widget.onClose,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: colors.isDark
                                      ? Colors.black.withValues(alpha: 0.40)
                                      : colors.surfaceSecondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.border,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: colors.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              secondChild: const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ],
    );
  }
}

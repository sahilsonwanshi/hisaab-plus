import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/friend_model.dart';
import '../widgets/app_info_card.dart';
import '../widgets/custom_toast.dart';
import '../widgets/expense_filter_bar.dart';
import '../widgets/personal_expense_timeline.dart';
import '../widgets/profile_summary_card.dart';
import '../widgets/smooth_route.dart';
import 'backup_screen.dart';
import 'entry_form_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onGoToHome;

  const ProfileScreen({super.key, this.onGoToHome});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Exact OLED Palette
  static const Color oledBg = Color(0xFF000000);
  static const Color greenAccent = Color(0xFF00E676);
  static const Color redAccent = Color(0xFFFF5252);
  static const Color textMuted = Color(0xFFA1A1AA);

  String _activeCategoryFilter = "Sabhi";
  String _activeDateFilter = "all"; // 'all', 'today', 'yesterday', 'custom'
  DateTime? _selectedCustomDate;
  int _displayLimit = 20;

  late Box<FriendModel> _friendsBox;
  late Box<Map> _personalBox;

  static const List<String> _categories = [
    "Sabhi",
    "Chai",
    "Kirana",
    "Khana",
    "Medical",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _friendsBox = Hive.box<FriendModel>('friends_box');
    _personalBox = Hive.box<Map>('personal_expenses_box');
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() {});
  }

  void _openDirectPersonalEntry() {
    Navigator.push(
      context,
      SmoothOledRoute(
        page: EntryFormView(
          entryType: 2,
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // Date Picker Modal
  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedCustomDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: greenAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF16161A),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF16161A),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedCustomDate = picked;
        _activeDateFilter = "custom";
        _displayLimit = 20;
      });
    }
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

  bool _matchesDateFilter(DateTime itemDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(itemDate.year, itemDate.month, itemDate.day);

    if (_activeDateFilter == "all") return true;
    if (_activeDateFilter == "today") return checkDate == today;
    if (_activeDateFilter == "yesterday") return checkDate == yesterday;
    if (_activeDateFilter == "custom" && _selectedCustomDate != null) {
      final customDate = DateTime(
        _selectedCustomDate!.year,
        _selectedCustomDate!.month,
        _selectedCustomDate!.day,
      );
      return checkDate == customDate;
    }
    return true;
  }

  void _confirmDeleteExpense(dynamic key, Map item) {
    final title = item["title"] ?? "Kharcha";
    final amount = item["amount"] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
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
          "Kya aap '$title' (-₹$amount) ko delete karna chahte hain?",
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
              _personalBox.delete(key);
              AppToast.show(
                context,
                title: "'$title' delete ho gaya!",
                type: ToastType.error,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Delete",
              style: TextStyle(fontWeight: FontWeight.bold),
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
        fit: StackFit.expand,
        children: [
          // 1. Fullscreen Wallpaper
          Positioned.fill(
            child: Opacity(
              opacity: 0.38,
              child: Image.asset(
                'assets/images/profile_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),

          // 2. Soft Dark Ambient Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),

          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                // Header (< Profile & Guest Pill)
                _buildHeader(context),

                // Scrollable Body
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: greenAccent,
                    backgroundColor: Colors.black87,
                    displacement: 20,
                    child: ValueListenableBuilder<Box<FriendModel>>(
                      valueListenable: _friendsBox.listenable(),
                      builder: (context, fBox, _) {
                        int totalLena = 0;
                        int totalDena = 0;
                        int lenaCount = 0;
                        int denaCount = 0;

                        for (var f in fBox.values) {
                          if (f.type == 'lena' && f.balance > 0) {
                            totalLena += f.balance;
                            lenaCount++;
                          } else if (f.type == 'dena' && f.balance > 0) {
                            totalDena += f.balance;
                            denaCount++;
                          }
                        }

                        final int netBalance = totalLena - totalDena;
                        final int combined = totalLena + totalDena;
                        final double greenFrac = combined == 0
                            ? 0.5
                            : (totalLena / combined);
                        final double redFrac = combined == 0
                            ? 0.5
                            : (totalDena / combined);

                        return ValueListenableBuilder<Box<Map>>(
                          valueListenable: _personalBox.listenable(),
                          builder: (context, pBox, _) {
                            final rawKeys = pBox.keys
                                .toList()
                                .reversed
                                .toList();
                            final rawItems = pBox.values
                                .toList()
                                .reversed
                                .toList();

                            // Category + Date Filter Integration
                            final List<MapEntry<dynamic, Map>>
                            allFilteredItems = [];
                            for (int i = 0; i < rawItems.length; i++) {
                              final item = rawItems[i];
                              final k = rawKeys[i];
                              final cat =
                                  item["category"]?.toString() ?? "Other";

                              // Category Match
                              if (_activeCategoryFilter != "Sabhi" &&
                                  cat.toLowerCase() !=
                                      _activeCategoryFilter.toLowerCase()) {
                                continue;
                              }

                              // Date Match
                              final ts =
                                  item["timestamp"] as int? ??
                                  DateTime.now().millisecondsSinceEpoch;
                              final itemDate =
                                  DateTime.fromMillisecondsSinceEpoch(ts);
                              if (!_matchesDateFilter(itemDate)) {
                                continue;
                              }

                              allFilteredItems.add(MapEntry(k, item));
                            }

                            final int filteredKharchaTotal = allFilteredItems
                                .fold(
                                  0,
                                  (sum, e) =>
                                      sum +
                                      ((e.value["amount"] as num?)?.toInt() ??
                                          0),
                                );

                            // Pagination
                            final paginatedItems = allFilteredItems
                                .take(_displayLimit)
                                .toList();

                            // Date-wise Grouping with Daily Totals
                            final Map<String, List<MapEntry<dynamic, Map>>>
                            groupedExpenses = {};
                            final Map<String, int> dailyTotals = {};

                            for (var entry in paginatedItems) {
                              final item = entry.value;
                              final ts =
                                  item["timestamp"] as int? ??
                                  DateTime.now().millisecondsSinceEpoch;
                              final dateLabel = _formatDateHeader(
                                DateTime.fromMillisecondsSinceEpoch(ts),
                              );

                              groupedExpenses
                                  .putIfAbsent(dateLabel, () => [])
                                  .add(entry);
                              dailyTotals[dateLabel] =
                                  (dailyTotals[dateLabel] ?? 0) +
                                  ((item["amount"] as num?)?.toInt() ?? 0);
                            }

                            final bool hasMore =
                                allFilteredItems.length > _displayLimit;

                            return SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                4,
                                16,
                                120,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. Profile Summary Card (Radial Net Balance, Lena, Dena)
                                  ProfileSummaryCard(
                                    netBalance: netBalance,
                                    totalLena: totalLena,
                                    totalDena: totalDena,
                                    lenaCount: lenaCount,
                                    denaCount: denaCount,
                                    greenFrac: greenFrac,
                                    redFrac: redFrac,
                                    onSyncTap: () {
                                      Navigator.push(
                                        context,
                                        SmoothOledRoute(
                                          page: const BackupScreen(),
                                        ),
                                      );
                                    },
                                    onAddKharchaTap: _openDirectPersonalEntry,
                                  ),

                                  const SizedBox(height: 16),

                                  // 2. Expense Filter Bar (Date + Category Capsules)
                                  ExpenseFilterBar(
                                    activeDateFilter: _activeDateFilter,
                                    selectedCustomDate: _selectedCustomDate,
                                    onDateFilterChanged: (newFilter) {
                                      setState(() {
                                        _activeDateFilter = newFilter;
                                        _selectedCustomDate = null;
                                        _displayLimit = 20;
                                      });
                                    },
                                    onPickCustomDate: _pickCustomDate,
                                    onClearCustomDate: () {
                                      setState(() {
                                        _activeDateFilter = "all";
                                        _selectedCustomDate = null;
                                      });
                                    },
                                    activeCategoryFilter: _activeCategoryFilter,
                                    categories: _categories,
                                    rawItems: rawItems,
                                    onCategoryFilterChanged: (newCat) {
                                      setState(() {
                                        _activeCategoryFilter = newCat;
                                        _displayLimit = 20;
                                      });
                                    },
                                  ),

                                  const SizedBox(height: 20),

                                  // 3. Section Title & Filter Total
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Personal Kharcha",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        "Filter Total: ₹$filteredKharchaTotal.00",
                                        style: const TextStyle(
                                          color: textMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // 4. Date-Grouped Timeline Cards
                                  PersonalExpenseTimeline(
                                    groupedExpenses: groupedExpenses,
                                    dailyTotals: dailyTotals,
                                    isEmpty: allFilteredItems.isEmpty,
                                    isDefaultFilter:
                                        _activeCategoryFilter == "Sabhi" &&
                                        _activeDateFilter == "all",
                                    hasMore: hasMore,
                                    onLoadMore: () {
                                      setState(() => _displayLimit += 20);
                                    },
                                    onDeleteItem: _confirmDeleteExpense,
                                  ),

                                  const SizedBox(height: 20),

                                  // 5. Expandable App Info Card
                                  const AppInfoCard(),
                                ],
                              ),
                            );
                          },
                        );
                      },
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 10),
      child: Row(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                onPressed: () {
                  if (widget.onGoToHome != null) {
                    widget.onGoToHome!();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
              const Text(
                "Profile",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_rounded,
                  color: Colors.white70,
                  size: 15,
                ),
                SizedBox(width: 6),
                Text(
                  "Guest #8941",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

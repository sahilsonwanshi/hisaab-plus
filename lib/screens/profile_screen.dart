import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/friend_model.dart';
import '../services/drive_sync_service.dart';
import '../widgets/app_info_card.dart';
import '../widgets/custom_toast.dart';
import '../widgets/expense_filter_bar.dart';
import '../widgets/personal_expense_timeline.dart';
import '../widgets/profile_compact_stats.dart';
import '../widgets/profile_user_card.dart';
import '../widgets/smooth_route.dart';
import 'backup_screen.dart';
import 'entry_form_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/theme_selector_card.dart';

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

  static const int _pageSize = 6;
  String _activeDateFilter = "all"; // 'all', 'today', 'yesterday', 'custom'
  String _activeCategoryFilter = "Sabhi";
  DateTime? _selectedCustomDate;
  int _displayLimit = _pageSize;

  late Box<FriendModel> _friendsBox;
  late Box<Map> _personalBox;

  @override
  void initState() {
    super.initState();
    _friendsBox = Hive.box<FriendModel>('friends_box');
    _personalBox = Hive.box<Map>('personal_expenses_box');
    DriveSyncService.instance.initialize();
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
          initialTabIndex: 1,
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
    );

    if (picked != null) {
      setState(() {
        _selectedCustomDate = picked;
        _activeDateFilter = "custom";
        _displayLimit = _pageSize;
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
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.border),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: colors.redAccent, size: 22),
            const SizedBox(width: 8),
            Text(
              "Kharcha Delete Karein?",
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
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
            child: Text(
              "Cancel",
              style: TextStyle(color: colors.textMuted, fontWeight: FontWeight.w600),
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
              backgroundColor: colors.redAccent,
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
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fullscreen Wallpaper (Dark & Light Mode)
          Positioned.fill(
            child: Opacity(
              opacity: colors.isDark ? 0.38 : 0.76,
              child: Image.asset(
                'assets/images/profile_bg.png',
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
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.65),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.25),
                          const Color(0xFFF1F5F9).withValues(alpha: 0.40),
                        ],
                  stops: const [0.0, 0.45, 1.0],
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
                    color: colors.greenAccent,
                    backgroundColor: colors.surface,
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

                            // Date Filter Integration
                            final List<MapEntry<dynamic, Map>>
                            allFilteredItems = [];
                            for (int i = 0; i < rawItems.length; i++) {
                              final item = rawItems[i];
                              final k = rawKeys[i];

                              // Date Match
                              final ts =
                                  item["timestamp"] as int? ??
                                  DateTime.now().millisecondsSinceEpoch;
                              final itemDate =
                                  DateTime.fromMillisecondsSinceEpoch(ts);
                              if (!_matchesDateFilter(itemDate)) {
                                continue;
                              }

                              // Category Match
                              if (_activeCategoryFilter != "Sabhi" &&
                                  (item["category"] ?? "")
                                          .toString()
                                          .toLowerCase() !=
                                      _activeCategoryFilter.toLowerCase()) {
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

                            for (var entry in allFilteredItems) {
                              final item = entry.value;
                              final ts =
                                  item["timestamp"] as int? ??
                                  DateTime.now().millisecondsSinceEpoch;
                              final dateLabel = _formatDateHeader(
                                DateTime.fromMillisecondsSinceEpoch(ts),
                              );
                              dailyTotals[dateLabel] =
                                  (dailyTotals[dateLabel] ?? 0) +
                                  ((item["amount"] as num?)?.toInt() ?? 0);
                            }

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
                                  // 1. Unified Profile & Backup Card
                                  ValueListenableBuilder<GoogleSignInAccount?>(
                                    valueListenable: DriveSyncService
                                        .instance.currentUserNotifier,
                                    builder: (context, googleAccount, _) {
                                      return ProfileUserCard(
                                        googleAccount: googleAccount,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            SmoothOledRoute(
                                              page: const BackupScreen(),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 10),

                                  // 2. Financial Overview (Clean 3-column snapshot)
                                  ProfileCompactStats(
                                    netBalance: netBalance,
                                    totalLena: totalLena,
                                    totalDena: totalDena,
                                    lenaCount: lenaCount,
                                    denaCount: denaCount,
                                    personalKharchaTotal: filteredKharchaTotal,
                                    onAddPersonalKharcha:
                                        _openDirectPersonalEntry,
                                  ),

                                  const SizedBox(height: 18),

                                   // 3. Personal Kharcha Header (Clean Title & Total)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Personal Kharcha",
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      if (allFilteredItems.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 3.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.surfaceSecondary,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: colors.border,
                                            ),
                                          ),
                                          child: Text(
                                            "Total: ₹$filteredKharchaTotal.00",
                                            style: TextStyle(
                                              color: colors.textSecondary,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // 4. Organized Day & Category Filter Bar
                                  ExpenseFilterBar(
                                    activeDateFilter: _activeDateFilter,
                                    selectedCustomDate: _selectedCustomDate,
                                    onDateFilterChanged: (newFilter) {
                                      setState(() {
                                        _activeDateFilter = newFilter;
                                        _selectedCustomDate = null;
                                        _displayLimit = _pageSize;
                                      });
                                    },
                                    onPickCustomDate: _pickCustomDate,
                                    onClearCustomDate: () {
                                      setState(() {
                                        _activeDateFilter = "all";
                                        _selectedCustomDate = null;
                                        _displayLimit = _pageSize;
                                      });
                                    },
                                    activeCategoryFilter: _activeCategoryFilter,
                                    categories: const [
                                      "Sabhi",
                                      "Chai",
                                      "Kirana",
                                      "Khana",
                                      "Medical",
                                      "Other",
                                    ],
                                    rawItems: rawItems.cast<Map>(),
                                    onCategoryFilterChanged: (newCat) {
                                      setState(() {
                                        _activeCategoryFilter = newCat;
                                        _displayLimit = _pageSize;
                                      });
                                    },
                                  ),

                                  const SizedBox(height: 8),

                                  // 5. Compact "+ Add Kharcha" Sub-Row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _activeDateFilter == "all"
                                            ? "Sabhi Din Ke Kharcha"
                                            : _activeDateFilter == "today"
                                                ? "Aaj Ka Kharcha"
                                                : _activeDateFilter ==
                                                        "yesterday"
                                                    ? "Kal Ka Kharcha"
                                                    : "Custom Date",
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: _openDirectPersonalEntry,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.greenPillBg,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: colors.greenPillBorder,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.add_rounded,
                                                color: colors.greenText,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Add Kharcha",
                                                style: TextStyle(
                                                  color: colors.greenText,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // 6. Date-Grouped Timeline Cards (Paginated)
                                  PersonalExpenseTimeline(
                                    groupedExpenses: groupedExpenses,
                                    dailyTotals: dailyTotals,
                                    isEmpty: allFilteredItems.isEmpty,
                                    isDefaultFilter:
                                        _activeCategoryFilter == "Sabhi" &&
                                        _activeDateFilter == "all",
                                    hasMore: hasMore,
                                    onLoadMore: () {
                                      setState(
                                        () => _displayLimit += _pageSize,
                                      );
                                    },
                                    onDeleteItem: _confirmDeleteExpense,
                                  ),

                                  const SizedBox(height: 20),

                                  // 7. Settings: Theme Selector Card
                                  const ThemeSelectorCard(),

                                  const SizedBox(height: 10),

                                  // 8. Settings: Cloud & Local Backups
                                  Container(
                                    decoration: BoxDecoration(
                                      color: colors.isDark
                                          ? Colors.black.withValues(alpha: 0.35)
                                          : colors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: colors.border,
                                      ),
                                      boxShadow: colors.isDark
                                          ? []
                                          : [colors.cardShadow],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            SmoothOledRoute(
                                              page: const BackupScreen(),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.cloud_sync_rounded,
                                                color: colors.blueAccent,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  "Cloud & Local Backups",
                                                  style: TextStyle(
                                                    color: colors.textPrimary,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color: colors.textMuted,
                                                size: 12,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Expandable App Info Card
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
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 10),
      child: Row(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: colors.textPrimary,
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
              Text(
                "Profile",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
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
              color: colors.isDark
                  ? Colors.black.withValues(alpha: 0.45)
                  : colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.border,
              ),
              boxShadow: colors.isDark ? [] : [colors.cardShadow],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_rounded,
                  color: colors.textSecondary,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  "Guest #8941",
                  style: TextStyle(
                    color: colors.textPrimary,
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

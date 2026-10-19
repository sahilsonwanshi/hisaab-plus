import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/friend_model.dart';
import '../models/transaction_model.dart';
import '../services/hisaab_entry_service.dart';
import '../services/pdf_statement_service.dart';
import '../widgets/custom_toast.dart';
import '../theme/app_colors.dart';

class HisabChatScreen extends StatefulWidget {
  final dynamic friendKey;
  final String friendName;
  final String netAmount;
  final bool isLena;

  const HisabChatScreen({
    super.key,
    this.friendKey,
    this.friendName = "Sahil",
    this.netAmount = "0",
    this.isLena = true,
  });

  @override
  State<HisabChatScreen> createState() => _HisabChatScreenState();
}

class _HisabChatScreenState extends State<HisabChatScreen> {
  static const Color oledBg = Color(0xFF000000);
  static const Color surfaceCard = Color(0xFF141416);
  static const Color surfaceHighlight = Color(0xFF202024);
  static const Color borderCustom = Color(0xFF242429);

  static const Color lenaGreen = Color(0xFF10B981);
  static const Color lenaGreenLight = Color(0xFF34D399);
  static const Color denaRed = Color(0xFFF43F5E);
  static const Color denaRedLight = Color(0xFFFB7185);

  bool _isDetailsExpanded = false;
  bool _isBottomDockVisible = true;
  int _entryType = 0; // 0: Diya, 1: Liya
  String _selectedPaymentMode = "UPI";
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late Box<FriendModel> _friendsBox;
  late Box<TransactionModel> _transBox;
  late HisaabEntryService _entryService;

  @override
  void initState() {
    super.initState();
    _friendsBox = Hive.box<FriendModel>('friends_box');
    _transBox = Hive.box<TransactionModel>('transactions_box');
    _entryService = HisaabEntryService(
      friendsBox: _friendsBox,
      transBox: _transBox,
    );
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToNewestChat();
    });
  }

  // Auto-scroll to the newest chat entries smoothly on screen open
  void _scrollToNewestChat() {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;

    if (maxExtent > 250) {
      _scrollController.jumpTo(maxExtent - 120);
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted && _scrollController.hasClients) {
        if (_scrollController.offset <
            _scrollController.position.maxScrollExtent) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isBottomDockVisible) {
        setState(() => _isBottomDockVisible = false);
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isBottomDockVisible) {
        setState(() => _isBottomDockVisible = true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _amountController.dispose();
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  FriendModel? _resolveFriend(Box<FriendModel> box) {
    if (widget.friendKey != null && box.containsKey(widget.friendKey)) {
      return box.get(widget.friendKey);
    }
    for (var f in box.values) {
      if (f.name.trim().toLowerCase() ==
          widget.friendName.trim().toLowerCase()) {
        return f;
      }
    }
    return null;
  }

  // 1. Single entry delete + balance auto-adjustment & transactions_box sync
  Future<void> _deleteSingleEntry(
      FriendModel friend, Map<dynamic, dynamic> targetTx) async {
    await _entryService.deleteSingleFriendTransaction(
      friend: friend,
      targetTx: targetTx,
    );

    if (mounted) {
      setState(() {});
      AppToast.show(
        context,
        title: "'${targetTx['title'] ?? 'Entry'}' delete ho gayi!",
        type: ToastType.error,
      );
    }
  }

  // 2. Long Press Entry Delete Dialog
  void _showEntryDeleteDialog(FriendModel friend, Map<dynamic, dynamic> tx) {
    final int amount = (tx["amount"] as num?)?.toInt() ?? 0;
    final String title = tx["title"] ?? "Hisaab";

    showDialog(
      context: context,
      builder: (ctx) {
        final colors = context.colors;
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: colors.border),
          ),
          title: Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: colors.redText, size: 22),
              const SizedBox(width: 8),
              Text(
                "Entry Delete Karein?",
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            "Kya aap '$title' (₹$amount) ko delete karna chahte hain? Khata balance se ye auto-adjust ho jayega.",
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: TextStyle(color: colors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _deleteSingleEntry(friend, tx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: colors.redAccent),
              child: const Text(
                "Delete",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 3. Poora Chat Clear Karna
  void _clearChatHistory(FriendModel friend) {
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = context.colors;
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: colors.border),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.cleaning_services_rounded,
                color: Colors.amber,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                "Clear Chat?",
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            "Kya aap '${friend.name}' ki puri statement history hatana chahte hain? Net balance ₹0 ho jayega.",
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: TextStyle(color: colors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _entryService.clearFriendHistory(friend);
                if (mounted) {
                  setState(() {});
                  AppToast.show(
                    context,
                    title: "Puri chat clear kar di gayi!",
                    type: ToastType.warning,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
              ),
              child: const Text(
                "Clear All",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 4. Friend Khata Delete Karna (With full transBox cleanup)
  void _confirmDeleteFriend(FriendModel friend) {
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = context.colors;
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: colors.border),
          ),
          title: Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: colors.redText, size: 22),
              const SizedBox(width: 8),
              Text(
                "Khata Delete Karein?",
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            "Kya aap sach me '${friend.name}' ka khata aur sare statement permanent delete karna chahte hain?",
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: TextStyle(color: colors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _entryService.clearFriendHistory(friend);
                await friend.delete();
                if (mounted) {
                  Navigator.of(context).pop();
                  AppToast.show(
                    context,
                    title: "${friend.name} ka khata delete ho gaya!",
                    type: ToastType.error,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: colors.redAccent),
              child: const Text(
                "Delete Khata",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Date parsing helper for transactions in history
  DateTime _extractEntryDate(Map<dynamic, dynamic> tx) {
    if (tx["timestamp"] is int) {
      return DateTime.fromMillisecondsSinceEpoch(tx["timestamp"] as int);
    }
    final transKey = tx["transKey"];
    if (transKey != null && _transBox.containsKey(transKey)) {
      final trans = _transBox.get(transKey);
      if (trans != null) {
        return trans.date;
      }
    }
    final raw = tx["date"]?.toString() ?? "";
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;

    try {
      final parts = raw.split(" ");
      if (parts.isNotEmpty && parts[0].contains("/")) {
        final dParts = parts[0].split("/");
        final day = int.parse(dParts[0]);
        final month = int.parse(dParts[1]);
        final now = DateTime.now();
        int hour = 0;
        int min = 0;
        if (parts.length > 1 && parts[1].contains(":")) {
          final tParts = parts[1].split(":");
          hour = int.parse(tParts[0]);
          min = int.parse(tParts[1]);
        }
        return DateTime(now.year, month, day, hour, min);
      }
    } catch (_) {}

    return DateTime.now();
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return "";
  }

  // Generates a clean, professional accounting statement without emojis
  String _generateProfessionalStatement({
    required FriendModel friend,
    required List<Map<dynamic, dynamic>> filteredList,
    required String periodLabel,
  }) {
    int totalDiya = 0;
    int totalLiya = 0;

    for (var tx in filteredList) {
      final amt = (tx["amount"] as num?)?.toInt() ?? 0;
      if (tx["type"] == "diya") {
        totalDiya += amt;
      } else if (tx["type"] == "liya") {
        totalLiya += amt;
      }
    }

    final int netBalance = totalDiya - totalLiya;
    final String netStatus;
    if (netBalance > 0) {
      netStatus = "Rs. $netBalance (To Receive / Lena)";
    } else if (netBalance < 0) {
      netStatus = "Rs. ${netBalance.abs()} (To Pay / Dena)";
    } else {
      netStatus = "Rs. 0 (Settled / Barabar)";
    }

    final now = DateTime.now();
    final generatedOn =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} "
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    final StringBuffer buffer = StringBuffer();
    buffer.writeln("----------------------------------------");
    buffer.writeln("           HISAAB STATEMENT            ");
    buffer.writeln("----------------------------------------");
    buffer.writeln("Name      : ${friend.name}");
    if (friend.phone.trim().isNotEmpty) {
      buffer.writeln("Phone     : ${friend.phone.trim()}");
    }
    buffer.writeln("Period    : $periodLabel");
    buffer.writeln("Date      : $generatedOn");
    buffer.writeln("----------------------------------------");
    buffer.writeln("SUMMARY:");
    buffer.writeln("Total Given (Diya)    : Rs. $totalDiya");
    buffer.writeln("Total Received (Liya) : Rs. $totalLiya");
    buffer.writeln("Net Balance           : $netStatus");
    buffer.writeln("----------------------------------------");
    buffer.writeln("TRANSACTIONS (${filteredList.length} Entries):");
    buffer.writeln("----------------------------------------");

    if (filteredList.isEmpty) {
      buffer.writeln("Koi entry nahi mili.");
    } else {
      for (int i = 0; i < filteredList.length; i++) {
        final tx = filteredList[i];
        final isDiya = tx["type"] == "diya";
        final amt = tx["amount"] ?? 0;
        final title = (tx["title"] ?? "Hisaab").toString().trim();
        final mode = (tx["mode"] ?? "UPI").toString().trim();
        final date = (tx["date"] ?? "").toString().trim();
        final sign = isDiya ? "(+)" : "(-)";
        final typeStr = isDiya ? "Diya" : "Liya";

        buffer.writeln("${i + 1}. $date | Rs. $amt $sign [$typeStr]");
        if (title.isNotEmpty && title.toLowerCase() != "hisaab") {
          buffer.writeln("   Note: $title");
        }
        buffer.writeln("   Mode: $mode");
        if (i < filteredList.length - 1) {
          buffer.writeln(". . . . . . . . . . . . . . . . . . . .");
        }
      }
    }

    buffer.writeln("----------------------------------------");
    buffer.writeln("Shared via Hisaab+");
    buffer.writeln("----------------------------------------");

    return buffer.toString();
  }

  // 5. WhatsApp / Share Hisaab with Date Range Filter & Professional Format
  void _shareHisaabOnWhatsApp(FriendModel friend) {
    String selectedFilter = "all"; // all, this_month, last_month, last_30_days, custom
    DateTimeRange? customRange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final now = DateTime.now();

            // Filter history based on selectedFilter
            final List<Map<dynamic, dynamic>> filteredHistory =
                friend.history.where((tx) {
              final d = _extractEntryDate(tx);
              if (selectedFilter == "this_month") {
                return d.year == now.year && d.month == now.month;
              } else if (selectedFilter == "custom" && customRange != null) {
                final start = DateTime(
                  customRange!.start.year,
                  customRange!.start.month,
                  customRange!.start.day,
                );
                final end = DateTime(
                  customRange!.end.year,
                  customRange!.end.month,
                  customRange!.end.day,
                  23,
                  59,
                  59,
                );
                return (d.isAfter(start) || d.isAtSameMomentAs(start)) &&
                    (d.isBefore(end) || d.isAtSameMomentAs(end));
              }
              return true;
            }).toList();

            // Calculate totals for preview
            int totalDiya = 0;
            int totalLiya = 0;
            for (var tx in filteredHistory) {
              final amt = (tx["amount"] as num?)?.toInt() ?? 0;
              if (tx["type"] == "diya") {
                totalDiya += amt;
              } else if (tx["type"] == "liya") {
                totalLiya += amt;
              }
            }
            final netBalance = totalDiya - totalLiya;

            String periodLabel = "All Time (Sabhi Len Den)";
            if (selectedFilter == "this_month") {
              periodLabel = "${_getMonthName(now.month)} ${now.year}";
            } else if (selectedFilter == "custom" && customRange != null) {
              periodLabel =
                  "${customRange!.start.day}/${customRange!.start.month}/${customRange!.start.year} to ${customRange!.end.day}/${customRange!.end.month}/${customRange!.end.year}";
            }

            final bottomPadding = MediaQuery.of(sheetCtx).viewInsets.bottom;
            final colors = context.colors;

            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomPadding),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: colors.border, width: 1.5),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Share Hisaab Statement",
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              friend.name,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.share_rounded,
                            color: Color(0xFF25D366),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Filter Selection Label
                    Text(
                      "Select Date Range",
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Filter Chips (Scrollable horizontal row)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildShareFilterChip(
                            colors: colors,
                            label: "Sabhi (All)",
                            isSelected: selectedFilter == "all",
                            onTap: () =>
                                setModalState(() => selectedFilter = "all"),
                          ),
                          _buildShareFilterChip(
                            colors: colors,
                            label: "Iss Mahine",
                            isSelected: selectedFilter == "this_month",
                            onTap: () => setModalState(
                              () => selectedFilter = "this_month",
                            ),
                          ),
                          _buildShareFilterChip(
                            colors: colors,
                            label: customRange != null
                                ? "${customRange!.start.day}/${customRange!.start.month} - ${customRange!.end.day}/${customRange!.end.month}"
                                : "Custom Range 📅",
                            isSelected: selectedFilter == "custom",
                            onTap: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                initialDateRange: customRange ??
                                    DateTimeRange(
                                      start: now.subtract(
                                        const Duration(days: 7),
                                      ),
                                      end: now,
                                    ),
                                builder: (ctx, child) {
                                  return Theme(
                                    data: colors.isDark
                                        ? ThemeData.dark().copyWith(
                                            colorScheme: const ColorScheme.dark(
                                              primary: lenaGreen,
                                              surface: surfaceCard,
                                            ),
                                          )
                                        : ThemeData.light().copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: colors.greenText,
                                              surface: colors.surface,
                                              onSurface: colors.textPrimary,
                                            ),
                                          ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setModalState(() {
                                  customRange = picked;
                                  selectedFilter = "custom";
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filtered Summary Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                periodLabel,
                                style: TextStyle(
                                  color: colors.blueAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: colors.border),
                                ),
                                child: Text(
                                  "${filteredHistory.length} Entries",
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 1,
                            color: colors.divider,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Total Given (Diya)",
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "₹$totalDiya",
                                    style: TextStyle(
                                      color: colors.isDark ? lenaGreenLight : colors.greenText,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "Total Received (Liya)",
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "₹$totalLiya",
                                    style: TextStyle(
                                      color: colors.isDark ? denaRedLight : colors.redText,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Net Balance:",
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                netBalance > 0
                                    ? "₹$netBalance (Lena Hai)"
                                    : (netBalance < 0
                                        ? "₹${netBalance.abs()} (Dena Hai)"
                                        : "₹0 (Settled)"),
                                style: TextStyle(
                                  color: netBalance > 0
                                      ? (colors.isDark ? lenaGreen : colors.greenText)
                                      : (netBalance < 0
                                          ? (colors.isDark ? denaRed : colors.redText)
                                          : colors.textMuted),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Prominent Primary Button: Share PDF Statement
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626), // Professional PDF Red
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 20,
                        ),
                        label: const Text(
                          "Share PDF Statement (Table)",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(sheetCtx);
                          try {
                            final pdfBytes =
                                await PdfStatementService.generateStatementPdf(
                              friend: friend,
                              filteredList: filteredHistory,
                              periodLabel: periodLabel,
                            );

                            final safeName = friend.name
                                .replaceAll(RegExp(r'[^\w\s]+'), '')
                                .trim()
                                .replaceAll(' ', '_');
                            final fileName =
                                'Hisaab_${safeName}_${now.day}_${now.month}_${now.year}.pdf';

                            await Printing.sharePdf(
                              bytes: pdfBytes,
                              filename: fileName,
                            );
                          } catch (e) {
                            if (mounted) {
                              AppToast.show(
                                this.context,
                                title: "PDF share karne me samasya aayi: $e",
                                type: ToastType.error,
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Secondary Action Buttons (Text Copy & Share)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              side: BorderSide(color: colors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text(
                              "Copy Text",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              final text = _generateProfessionalStatement(
                                friend: friend,
                                filteredList: filteredHistory,
                                periodLabel: periodLabel,
                              );
                              Clipboard.setData(ClipboardData(text: text));
                              Navigator.pop(sheetCtx);
                              AppToast.show(
                                this.context,
                                title: "Statement clipboard me copy ho gaya!",
                                type: ToastType.success,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              side: BorderSide(color: colors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            icon: const Icon(Icons.share_rounded, size: 16),
                            label: const Text(
                              "Share Text",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              final text = _generateProfessionalStatement(
                                friend: friend,
                                filteredList: filteredHistory,
                                periodLabel: periodLabel,
                              );
                              Navigator.pop(sheetCtx);
                              SharePlus.instance.share(
                                ShareParams(
                                  text: text,
                                  subject: "Hisaab Statement - ${friend.name}",
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShareFilterChip({
    required AppColors colors,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (colors.isDark ? surfaceHighlight : colors.greenPillBg)
                : colors.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (colors.isDark
                      ? lenaGreen.withValues(alpha: 0.8)
                      : colors.greenPillBorder)
                  : colors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? (colors.isDark ? Colors.white : colors.greenText)
                  : colors.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // 6. Tap-to-Edit Entry Bottom Sheet
  void _showEditEntrySheet(FriendModel friend, Map<dynamic, dynamic> tx) {
    final int currentAmount = (tx["amount"] as num?)?.toInt() ?? 0;
    final String currentTitle = tx["title"] ?? "";
    final String currentMode = tx["mode"] ?? "UPI";
    final String currentType = tx["type"] ?? "diya";

    final editAmountCtrl = TextEditingController(
      text: currentAmount > 0 ? "$currentAmount" : "",
    );
    final editNoteCtrl = TextEditingController(text: currentTitle);
    int selectedType = currentType == 'diya' ? 0 : 1;
    String selectedMode = currentMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setModalState) {
            final bottomPadding = MediaQuery.of(modalCtx).viewInsets.bottom;
            final colors = context.colors;

            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomPadding),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: colors.border, width: 1.5),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header with Delete shortcut
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              color: colors.textPrimary,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Edit Entry",
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: colors.redText,
                            size: 22,
                          ),
                          tooltip: "Delete Entry",
                          onPressed: () {
                            Navigator.pop(modalCtx);
                            _showEntryDeleteDialog(friend, tx);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Diya / Liya Toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setModalState(() => selectedType = 0),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedType == 0
                                      ? (colors.isDark
                                          ? const Color(0xB3022C22)
                                          : colors.greenPillBg)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: selectedType == 0
                                      ? Border.all(
                                          color: colors.isDark
                                              ? const Color(0x66047857)
                                              : colors.greenPillBorder,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 16,
                                      color: selectedType == 0
                                          ? (colors.isDark
                                              ? lenaGreenLight
                                              : colors.greenText)
                                          : colors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Diya (Udhar)",
                                      style: TextStyle(
                                        color: selectedType == 0
                                            ? (colors.isDark
                                                ? lenaGreenLight
                                                : colors.greenText)
                                            : colors.textMuted,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setModalState(() => selectedType = 1),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedType == 1
                                      ? (colors.isDark
                                          ? const Color(0xB34C0519)
                                          : colors.redPillBg)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: selectedType == 1
                                      ? Border.all(
                                          color: colors.isDark
                                              ? const Color(0x66BE123C)
                                              : colors.redPillBorder,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_downward_rounded,
                                      size: 16,
                                      color: selectedType == 1
                                          ? (colors.isDark
                                              ? denaRedLight
                                              : colors.redText)
                                          : colors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Liya (Paisa)",
                                      style: TextStyle(
                                        color: selectedType == 1
                                            ? (colors.isDark
                                                ? denaRedLight
                                                : colors.redText)
                                            : colors.textMuted,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Amount Field
                    Text(
                      "Amount (₹)",
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: colors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "₹",
                            style: TextStyle(
                              color: selectedType == 0
                                  ? (colors.isDark ? lenaGreenLight : colors.greenText)
                                  : (colors.isDark ? denaRedLight : colors.redText),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: editAmountCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: "0",
                                hintStyle: TextStyle(color: colors.textMuted),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Note Field
                    Text(
                      "Note / Title",
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: colors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            color: colors.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: editNoteCtrl,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: "Hisaab ka note...",
                                hintStyle: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Payment Mode Chips
                    Text(
                      "Payment Mode",
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: ["UPI", "Cash", "ATM"].map((mode) {
                        final isSelected = selectedMode == mode;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () =>
                                setModalState(() => selectedMode = mode),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (colors.isDark ? surfaceHighlight : colors.greenPillBg)
                                    : colors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? (colors.isDark ? lenaGreenLight.withValues(alpha: 0.6) : colors.greenPillBorder)
                                      : colors.border,
                                ),
                              ),
                              child: Text(
                                mode,
                                style: TextStyle(
                                  color: isSelected
                                      ? (colors.isDark ? Colors.white : colors.greenText)
                                      : colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.isDark ? Colors.white : colors.greenAccent,
                          foregroundColor: colors.isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final newAmt =
                              int.tryParse(editAmountCtrl.text.trim()) ?? 0;
                          if (newAmt <= 0) {
                            AppToast.show(
                              modalCtx,
                              title: "Valid amount daalein!",
                              type: ToastType.warning,
                            );
                            return;
                          }
                          final newNote = editNoteCtrl.text.trim().isEmpty
                              ? (selectedType == 0
                                  ? "Udhar Diya"
                                  : "Paisa Liya")
                              : editNoteCtrl.text.trim();

                          Navigator.pop(modalCtx);

                          await _entryService.editSingleFriendTransaction(
                            friend: friend,
                            targetTx: tx,
                            newAmount: newAmt,
                            newNote: newNote,
                            newPaymentMode: selectedMode,
                            newType: selectedType == 0 ? 'diya' : 'liya',
                          );

                          if (mounted) {
                            setState(() {});
                            AppToast.show(
                              context,
                              title: "Entry update ho gayi!",
                              type: ToastType.success,
                            );
                          }
                        },
                        child: Text(
                          "Update Entry",
                          style: TextStyle(
                            color: colors.isDark ? Colors.black : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addNewEntry() {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      AppToast.show(context, title: "Amount daalein!", type: ToastType.warning);
      return;
    }

    final noteText = _noteController.text.trim().isEmpty
        ? (_entryType == 0 ? "Udhar Diya" : "Paisa Liya")
        : _noteController.text.trim();

    // ERROR FIX: Naye Single Friend method ko call karein
    final targetFriendKey =
        widget.friendKey ?? _resolveFriend(_friendsBox)?.key;

    if (targetFriendKey != null) {
      _entryService.saveSingleFriendTransaction(
        friendKey: targetFriendKey,
        amount: amount,
        txType: _entryType == 0 ? 'diya' : 'liya',
        note: noteText,
        paymentMode: _selectedPaymentMode,
      );
    }

    _amountController.clear();
    _noteController.clear();
    FocusScope.of(context).unfocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });

    AppToast.show(
      context,
      title: "Entry save ho gayi!",
      type: ToastType.success,
    );
  }

  void _closeChatPage() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ValueListenableBuilder<Box<FriendModel>>(
      valueListenable: _friendsBox.listenable(),
      builder: (context, box, _) {
        final FriendModel? currentFriend = _resolveFriend(box);

        final String displayName = currentFriend?.name ?? widget.friendName;
        final int currentBalance =
            currentFriend?.balance ?? (int.tryParse(widget.netAmount) ?? 0);
        final bool isLena = currentFriend != null
            ? currentFriend.type == 'lena'
            : widget.isLena;
        final bool isSettled = currentBalance == 0;

        final historyList = currentFriend?.history ?? [];

        // Dost details from FriendModel
        final String phone = currentFriend?.phone.trim() ?? "";
        final String rawDesc = currentFriend?.desc.trim() ?? "";
        String descNote = rawDesc;
        String tag = "";
        if (rawDesc.contains("•")) {
          final parts = rawDesc.split("•");
          descNote = parts[0].trim();
          tag = parts[1].trim();
        }

        return Scaffold(
          backgroundColor: colors.bg,
          body: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: colors.isDark ? 0.25 : 0.05,
                  child: Image.asset(
                    'assets/images/chat_bg.png',
                    fit: BoxFit.cover,
                    repeat: ImageRepeat.repeat,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    // Top App Bar
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 8,
                        top: 4,
                        bottom: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _closeChatPage,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: colors.textPrimary,
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                displayName,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: colors.textPrimary,
                              size: 20,
                            ),
                            color: colors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: colors.border),
                            ),
                            onSelected: (val) {
                              if (currentFriend == null) return;
                              if (val == 'share_whatsapp') {
                                _shareHisaabOnWhatsApp(currentFriend);
                              } else if (val == 'clear_chat') {
                                _clearChatHistory(currentFriend);
                              } else if (val == 'delete_khata') {
                                _confirmDeleteFriend(currentFriend);
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'share_whatsapp',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.share_rounded,
                                      color: Color(0xFF25D366),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "WhatsApp / Share Hisaab",
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'clear_chat',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.cleaning_services_rounded,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Clear Chat",
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete_khata',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_forever_rounded,
                                      color: colors.redText,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Delete Khata",
                                      style: TextStyle(
                                        color: colors.redText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Top Balance Card with EXPANDABLE DETAILS
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.border),
                          boxShadow: colors.isDark ? [] : [colors.cardShadow],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isSettled
                                          ? "HISAAB CLEAR (CHUKTA)"
                                          : (isLena
                                                ? "NET LENA HAI"
                                                : "NET DENA HAI"),
                                      style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          "₹$currentBalance",
                                          style: TextStyle(
                                            color: isSettled
                                                ? colors.textSecondary
                                                : (isLena
                                                      ? (colors.isDark ? lenaGreen : colors.greenText)
                                                      : (colors.isDark ? denaRed : colors.redText)),
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isSettled
                                              ? "(Settled)"
                                              : (isLena
                                                    ? "(Receive)"
                                                    : "(Pay)"),
                                          style: TextStyle(
                                            color: isSettled
                                                ? colors.textMuted
                                                : (isLena
                                                      ? (colors.isDark
                                                          ? const Color(0xE634D399)
                                                          : colors.greenText)
                                                      : (colors.isDark
                                                          ? const Color(0xE6FB7185)
                                                          : colors.redText)),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // DETAILS BUTTON (Replaces old static Ledger button)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isDetailsExpanded = !_isDetailsExpanded;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isDetailsExpanded
                                          ? (colors.isDark
                                              ? surfaceHighlight
                                              : colors.blueAccent.withValues(alpha: 0.12))
                                          : colors.surfaceSecondary,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _isDetailsExpanded
                                            ? colors.blueAccent.withValues(alpha: 0.5)
                                            : colors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Details",
                                          style: TextStyle(
                                            color: _isDetailsExpanded
                                                ? colors.blueAccent
                                                : colors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        AnimatedRotation(
                                          turns: _isDetailsExpanded ? 0.5 : 0.0,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: _isDetailsExpanded
                                                ? colors.blueAccent
                                                : colors.textSecondary,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // EXPANDED DOST DETAILS DRAWER
                            if (_isDetailsExpanded) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: colors.divider,
                              ),
                              const SizedBox(height: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Mobile Number
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone_rounded,
                                        size: 13,
                                        color: colors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        phone.isNotEmpty
                                            ? phone
                                            : "Mobile number nahi joda gaya",
                                        style: TextStyle(
                                          color: phone.isNotEmpty
                                              ? colors.textPrimary
                                              : colors.textMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Description & Tag Badge
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.notes_rounded,
                                        size: 13,
                                        color: colors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          descNote.isNotEmpty
                                              ? descNote
                                              : "Koi note/description nahi",
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 11.5,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (tag.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.isDark
                                                ? const Color(0xFF0C1929)
                                                : colors.blueAccent.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: colors.blueAccent.withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Text(
                                            tag,
                                            style: TextStyle(
                                              color: colors.blueAccent,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Chat Statements List
                    Expanded(
                      child: historyList.isEmpty
                          ? Center(
                              child: Text(
                                "Abhi tak koi entry nahi hai",
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: historyList.length,
                              itemBuilder: (context, index) {
                                final msg = historyList[index];
                                final isDiya = msg["type"] == 'diya';

                                return Align(
                                  alignment: isDiya
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (currentFriend != null) {
                                        _showEditEntrySheet(currentFriend, msg);
                                      }
                                    },
                                    onLongPress: () {
                                      if (currentFriend != null) {
                                        _showEntryDeleteDialog(
                                          currentFriend,
                                          msg,
                                        );
                                      }
                                    },
                                    child: Container(
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.85,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colors.isDark
                                            ? (isDiya
                                                    ? const Color(0xFF121415)
                                                    : surfaceCard)
                                                .withValues(alpha: 0.88)
                                            : (isDiya
                                                    ? colors.greenPillBg
                                                    : colors.redPillBg),
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          bottomLeft: const Radius.circular(16),
                                          bottomRight: const Radius.circular(
                                            16,
                                          ),
                                          topRight: isDiya
                                              ? const Radius.circular(4)
                                              : const Radius.circular(16),
                                        ),
                                        border: Border.all(
                                          color: colors.isDark
                                              ? borderCustom
                                              : (isDiya
                                                  ? colors.greenPillBorder
                                                  : colors.redPillBorder),
                                        ),
                                        boxShadow: colors.isDark ? [] : [colors.cardShadow],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: colors.divider,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      "₹${msg["amount"]}",
                                                      style: TextStyle(
                                                        color: isDiya
                                                            ? (colors.isDark
                                                                ? lenaGreenLight
                                                                : colors.greenText)
                                                            : (colors.isDark
                                                                ? denaRedLight
                                                                : colors.redText),
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      isDiya
                                                          ? "(Diya)"
                                                          : "(Liya)",
                                                      style: TextStyle(
                                                        color: isDiya
                                                            ? (colors.isDark
                                                                ? const Color(
                                                                    0xCC6EE7B7,
                                                                  )
                                                                : colors.greenText)
                                                            : (colors.isDark
                                                                ? const Color(
                                                                    0xCCFDA4AF,
                                                                  )
                                                                : colors.redText),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: colors.surfaceSecondary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: colors.border,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    msg["mode"] ?? "UPI",
                                                    style: TextStyle(
                                                      color: colors.textSecondary,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            msg["title"] ?? "Hisaab",
                                            style: TextStyle(
                                              color: colors.textPrimary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.edit_rounded,
                                                    size: 11,
                                                    color: colors.textMuted,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "Tap to edit",
                                                    style: TextStyle(
                                                      color: colors.textMuted,
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    msg["date"] ?? "",
                                                    style: TextStyle(
                                                      color: colors.textMuted,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  if (isDiya) ...[
                                                    const SizedBox(width: 4),
                                                    Icon(
                                                      Icons.done_all_rounded,
                                                      size: 12,
                                                      color: colors.isDark
                                                          ? lenaGreenLight
                                                          : colors.greenText,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Bottom Dock Animated CrossFade (Auto hides on scroll)
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 220),
                      crossFadeState: _isBottomDockVisible
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: _buildBottomDock(context),
                      secondChild: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // Floating Restore Button when Dock is Hidden
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                bottom: _isBottomDockVisible ? -60 : 20,
                right: 20,
                child: GestureDetector(
                  onTap: () => setState(() => _isBottomDockVisible = true),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (colors.isDark ? lenaGreen : colors.greenText)
                            .withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: colors.isDark ? 0.5 : 0.15,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: colors.isDark ? Colors.white : colors.greenText,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomDock(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: colors.isDark
            ? oledBg.withValues(alpha: 0.96)
            : colors.surface.withValues(alpha: 0.98),
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  color: colors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    style: TextStyle(color: colors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Hisaab ka note likhein...",
                      hintStyle: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  color: colors.surface,
                  onSelected: (val) =>
                      setState(() => _selectedPaymentMode = val),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: "UPI",
                      child: Text("UPI", style: TextStyle(color: colors.textPrimary)),
                    ),
                    PopupMenuItem(
                      value: "Cash",
                      child: Text(
                        "Cash",
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    ),
                    PopupMenuItem(
                      value: "ATM",
                      child: Text("ATM", style: TextStyle(color: colors.textPrimary)),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 14,
                          color: colors.isDark ? lenaGreenLight : colors.greenText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedPaymentMode,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.expand_less_rounded,
                          size: 14,
                          color: colors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _entryType = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _entryType == 0
                            ? (colors.isDark
                                ? const Color(0xB3022C22)
                                : colors.greenPillBg)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: _entryType == 0
                            ? Border.all(
                                color: colors.isDark
                                    ? const Color(0x66047857)
                                    : colors.greenPillBorder,
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 16,
                            color: _entryType == 0
                                ? (colors.isDark
                                    ? const Color(0xFF6EE7B7)
                                    : colors.greenText)
                                : colors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Diya",
                            style: TextStyle(
                              color: _entryType == 0
                                  ? (colors.isDark
                                      ? const Color(0xFF6EE7B7)
                                      : colors.greenText)
                                  : colors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _entryType = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _entryType == 1
                            ? (colors.isDark
                                ? const Color(0xB34C0519)
                                : colors.redPillBg)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: _entryType == 1
                            ? Border.all(
                                color: colors.isDark
                                    ? const Color(0x66BE123C)
                                    : colors.redPillBorder,
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 16,
                            color: _entryType == 1
                                ? (colors.isDark
                                    ? const Color(0xFFFDA4AF)
                                    : colors.redText)
                                : colors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Liya",
                            style: TextStyle(
                              color: _entryType == 1
                                  ? (colors.isDark
                                      ? const Color(0xFFFDA4AF)
                                      : colors.redText)
                                  : colors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "₹",
                        style: TextStyle(
                          color: colors.isDark
                              ? lenaGreenLight
                              : colors.greenText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: "Amount",
                            hintStyle: TextStyle(
                              color: colors.textMuted,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _addNewEntry,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: colors.isDark
                        ? Colors.white
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colors.isDark ? Colors.black26 : Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Save",
                        style: TextStyle(
                          color: colors.isDark ? Colors.black : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check_rounded,
                        color: colors.isDark ? Colors.black : Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _closeChatPage,
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: colors.surfaceSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close_rounded,
                      color: colors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: 128,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

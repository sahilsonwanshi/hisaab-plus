import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/friend_model.dart';
import '../services/hisaab_entry_service.dart';
import '../widgets/custom_toast.dart';

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
  static const Color surfaceSecondary = Color(0xFF18181B);
  static const Color surfaceHighlight = Color(0xFF202024);
  static const Color borderCustom = Color(0xFF242429);

  static const Color lenaGreen = Color(0xFF10B981);
  static const Color lenaGreenLight = Color(0xFF34D399);
  static const Color denaRed = Color(0xFFF43F5E);
  static const Color denaRedLight = Color(0xFFFB7185);

  bool _isDetailsExpanded = false;
  int _entryType = 0; // 0: Diya, 1: Liya
  String _selectedPaymentMode = "UPI";
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late Box<FriendModel> _friendsBox;
  late HisaabEntryService _entryService;

  @override
  void initState() {
    super.initState();
    _friendsBox = Hive.box<FriendModel>('friends_box');
    _entryService = HisaabEntryService(
      friendsBox: _friendsBox,
      transBox: Hive.box('transactions_box'),
    );
  }

  @override
  void dispose() {
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

  // 1. Single entry delete + balance auto-adjustment
  void _deleteSingleEntry(FriendModel friend, Map<dynamic, dynamic> targetTx) {
    final int amount = (targetTx["amount"] as num?)?.toInt() ?? 0;
    final String type = targetTx["type"] ?? "diya";

    setState(() {
      friend.history.remove(targetTx);

      if (type == "diya") {
        friend.balance -= amount;
      } else if (type == "liya") {
        friend.balance += amount;
      }

      if (friend.balance > 0) {
        friend.type = "lena";
      } else if (friend.balance < 0) {
        friend.type = "dena";
      } else {
        friend.balance = 0;
        friend.type = "settled";
      }

      if (friend.history.isNotEmpty) {
        friend.lastMessage = friend.history.last["title"] ?? "";
        friend.lastDate = friend.history.last["date"] ?? "";
      } else {
        friend.lastMessage = "Khata ready";
        friend.lastDate = "";
      }
    });

    friend.save();

    AppToast.show(
      context,
      title: "'${targetTx['title']}' entry delete ho gayi!",
      type: ToastType.error,
    );
  }

  // 2. Long Press Entry Delete Dialog
  void _showEntryDeleteDialog(FriendModel friend, Map<dynamic, dynamic> tx) {
    final int amount = (tx["amount"] as num?)?.toInt() ?? 0;
    final String title = tx["title"] ?? "Hisaab";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceHighlight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: denaRed, size: 22),
            SizedBox(width: 8),
            Text(
              "Entry Delete Karein?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "Kya aap '$title' (₹$amount) ko delete karna chahte hain? Khata balance se ye auto-adjust ho jayega.",
          style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSingleEntry(friend, tx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: denaRed),
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

  // 3. Poora Chat Clear Karna
  void _clearChatHistory(FriendModel friend) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceHighlight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(
              Icons.cleaning_services_rounded,
              color: Colors.amber,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              "Clear Chat?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "Kya aap '${friend.name}' ki puri statement history hatana chahte hain? Net balance ₹0 ho jayega.",
          style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                friend.history.clear();
                friend.balance = 0;
                friend.type = "settled";
                friend.lastMessage = "Chat cleared";
                friend.lastDate = "Aaj";
              });
              friend.save();
              Navigator.pop(ctx);
              AppToast.show(
                context,
                title: "Puri chat clear kar di gayi!",
                type: ToastType.warning,
              );
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
      ),
    );
  }

  // 4. Friend Khata Delete Karna
  void _confirmDeleteFriend(FriendModel friend) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceHighlight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: denaRed, size: 22),
            SizedBox(width: 8),
            Text(
              "Khata Delete Karein?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "Kya aap sach me '${friend.name}' ka khata aur sare statement permanent delete karna chahte hain?",
          style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              friend.delete();
              Navigator.of(context).pop();
              AppToast.show(
                context,
                title: "${friend.name} ka khata delete ho gaya!",
                type: ToastType.error,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: denaRed),
            child: const Text(
              "Delete Khata",
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

  void _addNewEntry() {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      AppToast.show(context, title: "Amount daalein!", type: ToastType.warning);
      return;
    }

    final noteText = _noteController.text.trim().isEmpty
        ? (_entryType == 0 ? "Udhar Diya" : "Paisa Liya")
        : _noteController.text.trim();

    if (widget.friendKey != null) {
      _entryService.saveTransaction(
        selectedFriendKeys: {widget.friendKey},
        totalAmount: amount,
        txType: _entryType == 0 ? 'diya' : 'liya',
        note: noteText,
        paymentMode: _selectedPaymentMode,
      );
    } else {
      final currentFriend = _resolveFriend(_friendsBox);
      if (currentFriend != null) {
        _entryService.saveTransaction(
          selectedFriendKeys: {currentFriend.key},
          totalAmount: amount,
          txType: _entryType == 0 ? 'diya' : 'liya',
          note: noteText,
          paymentMode: _selectedPaymentMode,
        );
      }
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
          backgroundColor: oledBg,
          body: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.25,
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
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Color(0xFFA3A3A3),
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Color(0xFFD4D4D4),
                              size: 20,
                            ),
                            color: surfaceHighlight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: borderCustom),
                            ),
                            onSelected: (val) {
                              if (currentFriend == null) return;
                              if (val == 'clear_chat') {
                                _clearChatHistory(currentFriend);
                              } else if (val == 'delete_khata') {
                                _confirmDeleteFriend(currentFriend);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'clear_chat',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.cleaning_services_rounded,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Clear Chat",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete_khata',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_forever_rounded,
                                      color: denaRed,
                                      size: 18,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Delete Khata",
                                      style: TextStyle(
                                        color: denaRed,
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
                          color: surfaceCard.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderCustom),
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
                                      style: const TextStyle(
                                        color: Color(0xFFA3A3A3),
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
                                                ? Colors.white70
                                                : (isLena
                                                      ? lenaGreen
                                                      : denaRed),
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
                                                ? Colors.white54
                                                : (isLena
                                                      ? const Color(0xE634D399)
                                                      : const Color(
                                                          0xE6FB7185,
                                                        )),
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
                                          ? surfaceHighlight
                                          : surfaceSecondary,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _isDetailsExpanded
                                            ? const Color(0xFF38BDF8)
                                                  .withValues(alpha: 0.5)
                                            : borderCustom,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Details",
                                          style: TextStyle(
                                            color: _isDetailsExpanded
                                                ? const Color(0xFF38BDF8)
                                                : const Color(0xFFD4D4D4),
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
                                                ? const Color(0xFF38BDF8)
                                                : const Color(0xFFD4D4D4),
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
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                              const SizedBox(height: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Mobile Number
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_rounded,
                                        size: 13,
                                        color: Color(0xFFA3A3A3),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        phone.isNotEmpty
                                            ? phone
                                            : "Mobile number nahi joda gaya",
                                        style: TextStyle(
                                          color: phone.isNotEmpty
                                              ? Colors.white
                                              : Colors.white38,
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
                                      const Icon(
                                        Icons.notes_rounded,
                                        size: 13,
                                        color: Color(0xFFA3A3A3),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          descNote.isNotEmpty
                                              ? descNote
                                              : "Koi note/description nahi",
                                          style: const TextStyle(
                                            color: Color(0xFFD4D4D4),
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
                                            color: const Color(0xFF0C1929),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF0284C7)
                                                  .withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Text(
                                            tag,
                                            style: const TextStyle(
                                              color: Color(0xFF38BDF8),
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
                          ? const Center(
                              child: Text(
                                "Abhi tak koi entry nahi hai",
                                style: TextStyle(
                                  color: Color(0xFFA3A3A3),
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
                                        color:
                                            (isDiya
                                                    ? const Color(0xFF121415)
                                                    : surfaceCard)
                                                .withValues(alpha: 0.88),
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
                                        border: Border.all(color: borderCustom),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.only(
                                              bottom: 6,
                                            ),
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Color(0x0DFFFFFF),
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
                                                      "${isDiya ? '+' : '-'}₹${msg["amount"]}",
                                                      style: TextStyle(
                                                        color: isDiya
                                                            ? lenaGreenLight
                                                            : denaRed,
                                                        fontSize: 14,
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
                                                            ? const Color(
                                                                0xCC6EE7B7,
                                                              )
                                                            : const Color(
                                                                0xCCFDA4AF,
                                                              ),
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
                                                    color: surfaceHighlight,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: borderCustom,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    msg["mode"] ?? "UPI",
                                                    style: const TextStyle(
                                                      color: Color(0xFFD4D4D4),
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
                                              color: isDiya
                                                  ? const Color(0xFFE5E5E5)
                                                  : const Color(0xFFD4D4D4),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const SizedBox.shrink(),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    msg["date"] ?? "",
                                                    style: const TextStyle(
                                                      color: Color(0xFFD4D4D4),
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  if (isDiya) ...[
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons.done_all_rounded,
                                                      size: 12,
                                                      color: lenaGreenLight,
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

                    // Bottom Dock
                    _buildBottomDock(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomDock() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: oledBg.withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: borderCustom)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCustom),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFFA3A3A3),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: "Hisaab ka note likhein...",
                      hintStyle: TextStyle(
                        color: Color(0xFF737373),
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  color: surfaceHighlight,
                  onSelected: (val) =>
                      setState(() => _selectedPaymentMode = val),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: "UPI",
                      child: Text("UPI", style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem(
                      value: "Cash",
                      child: Text(
                        "Cash",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const PopupMenuItem(
                      value: "ATM",
                      child: Text("ATM", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceHighlight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderCustom),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 14,
                          color: lenaGreenLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedPaymentMode,
                          style: const TextStyle(
                            color: Color(0xFFE5E5E5),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.expand_less_rounded,
                          size: 14,
                          color: Color(0xFFA3A3A3),
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
              color: surfaceSecondary.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCustom),
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
                            ? const Color(0xB3022C22)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: _entryType == 0
                            ? Border.all(color: const Color(0x66047857))
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 16,
                            color: _entryType == 0
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFFA3A3A3),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Diya",
                            style: TextStyle(
                              color: _entryType == 0
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFFA3A3A3),
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
                            ? const Color(0xB34C0519)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: _entryType == 1
                            ? Border.all(color: const Color(0x66BE123C))
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 16,
                            color: _entryType == 1
                                ? const Color(0xFFFDA4AF)
                                : const Color(0xFFA3A3A3),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Liya",
                            style: TextStyle(
                              color: _entryType == 1
                                  ? const Color(0xFFFDA4AF)
                                  : const Color(0xFFA3A3A3),
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
                    color: surfaceSecondary,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderCustom),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        "₹",
                        style: TextStyle(
                          color: lenaGreenLight,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Amount",
                            hintStyle: TextStyle(
                              color: Color(0xFF737373),
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
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _addNewEntry,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Save",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.check_rounded, color: Colors.black, size: 16),
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
                    color: surfaceSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderCustom),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.close_rounded,
                      color: Color(0xFFD4D4D4),
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
              color: const Color(0x6652525B),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

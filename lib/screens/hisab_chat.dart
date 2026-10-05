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
        final FriendModel? currentFriend = widget.friendKey != null
            ? box.get(widget.friendKey)
            : null;

        final String displayName = currentFriend?.name ?? widget.friendName;
        final int currentBalance =
            currentFriend?.balance ?? (int.tryParse(widget.netAmount) ?? 0);
        final bool isLena = currentFriend != null
            ? currentFriend.type == 'lena'
            : widget.isLena;
        final bool isSettled = currentBalance == 0;

        final historyList = currentFriend?.history ?? [];

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
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 14,
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
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.more_vert_rounded,
                              color: Color(0xFFD4D4D4),
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceCard.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderCustom),
                        ),
                        child: Row(
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
                                            : (isLena ? lenaGreen : denaRed),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isSettled
                                          ? "(Settled)"
                                          : (isLena ? "(Receive)" : "(Pay)"),
                                      style: TextStyle(
                                        color: isSettled
                                            ? Colors.white54
                                            : (isLena
                                                  ? const Color(0xE634D399)
                                                  : const Color(0xE6FB7185)),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceSecondary,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderCustom),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    "Ledger",
                                    style: TextStyle(
                                      color: Color(0xFFD4D4D4),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    color: Color(0xFFD4D4D4),
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                                        bottomRight: const Radius.circular(16),
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
                                                MainAxisAlignment.spaceBetween,
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
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: borderCustom,
                                                  ),
                                                ),
                                                child: Text(
                                                  msg["mode"] ?? "UPI",
                                                  style: const TextStyle(
                                                    color: Color(0xFFD4D4D4),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
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
                                );
                              },
                            ),
                    ),
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
                // BUG 3 FIX: Only UPI, Cash, ATM
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

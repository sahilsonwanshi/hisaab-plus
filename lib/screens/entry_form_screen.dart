import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/friend_model.dart';
import '../models/transaction_model.dart';
import '../models/entry_form_state.dart';
import '../services/hisaab_entry_service.dart';
import '../widgets/custom_toast.dart';
import '../widgets/entry_form_widgets.dart';

class EntryFormView extends StatefulWidget {
  final int entryType;
  final VoidCallback onClose;

  const EntryFormView({
    super.key,
    required this.entryType,
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
  late HisaabEntryService _entryService;

  late EntryFormStateData _stateData;

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _newFriendNameCtrl = TextEditingController();
  final TextEditingController _newFriendPhoneCtrl = TextEditingController();
  final TextEditingController _newFriendNoteCtrl = TextEditingController();

  final List<Map<String, dynamic>> _paymentOptions = [
    {'name': 'UPI', 'icon': Icons.account_balance_wallet_rounded},
    {'name': 'Cash', 'icon': Icons.payments_rounded},
    {'name': 'ATM', 'icon': Icons.credit_card_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _friendsBox = Hive.box<FriendModel>('friends_box');
    _transBox = Hive.box<TransactionModel>('transactions_box');
    _tagsBox = Hive.box<String>('tags_box');

    _entryService = HisaabEntryService(
      friendsBox: _friendsBox,
      transBox: _transBox,
    );

    // Default 3 tags agar pehli baar app run ho rahi ho
    if (_tagsBox.isEmpty) {
      _tagsBox.addAll(['Personal', 'Business', 'College']);
    }

    _stateData = EntryFormStateData(
      txType: widget.entryType == 2 ? 'liya' : 'diya',
      selectedTag: null,
      selectedFriendKeys: {},
      availableTags: _tagsBox.values.toList(), // Hive se permanently load
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _noteCtrl.dispose();
    _amountCtrl.dispose();
    _newFriendNameCtrl.dispose();
    _newFriendPhoneCtrl.dispose();
    _newFriendNoteCtrl.dispose();
    super.dispose();
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
      _stateData.selectedFriendKeys.clear();
      _stateData.selectedFriendKeys.add(key);
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

  void _handleSaveHisaab() {
    final int amount = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      AppToast.show(
        context,
        title: "Kripya valid amount darj karein!",
        type: ToastType.warning,
      );
      return;
    }

    if (_stateData.selectedFriendKeys.isEmpty) {
      AppToast.show(
        context,
        title: "Kripya kam se kam ek dost chunein!",
        type: ToastType.warning,
      );
      return;
    }

    final noteText = _noteCtrl.text.trim();

    _entryService.saveTransaction(
      selectedFriendKeys: _stateData.selectedFriendKeys,
      totalAmount: amount,
      txType: _stateData.txType,
      note: noteText,
      paymentMode: _stateData.selectedPaymentMode,
    );

    _amountCtrl.clear();
    _noteCtrl.clear();
    FocusScope.of(context).unfocus();

    AppToast.show(
      context,
      title: "₹$amount ka hisaab safalta se jod diya gaya!",
      type: ToastType.success,
    );
    widget.onClose();
  }

  void _showPaymentModeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: borderCustom),
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
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Payment Mode Chunein",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ..._paymentOptions.map((opt) {
                  final isSelected =
                      _stateData.selectedPaymentMode == opt['name'];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    leading: Icon(
                      opt['icon'] as IconData,
                      color: isSelected ? lenaGreen : neutral300,
                      size: 20,
                    ),
                    title: Text(
                      opt['name'] as String,
                      style: TextStyle(
                        color: isSelected ? lenaGreen : Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: lenaGreen,
                            size: 18,
                          )
                        : null,
                    onTap: () {
                      setState(
                        () => _stateData.selectedPaymentMode =
                            opt['name'] as String,
                      );
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: bgOled,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: ValueListenableBuilder<Box<FriendModel>>(
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

            final selectedCount = _stateData.selectedFriendKeys.length;
            String activeFriendName = "Koi dost select karein";
            String activeFriendBalance = "Khata Chunein";
            bool isPositiveBalance = true;

            if (selectedCount == 1) {
              final singleKey = _stateData.selectedFriendKeys.first;
              final FriendModel? f = _friendsBox.get(singleKey);
              if (f != null) {
                activeFriendName = f.name;
                final isLena = f.type == 'lena';
                isPositiveBalance = isLena;
                activeFriendBalance =
                    "${isLena ? '+₹' : '-₹'}${f.balance} ${isLena ? 'lena' : 'dena'}";
              }
            } else if (selectedCount > 1) {
              activeFriendName = "$selectedCount Dost Chune Hue";
              activeFriendBalance = "Group Split";
            }

            return Column(
              children: [
                EntryTopNavHeader(
                  selectedCount: selectedCount,
                  onBack: widget.onClose,
                ),
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
                        // PERMANENT HIVE SAVE FIX:
                        onCustomTagAdded: (newTag) {
                          setState(() {
                            if (!_tagsBox.values.contains(newTag)) {
                              _tagsBox.add(newTag); // Local database me save
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
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: Text(
                              "Koi dost nahi mila",
                              style: TextStyle(color: neutral500, fontSize: 12),
                            ),
                          ),
                        )
                      else
                        ...filteredEntries.map((entry) {
                          final key = entry.key;
                          final friend = entry.value;
                          final isSelected = _stateData.selectedFriendKeys
                              .contains(key);
                          return SelectableFriendCardWidget(
                            friendKey: key,
                            friend: friend,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _stateData.selectedFriendKeys.remove(key);
                                } else {
                                  _stateData.selectedFriendKeys.add(key);
                                }
                              });
                            },
                          );
                        }),
                    ],
                  ),
                ),
                EntryBottomDockWidget(
                  activeFriendName: activeFriendName,
                  activeBalance: activeFriendBalance,
                  isPositive: isPositiveBalance,
                  selectedCount: selectedCount,
                  noteCtrl: _noteCtrl,
                  amountCtrl: _amountCtrl,
                  selectedPaymentMode: _stateData.selectedPaymentMode,
                  txType: _stateData.txType,
                  onPaymentModeTap: _showPaymentModeSheet,
                  onTxTypeChanged: (type) =>
                      setState(() => _stateData.txType = type),
                  onSave: _handleSaveHisaab,
                  onClosePage: widget.onClose,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

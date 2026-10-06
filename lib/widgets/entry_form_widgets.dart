import 'package:flutter/material.dart';

import '../models/friend_model.dart';

// UI Palette Constants
const Color bgOled = Color(0xFF000000);
const Color surfaceCard = Color(0xFF121415);
const Color surfaceSec = Color(0xFF18181B);
const Color surfaceHighlight = Color(0xFF202024);
const Color borderCustom = Color(0xFF242429);
const Color lenaGreen = Color(0xFF10B981);
const Color denaRed = Color(0xFFF43F5E);
const Color neutral300 = Color(0xFFD4D4D8);
const Color neutral400 = Color(0xFFA1A1AA);
const Color neutral500 = Color(0xFF71717A);
const Color neutral600 = Color(0xFF52525B);

// -------------------------------------------------------------
// FILTER ITEM MODEL
// -------------------------------------------------------------
class FilterItem {
  final String id;
  final String label;
  final int count;
  final String type;

  FilterItem({
    required this.id,
    required this.label,
    required this.count,
    required this.type,
  });
}

// -------------------------------------------------------------
// 1. TOP NAVIGATION HEADER
// -------------------------------------------------------------
class EntryTopNavHeader extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onBack;

  const EntryTopNavHeader({
    super.key,
    required this.selectedCount,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: neutral400,
                  size: 18,
                ),
                onPressed: onBack,
              ),
              const Text(
                "Choose Friends",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: selectedCount > 0 ? const Color(0xFF0F291C) : surfaceSec,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selectedCount > 0
                    ? const Color(0xFF00E676).withValues(alpha: 0.4)
                    : borderCustom,
              ),
            ),
            child: Text(
              selectedCount == 1
                  ? "1 Selected"
                  : (selectedCount > 1
                        ? "$selectedCount Selected"
                        : "0 Selected"),
              style: TextStyle(
                color: selectedCount > 0 ? const Color(0xFF34D399) : neutral400,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 2. SEARCH & DYNAMIC FILTER PILLS BAR
// -------------------------------------------------------------
class EntrySearchBarAndFilters extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String activeFilter;
  final List<FilterItem> filterList;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onSearchChanged;

  const EntrySearchBarAndFilters({
    super.key,
    required this.searchCtrl,
    required this.activeFilter,
    required this.filterList,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  Widget _buildFilterPill(FilterItem item) {
    final isSelected = activeFilter == item.id;
    Color textColor = neutral400;

    if (isSelected) {
      textColor = Colors.black;
    } else if (item.type == 'lena') {
      textColor = lenaGreen;
    } else if (item.type == 'dena') {
      textColor = const Color(0xFFFB7185);
    } else if (item.type == 'tag') {
      textColor = const Color(0xFF38BDF8);
    }

    return GestureDetector(
      onTap: () => onFilterChanged(item.id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : (item.type == 'tag' ? const Color(0xFF0C1929) : surfaceSec),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : (item.type == 'tag'
                      ? const Color(0xFF0284C7).withValues(alpha: 0.4)
                      : borderCustom),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.type == 'tag' && !isSelected) ...[
              const Icon(Icons.tag_rounded, size: 12, color: Color(0xFF38BDF8)),
              const SizedBox(width: 3),
            ],
            Text(
              "${item.label} (${item.count})",
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF121415),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCustom),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: neutral500, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: (val) => onSearchChanged(),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: "Dost ka naam search karein...",
                      hintStyle: TextStyle(color: neutral500, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      searchCtrl.clear();
                      onSearchChanged();
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: surfaceSec,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderCustom),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 12,
                        color: neutral400,
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
              children: filterList
                  .map((item) => _buildFilterPill(item))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 3. ACCORDION: NAYA DOST ADD KAREIN
// -------------------------------------------------------------
class AddFriendAccordionWidget extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController noteCtrl;
  final String? selectedTag;
  final List<String> tags;
  final ValueChanged<String?> onTagSelected;
  final ValueChanged<String> onCustomTagAdded;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const AddFriendAccordionWidget({
    super.key,
    required this.isOpen,
    required this.onToggle,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.noteCtrl,
    required this.selectedTag,
    required this.tags,
    required this.onTagSelected,
    required this.onCustomTagAdded,
    required this.onCancel,
    required this.onSubmit,
  });

  void _showAddCustomTagDialog(BuildContext context) {
    final TextEditingController customTagCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: borderCustom),
          ),
          title: const Text(
            "Naya Custom Tag Banayein",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: surfaceSec,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCustom),
            ),
            child: TextField(
              controller: customTagCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: "Tag ka naam (e.g. Gym, Flatmate)...",
                hintStyle: TextStyle(color: neutral500, fontSize: 12),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "Cancel",
                style: TextStyle(color: neutral400, fontSize: 12),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: lenaGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () {
                final tagVal = customTagCtrl.text.trim();
                if (tagVal.isNotEmpty) {
                  onCustomTagAdded(tagVal);
                }
                Navigator.pop(ctx);
              },
              child: const Text(
                "Add Tag",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPhone = false,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: surfaceSec,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCustom),
      ),
      child: Row(
        children: [
          Icon(icon, color: neutral500, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: neutral500, fontSize: 12),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lenaGreen.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F291C),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: lenaGreen.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: lenaGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Naya Dost Add Karein",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F291C),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: lenaGreen.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Text(
                                "+ New",
                                style: TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Naye dost ka hisaab jodne ke liye",
                          style: TextStyle(color: neutral400, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: surfaceSec,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderCustom),
                    ),
                    child: Icon(
                      isOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: neutral300,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOpen) ...[
            const Divider(height: 1, color: borderCustom),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dost ka Naam *",
                    style: TextStyle(color: neutral400, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  _buildFormInput(
                    controller: nameCtrl,
                    hint: "e.g. Amit Sharma",
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Mobile Number",
                    style: TextStyle(color: neutral400, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  _buildFormInput(
                    controller: phoneCtrl,
                    hint: "+91 98765 43210",
                    icon: Icons.call_outlined,
                    isPhone: true,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Description / Note",
                    style: TextStyle(color: neutral400, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  _buildFormInput(
                    controller: noteCtrl,
                    hint: "Dost ke baare me note (optional)",
                    icon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Tag Chunein (Optional)",
                    style: TextStyle(color: neutral400, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...tags.map((tag) {
                          final isSel = selectedTag == tag;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () {
                                onTagSelected(isSel ? null : tag);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(0xFF0F291C)
                                      : surfaceSec,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSel
                                        ? lenaGreen.withValues(alpha: 0.6)
                                        : borderCustom,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    color: isSel
                                        ? const Color(0xFF34D399)
                                        : neutral300,
                                    fontSize: 11,
                                    fontWeight: isSel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        GestureDetector(
                          onTap: () => _showAddCustomTagDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C1929),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF0284C7)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 12,
                                  color: Color(0xFF38BDF8),
                                ),
                                SizedBox(width: 3),
                                Text(
                                  "Custom",
                                  style: TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: borderCustom),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: surfaceSec,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: onCancel,
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: neutral300, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: lenaGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            onPressed: onSubmit,
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Dost Save Karein",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.check_rounded,
                                    color: Colors.black,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 4. FRIEND CARD TILE
// -------------------------------------------------------------
class SelectableFriendCardWidget extends StatelessWidget {
  final dynamic friendKey;
  final FriendModel friend;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectableFriendCardWidget({
    super.key,
    required this.friendKey,
    required this.friend,
    required this.isSelected,
    required this.onTap,
  });

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isLena = friend.type == 'lena';
    final isSettled = friend.balance == 0 || friend.type == 'settled';

    final Color amountColor = isSettled
        ? neutral400
        : (isLena ? lenaGreen : denaRed);

    final String balanceLabel = isSettled
        ? "₹0 chukta"
        : (isLena ? "+₹${friend.balance} lena" : "-₹${friend.balance} dena");

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F1E16) : surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? lenaGreen.withValues(alpha: 0.8)
                  : borderCustom,
              width: isSelected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF0F291C) : surfaceSec,
                  border: Border.all(
                    color: isSelected
                        ? lenaGreen.withValues(alpha: 0.5)
                        : borderCustom,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getInitials(friend.name),
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF34D399) : neutral300,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      friend.desc.isNotEmpty
                          ? friend.desc
                          : (friend.lastMessage.isNotEmpty
                                ? friend.lastMessage
                                : "Khata ready"),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: neutral400, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${friend.balance}.00",
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    balanceLabel,
                    style: TextStyle(
                      color: amountColor.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? lenaGreen : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? lenaGreen : neutral600,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.black)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 5. BOTTOM ENTRY DOCK BAR
// -------------------------------------------------------------
class EntryBottomDockWidget extends StatelessWidget {
  final String activeFriendName;
  final String activeBalance;
  final bool isPositive;
  final int selectedCount;
  final TextEditingController noteCtrl;
  final TextEditingController amountCtrl;
  final String selectedPaymentMode;
  final String txType;
  final VoidCallback onPaymentModeTap;
  final ValueChanged<String> onTxTypeChanged;
  final VoidCallback onSave;
  final VoidCallback onClosePage;

  const EntryBottomDockWidget({
    super.key,
    required this.activeFriendName,
    required this.activeBalance,
    required this.isPositive,
    required this.selectedCount,
    required this.noteCtrl,
    required this.amountCtrl,
    required this.selectedPaymentMode,
    required this.txType,
    required this.onPaymentModeTap,
    required this.onTxTypeChanged,
    required this.onSave,
    required this.onClosePage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: const BoxDecoration(
        color: bgOled,
        border: Border(top: BorderSide(color: borderCustom, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 2, right: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        "Chuna Hua Dost: ",
                        style: TextStyle(color: neutral400, fontSize: 12),
                      ),
                      Flexible(
                        child: Text(
                          activeFriendName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selectedCount > 0 ? lenaGreen : neutral400,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? const Color(0xFF0F291C)
                        : (selectedCount == 0
                              ? surfaceSec
                              : const Color(0xFF2B1015)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isPositive
                          ? lenaGreen.withValues(alpha: 0.4)
                          : (selectedCount == 0
                                ? borderCustom
                                : denaRed.withValues(alpha: 0.4)),
                    ),
                  ),
                  child: Text(
                    activeBalance,
                    style: TextStyle(
                      color: isPositive
                          ? const Color(0xFF34D399)
                          : (selectedCount == 0
                                ? neutral400
                                : const Color(0xFFFB7185)),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 46,
            padding: const EdgeInsets.only(left: 12, right: 6),
            decoration: BoxDecoration(
              color: surfaceSec,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderCustom),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.edit_note_rounded,
                  color: neutral400,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: noteCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: "Hisaab ka note likhein (e.g. Chai, Udhaar)...",
                      hintStyle: TextStyle(color: neutral500, fontSize: 12.5),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onPaymentModeTap,
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: surfaceHighlight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderCustom),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: lenaGreen,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          selectedPaymentMode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: neutral400,
                          size: 15,
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
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: surfaceSec,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCustom),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTxTypeChanged('diya'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: txType == 'diya'
                            ? const Color(0xFF0F291C)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: txType == 'diya'
                            ? Border.all(
                                color: lenaGreen.withValues(alpha: 0.6),
                                width: 1.1,
                              )
                            : Border.all(color: Colors.transparent),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: txType == 'diya'
                                  ? const Color(0xFF34D399)
                                  : neutral400,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Diya",
                              style: TextStyle(
                                color: txType == 'diya'
                                    ? const Color(0xFF34D399)
                                    : neutral400,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTxTypeChanged('liya'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: txType == 'liya'
                            ? const Color(0xFF2B1015)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: txType == 'liya'
                            ? Border.all(
                                color: denaRed.withValues(alpha: 0.6),
                                width: 1.1,
                              )
                            : Border.all(color: Colors.transparent),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 16,
                              color: txType == 'liya'
                                  ? const Color(0xFFFB7185)
                                  : neutral400,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Liya",
                              style: TextStyle(
                                color: txType == 'liya'
                                    ? const Color(0xFFFB7185)
                                    : neutral400,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: surfaceSec,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderCustom),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        "₹",
                        style: TextStyle(
                          color: lenaGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Amount",
                            hintStyle: TextStyle(
                              color: neutral500,
                              fontSize: 13.5,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    elevation: 0,
                  ),
                  onPressed: onSave,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Save",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.check_rounded, color: Colors.black, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onClosePage,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: surfaceSec,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderCustom),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.close_rounded,
                      color: neutral300,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // const SizedBox(height: 12),
          // Container(
          //   width: 120,
          //   height: 4,
          //   decoration: BoxDecoration(
          //     color: const Color(0xFF2C2C2E),
          //     borderRadius: BorderRadius.circular(10),
          //   ),
          // ),
        ],
      ),
    );
  }
}

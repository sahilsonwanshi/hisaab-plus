import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/friend_model.dart';
import '../theme/app_colors.dart';

// UI Palette Constants (preserved for backwards-compatibility)
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
// 1. TOP NAVIGATION HEADER WITH SLIDING SWITCH
// -------------------------------------------------------------
class EntryTopNavHeader extends StatelessWidget {
  final int activeTab; // 0: Dost, 1: Personal
  final ValueChanged<int> onTabSwitch;
  final VoidCallback onBack;

  const EntryTopNavHeader({
    super.key,
    required this.activeTab,
    required this.onTabSwitch,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: colors.textSecondary,
                  size: 18,
                ),
                onPressed: onBack,
              ),
              Text(
                activeTab == 0 ? "Choose Friends" : "Personal Kharcha",
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: colors.isDark
                  ? Colors.black.withValues(alpha: 0.40)
                  : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.90),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => onTabSwitch(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: activeTab == 0
                          ? (colors.isDark ? Colors.white : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: activeTab == 0 && !colors.isDark
                          ? const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      "Dost",
                      style: TextStyle(
                        color: activeTab == 0
                            ? (colors.isDark ? Colors.black : const Color(0xFF0F172A))
                            : colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => onTabSwitch(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: activeTab == 1
                          ? (colors.isDark ? Colors.white : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: activeTab == 1 && !colors.isDark
                          ? const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      "Personal",
                      style: TextStyle(
                        color: activeTab == 1
                            ? (colors.isDark ? Colors.black : const Color(0xFF0F172A))
                            : colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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

  Widget _buildFilterPill(FilterItem item, AppColors colors) {
    final isSelected = activeFilter == item.id;
    Color textColor;
    Color bgColor;
    Color borderColor;

    if (isSelected) {
      bgColor = colors.isDark ? Colors.white : Colors.white;
      borderColor = colors.isDark ? Colors.white : Colors.white.withValues(alpha: 0.95);
      textColor = colors.isDark
          ? Colors.black
          : (item.type == 'tag'
              ? colors.blueAccent
              : (item.type == 'lena'
                  ? colors.greenText
                  : (item.type == 'dena' ? colors.redText : const Color(0xFF0F172A))));
    } else if (item.type == 'lena') {
      bgColor = colors.greenPillBg;
      borderColor = colors.greenPillBorder;
      textColor = colors.greenText;
    } else if (item.type == 'dena') {
      bgColor = colors.redPillBg;
      borderColor = colors.redPillBorder;
      textColor = colors.redText;
    } else if (item.type == 'tag') {
      bgColor = colors.isDark
          ? const Color(0xFF0C1929).withValues(alpha: 0.65)
          : const Color(0xFFE0F2FE).withValues(alpha: 0.70);
      borderColor = colors.isDark
          ? const Color(0xFF0284C7).withValues(alpha: 0.4)
          : const Color(0xFFBAE6FD).withValues(alpha: 0.85);
      textColor = colors.blueAccent;
    } else {
      bgColor = colors.isDark
          ? Colors.black.withValues(alpha: 0.35)
          : Colors.white.withValues(alpha: 0.52);
      borderColor = colors.isDark ? colors.border : Colors.white.withValues(alpha: 0.75);
      textColor = colors.textSecondary;
    }

    return GestureDetector(
      onTap: () => onFilterChanged(item.id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: isSelected
              ? (colors.isDark
                  ? []
                  : const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ])
              : (!colors.isDark ? [colors.cardShadow] : []),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.type == 'tag' && !isSelected) ...[
              Icon(Icons.tag_rounded, size: 12, color: colors.blueAccent),
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
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colors.glassCardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.glassCardBorder,
                    width: 1.1,
                  ),
                  boxShadow: colors.isDark ? [] : [colors.cardShadow],
                ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: colors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: (val) => onSearchChanged(),
                    style: TextStyle(color: colors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Dost ka naam search karein...",
                      hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
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
                        color: colors.isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : colors.surfaceHighlight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: filterList
                  .map((item) => _buildFilterPill(item, colors))
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
    final colors = context.colors;
    final TextEditingController customTagCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.border),
          ),
          title: Text(
            "Naya Custom Tag Banayein",
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: TextField(
              controller: customTagCtrl,
              autofocus: true,
              style: TextStyle(color: colors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: "Tag ka naam (e.g. Gym, Flatmate)...",
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 12),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.greenAccent,
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
              child: Text(
                "Add Tag",
                style: TextStyle(
                  color: colors.isDark ? Colors.black : Colors.white,
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
    required AppColors colors,
    bool isPhone = false,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.isDark
            ? Colors.black.withValues(alpha: 0.40)
            : colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : colors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.textSecondary, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
              style: TextStyle(color: colors.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 12),
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
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: colors.glassCardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.isDark
                  ? lenaGreen.withValues(alpha: 0.45)
                  : colors.glassCardBorder,
              width: 1.2,
            ),
            boxShadow: colors.isDark ? null : [colors.cardShadow],
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
                      color: colors.greenPillBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.greenPillBorder),
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      color: colors.greenAccent,
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
                            Text(
                              "Naya Dost Add Karein",
                              style: TextStyle(
                                color: colors.textPrimary,
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
                                color: colors.greenPillBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colors.greenPillBorder,
                                ),
                              ),
                              child: Text(
                                "+ New",
                                style: TextStyle(
                                  color: colors.greenAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Naye dost ka hisaab jodne ke liye",
                          style: TextStyle(color: colors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : colors.surfaceSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: colors.textSecondary,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOpen) ...[
            Divider(
              height: 1,
              color: colors.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : colors.divider,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Dost ka Naam *",
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  _buildFormInput(
                    controller: nameCtrl,
                    hint: "e.g. Amit Sharma",
                    icon: Icons.badge_outlined,
                    colors: colors,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Mobile Number",
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  _buildFormInput(
                    controller: phoneCtrl,
                    hint: "+91 98765 43210",
                    icon: Icons.call_outlined,
                    colors: colors,
                    isPhone: true,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Description / Note",
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  _buildFormInput(
                    controller: noteCtrl,
                    hint: "Dost ke baare me note (optional)",
                    icon: Icons.notes_rounded,
                    colors: colors,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Tag Chunein (Optional)",
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
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
                              onTap: () => onTagSelected(isSel ? null : tag),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? colors.greenPillBg
                                      : colors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSel
                                        ? colors.greenPillBorder
                                        : colors.border,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    color: isSel
                                        ? colors.greenText
                                        : colors.textSecondary,
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
                              color: colors.isDark
                                  ? const Color(0xFF0C1929)
                                  : const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colors.isDark
                                    ? const Color(0xFF0284C7).withValues(alpha: 0.4)
                                    : const Color(0xFFBAE6FD),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 12,
                                  color: colors.blueAccent,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  "Custom",
                                  style: TextStyle(
                                    color: colors.blueAccent,
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
                              side: BorderSide(
                                color: colors.border,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: colors.isDark
                                  ? Colors.black.withValues(alpha: 0.35)
                                  : colors.surfaceSecondary,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: onCancel,
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12,
                              ),
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
                              backgroundColor: colors.greenAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: onSubmit,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Dost Save Karein",
                                  style: TextStyle(
                                    color: colors.isDark ? Colors.black : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 4. FRIEND CARD TILE (Customized Translucent Glass Look)
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
    final colors = context.colors;
    final isLena = friend.type == 'lena';
    final isSettled = friend.balance == 0 || friend.type == 'settled';

    final Color amountColor = isSettled
        ? colors.textSecondary
        : (isLena ? colors.greenAccent : colors.redAccent);

    final String balanceLabel = isSettled
        ? "₹0 chukta"
        : (isLena ? "+₹${friend.balance} lena" : "-₹${friend.balance} dena");

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (colors.isDark
                        ? const Color(0xFF0F1E16).withValues(alpha: 0.80)
                        : colors.greenPillBg)
                    : colors.glassTileBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? (colors.isDark
                          ? lenaGreen.withValues(alpha: 0.85)
                          : colors.greenAccent)
                      : colors.glassTileBorder,
                  width: isSelected ? 1.2 : 1.1,
                ),
                boxShadow: (!colors.isDark && !isSelected) ? [colors.cardShadow] : null,
              ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? (colors.isDark
                          ? const Color(0xFF0F291C)
                          : const Color(0xFFD1FAE5))
                      : (colors.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : colors.surfaceSecondary),
                  border: Border.all(
                    color: isSelected
                        ? colors.greenAccent.withValues(alpha: 0.5)
                        : colors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getInitials(friend.name),
                    style: TextStyle(
                      color: isSelected
                          ? colors.greenAccent
                          : colors.textPrimary,
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
                      style: TextStyle(
                        color: colors.textPrimary,
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
                  color: isSelected ? colors.greenAccent : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? colors.greenAccent : colors.border,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 14,
                        color: colors.isDark ? Colors.black : Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
            ),
          ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 5. BOTTOM ENTRY DOCK BAR (Fixed Diya/Liya Segmented Pill)
// -------------------------------------------------------------
class EntryBottomDockWidget extends StatelessWidget {
  final String activeFriendName;
  final String activeBalance;
  final bool isPositive;
  final bool hasSelectedFriend;
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
    required this.hasSelectedFriend,
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
    final colors = context.colors;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: colors.isDark ? colors.border : Colors.white.withValues(alpha: 0.95),
                width: 1.2,
              ),
            ),
            boxShadow: colors.isDark ? null : [colors.cardShadow],
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2, right: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        "Chuna Hua Dost: ",
                        style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
                      ),
                      Flexible(
                        child: Text(
                          activeFriendName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasSelectedFriend
                                ? colors.greenAccent
                                : colors.textMuted,
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
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? colors.greenPillBg
                        : (!hasSelectedFriend
                              ? colors.surfaceSecondary
                              : colors.redPillBg),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isPositive
                          ? colors.greenPillBorder
                          : (!hasSelectedFriend
                                ? colors.border
                                : colors.redPillBorder),
                    ),
                  ),
                  child: Text(
                    activeBalance,
                    style: TextStyle(
                      color: isPositive
                          ? colors.greenText
                          : (!hasSelectedFriend
                                ? colors.textMuted
                                : colors.redText),
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
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
              border: Border.all(color: colors.border),
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
                    controller: noteCtrl,
                    style: TextStyle(color: colors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Hisaab ka note likhein...",
                      hintStyle: TextStyle(color: colors.textMuted, fontSize: 12),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onPaymentModeTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : colors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.border),
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
                          selectedPaymentMode,
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

          // =========================================================
          // FIXED DIYA / LIYA CAPSULE PILL
          // =========================================================
          Container(
            height: 44,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: colors.isDark
                  ? Colors.black.withValues(alpha: 0.40)
                  : colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                // 1. DIYA PILL
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTxTypeChanged('diya'),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: txType == 'diya'
                            ? (colors.isDark
                                ? const Color(0xFF0F291C).withValues(alpha: 0.90)
                                : colors.greenPillBg)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: txType == 'diya'
                              ? colors.greenAccent
                              : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: txType == 'diya'
                                  ? colors.greenText
                                  : colors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Diya",
                              style: TextStyle(
                                color: txType == 'diya'
                                    ? colors.greenText
                                    : colors.textSecondary,
                                fontWeight: txType == 'diya'
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // 2. LIYA PILL
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTxTypeChanged('liya'),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: txType == 'liya'
                            ? (colors.isDark
                                ? const Color(0xFF2B1015).withValues(alpha: 0.90)
                                : colors.redPillBg)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: txType == 'liya'
                              ? colors.redAccent
                              : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 16,
                              color: txType == 'liya'
                                  ? colors.redText
                                  : colors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Liya",
                              style: TextStyle(
                                color: txType == 'liya'
                                    ? colors.redText
                                    : colors.textSecondary,
                                fontWeight: txType == 'liya'
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 13,
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

          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: colors.isDark
                        ? Colors.black.withValues(alpha: 0.40)
                        : colors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colors.border),
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
                          controller: amountCtrl,
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    elevation: 0,
                  ),
                  onPressed: onSave,
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
                onTap: onClosePage,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.isDark
                        ? Colors.black.withValues(alpha: 0.40)
                        : colors.surfaceSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
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
    );
  }
}

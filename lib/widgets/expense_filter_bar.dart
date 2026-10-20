import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ExpenseFilterBar extends StatelessWidget {
  final String activeDateFilter;
  final DateTime? selectedCustomDate;
  final ValueChanged<String> onDateFilterChanged;
  final VoidCallback onPickCustomDate;
  final VoidCallback onClearCustomDate;

  // Optional Category Filter
  final String? activeCategoryFilter;
  final List<String>? categories;
  final List<Map>? rawItems;
  final ValueChanged<String>? onCategoryFilterChanged;

  const ExpenseFilterBar({
    super.key,
    required this.activeDateFilter,
    required this.selectedCustomDate,
    required this.onDateFilterChanged,
    required this.onPickCustomDate,
    required this.onClearCustomDate,
    this.activeCategoryFilter,
    this.categories,
    this.rawItems,
    this.onCategoryFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. DATE FILTER SEGMENT BAR
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.glassCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.glassCardBorder,
                  width: 1.2,
                ),
                boxShadow: colors.isDark ? [] : [colors.cardShadow],
              ),
          child: Row(
            children: [
              // 1. Sabhi Din
              Expanded(
                child: _buildSegment(
                  context: context,
                  id: "all",
                  label: "Sabhi",
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(width: 4),

              // 2. Aaj
              Expanded(
                child: _buildSegment(
                  context: context,
                  id: "today",
                  label: "Aaj",
                  icon: Icons.today_rounded,
                ),
              ),
              const SizedBox(width: 4),

              // 3. Kal
              Expanded(
                child: _buildSegment(
                  context: context,
                  id: "yesterday",
                  label: "Kal",
                  icon: Icons.history_rounded,
                ),
              ),
              const SizedBox(width: 4),

              // 4. Custom Date Picker Segment
              Expanded(
                child: _buildCustomSegment(context),
              ),
            ],
          ),
            ),
          ),
        ),

        // 2. CATEGORY FILTER CAPSULES
        if (categories != null && onCategoryFilterChanged != null) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: categories!.map((cat) {
                final isSel = activeCategoryFilter == cat;
                final count = cat == "Sabhi"
                    ? (rawItems?.length ?? 0)
                    : (rawItems
                            ?.where(
                              (e) =>
                                  (e["category"] ?? "")
                                      .toString()
                                      .toLowerCase() ==
                                  cat.toLowerCase(),
                            )
                            .length ??
                        0);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onCategoryFilterChanged!(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSel
                            ? (colors.isDark ? Colors.white : Colors.white)
                            : (colors.isDark
                                ? Colors.black.withValues(alpha: 0.35)
                                : Colors.white.withValues(alpha: 0.52)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSel
                              ? (colors.isDark ? Colors.white : Colors.white.withValues(alpha: 0.95))
                              : (colors.isDark ? colors.border : Colors.white.withValues(alpha: 0.75)),
                          width: 1.0,
                        ),
                        boxShadow: isSel
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
                          if (isSel) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors.isDark ? Colors.black : const Color(0xFF0F172A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            cat,
                            style: TextStyle(
                              color: isSel
                                  ? (colors.isDark ? Colors.black : const Color(0xFF0F172A))
                                  : colors.textSecondary,
                              fontSize: 11.5,
                              fontWeight:
                                  isSel ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "$count",
                            style: TextStyle(
                              color: isSel
                                  ? (colors.isDark
                                      ? Colors.black87
                                      : const Color(0xFF475569))
                                  : colors.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSegment({
    required BuildContext context,
    required String id,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = activeDateFilter == id;
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onDateFilterChanged(id),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (colors.isDark
                    ? colors.greenAccent.withValues(alpha: 0.16)
                    : colors.greenPillBg)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (colors.isDark
                      ? colors.greenAccent.withValues(alpha: 0.35)
                      : colors.greenPillBorder)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? (colors.isDark ? colors.greenAccent : colors.greenText)
                    : colors.textMuted,
              ),
              const SizedBox(width: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? (colors.isDark ? Colors.white : colors.greenText)
                        : colors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomSegment(BuildContext context) {
    final bool isSelected = activeDateFilter == "custom";
    final colors = context.colors;
    final String label = (isSelected && selectedCustomDate != null)
        ? "${selectedCustomDate!.day} ${_monthName(selectedCustomDate!.month)}"
        : "Date";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPickCustomDate,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? (colors.isDark
                    ? colors.blueAccent.withValues(alpha: 0.16)
                    : colors.blueAccent.withValues(alpha: 0.12))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colors.blueAccent.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 13,
                color: isSelected ? colors.blueAccent : colors.textMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? (colors.isDark ? Colors.white : colors.blueAccent)
                          : colors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (isSelected && selectedCustomDate != null) ...[
                const SizedBox(width: 2),
                GestureDetector(
                  onTap: onClearCustomDate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: colors.blueAccent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      "",
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
    if (month >= 1 && month <= 12) return months[month];
    return "";
  }
}

import 'package:flutter/material.dart';

class ExpenseFilterBar extends StatelessWidget {
  final String activeDateFilter;
  final DateTime? selectedCustomDate;
  final ValueChanged<String> onDateFilterChanged;
  final VoidCallback onPickCustomDate;
  final VoidCallback onClearCustomDate;

  final String activeCategoryFilter;
  final List<String> categories;
  final List<Map> rawItems;
  final ValueChanged<String> onCategoryFilterChanged;

  static const Color textMuted = Color(0xFFA1A1AA);
  static const Color textMutedDark = Color(0xFF71717A);
  static const Color greenAccent = Color(0xFF00E676);

  const ExpenseFilterBar({
    super.key,
    required this.activeDateFilter,
    required this.selectedCustomDate,
    required this.onDateFilterChanged,
    required this.onPickCustomDate,
    required this.onClearCustomDate,
    required this.activeCategoryFilter,
    required this.categories,
    required this.rawItems,
    required this.onCategoryFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. DATE FILTER ROW
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildDateChip(
                id: "all",
                label: "Sabhi Din",
                icon: Icons.calendar_today_rounded,
              ),
              _buildDateChip(
                id: "today",
                label: "Aaj",
                icon: Icons.today_rounded,
              ),
              _buildDateChip(
                id: "yesterday",
                label: "Kal",
                icon: Icons.history_rounded,
              ),
              // Custom Date Picker Chip
              GestureDetector(
                onTap: onPickCustomDate,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: activeDateFilter == "custom"
                        ? const Color(0xFF0C1929)
                        : Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: activeDateFilter == "custom"
                          ? const Color(0xFF38BDF8)
                          : Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_calendar_rounded,
                        size: 13,
                        color: activeDateFilter == "custom"
                            ? const Color(0xFF38BDF8)
                            : textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        selectedCustomDate != null && activeDateFilter == "custom"
                            ? "${selectedCustomDate!.day}/${selectedCustomDate!.month}/${selectedCustomDate!.year}"
                            : "Date Chunein",
                        style: TextStyle(
                          color: activeDateFilter == "custom"
                              ? const Color(0xFF38BDF8)
                              : textMuted,
                          fontSize: 11,
                          fontWeight: activeDateFilter == "custom"
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                      if (activeDateFilter == "custom") ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: onClearCustomDate,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 2. CATEGORY FILTER CAPSULES
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: categories.map((cat) {
              final isSel = activeCategoryFilter == cat;
              final count = cat == "Sabhi"
                  ? rawItems.length
                  : rawItems
                      .where(
                        (e) =>
                            (e["category"] ?? "")
                                .toString()
                                .toLowerCase() ==
                            cat.toLowerCase(),
                      )
                      .length;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onCategoryFilterChanged(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSel
                          ? Colors.white
                          : Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSel
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSel) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          cat,
                          style: TextStyle(
                            color: isSel ? Colors.black : textMuted,
                            fontSize: 11.5,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "$count",
                          style: TextStyle(
                            color: isSel ? Colors.black87 : textMutedDark,
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
    );
  }

  Widget _buildDateChip({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSel = activeDateFilter == id;

    return GestureDetector(
      onTap: () => onDateFilterChanged(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel
              ? greenAccent.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel
                ? greenAccent
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSel ? greenAccent : textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSel ? greenAccent : textMuted,
                fontSize: 11,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

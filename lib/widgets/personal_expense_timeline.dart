import 'package:flutter/material.dart';

class PersonalExpenseTimeline extends StatelessWidget {
  final Map<String, List<MapEntry<dynamic, Map>>> groupedExpenses;
  final Map<String, int> dailyTotals;
  final bool isEmpty;
  final bool isDefaultFilter;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final void Function(dynamic key, Map item) onDeleteItem;

  static const Color textMuted = Color(0xFFA1A1AA);
  static const Color textMutedDark = Color(0xFF71717A);
  static const Color redAccent = Color(0xFFFF5252);

  const PersonalExpenseTimeline({
    super.key,
    required this.groupedExpenses,
    required this.dailyTotals,
    required this.isEmpty,
    required this.isDefaultFilter,
    required this.hasMore,
    required this.onLoadMore,
    required this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Text(
            isDefaultFilter
                ? "Abhi tak koi kharcha add nahi kiya gaya hai.\n'+ Kharcha' button se add karein!"
                : "Chune gaye filter me koi kharcha nahi mila.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textMuted,
              fontSize: 12.5,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...groupedExpenses.entries.expand((group) {
          final dateLabel = group.key;
          final itemsUnderDate = group.value;
          final dayTotal = dailyTotals[dateLabel] ?? 0;

          return [
            // Daily Section Header: Date (Left) + Day Total (Right)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      dateLabel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Total: ₹$dayTotal.00",
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Timeline Items Under This Date
            ...List.generate(itemsUnderDate.length, (idx) {
              final entry = itemsUnderDate[idx];
              final rawKey = entry.key;
              final item = entry.value;
              final bool isLast = idx == itemsUnderDate.length - 1;

              final cat = item["category"]?.toString() ?? "Other";
              final catColor = _getCategoryColor(cat);
              final catIcon = _getCategoryIcon(cat);

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Time Label (Left)
                    SizedBox(
                      width: 44,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          item["time"] ?? "00:00",
                          style: const TextStyle(
                            color: textMutedDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // Timeline Node & Connecting Line
                    Column(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: catColor.withValues(alpha: 0.60),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            catIcon,
                            size: 14,
                            color: catColor,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 1.5,
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),

                    // Glassy Chat Expense Tile
                    Expanded(
                      child: GestureDetector(
                        onLongPress: () => onDeleteItem(rawKey, item),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item["title"] ?? "Kharcha",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${item["sub"]?.isNotEmpty == true ? item["sub"] : cat} • ${item["time"] ?? 'Aaj'}",
                                      style: const TextStyle(
                                        color: textMuted,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "-₹${item['amount']}.00",
                                    style: const TextStyle(
                                      color: redAccent,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item["mode"] ?? "Online UPI",
                                    style: const TextStyle(
                                      color: textMutedDark,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ];
        }),

        // Load More Button
        if (hasMore) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: onLoadMore,
              icon: const Icon(
                Icons.expand_more_rounded,
                color: Colors.white70,
                size: 18,
              ),
              label: const Text(
                "Aur Kharcha Dekhein",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'chai':
        return const Color(0xFFFB923C);
      case 'kirana':
        return const Color(0xFF60A5FA);
      case 'khana':
      case 'lunch':
      case 'dinner':
        return const Color(0xFFFACC15);
      case 'medical':
        return const Color(0xFFF87171);
      case 'icecream':
      case 'treat':
        return const Color(0xFFE879F9);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'chai':
        return Icons.local_cafe_rounded;
      case 'kirana':
        return Icons.shopping_cart_rounded;
      case 'khana':
      case 'lunch':
      case 'dinner':
        return Icons.restaurant_rounded;
      case 'medical':
        return Icons.medical_services_rounded;
      case 'icecream':
      case 'treat':
        return Icons.icecream_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}

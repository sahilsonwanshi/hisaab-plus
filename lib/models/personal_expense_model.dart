import 'package:flutter/material.dart';

class PersonalExpenseModel {
  final dynamic key;
  final String title;
  final String category;
  final int amount;
  final String mode;
  final String time;
  final int timestamp;

  const PersonalExpenseModel({
    this.key,
    required this.title,
    required this.category,
    required this.amount,
    required this.mode,
    required this.time,
    required this.timestamp,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  String get formattedAmount => '₹$amount';

  factory PersonalExpenseModel.fromMap(Map map, {dynamic key}) {
    return PersonalExpenseModel(
      key: key,
      title: map['title']?.toString() ?? '',
      category: map['category']?.toString() ?? map['sub']?.toString() ?? 'Other',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      mode: map['mode']?.toString() ?? 'Online UPI',
      time: map['time']?.toString() ?? '',
      timestamp: (map['timestamp'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'sub': category,
      'amount': amount,
      'category': category,
      'mode': mode,
      'time': time,
      'timestamp': timestamp,
    };
  }

  IconData get icon {
    switch (category.toLowerCase()) {
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
      case 'transport':
      case 'petrol':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}

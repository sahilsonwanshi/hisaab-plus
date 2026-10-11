import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/friend_model.dart';
import '../models/transaction_model.dart';

class HisaabEntryService {
  final Box<FriendModel> friendsBox;
  final Box<TransactionModel> transBox;

  HisaabEntryService({required this.friendsBox, required this.transBox});

  dynamic addNewFriend({
    required String name,
    required String phone,
    required String note,
    required String tag,
  }) {
    final cleanNote = note.trim();
    final cleanTag = tag.trim();

    String finalDesc;
    if (cleanTag.isNotEmpty && cleanNote.isNotEmpty) {
      finalDesc = "$cleanNote • $cleanTag";
    } else if (cleanTag.isNotEmpty) {
      finalDesc = cleanTag;
    } else if (cleanNote.isNotEmpty) {
      finalDesc = cleanNote;
    } else {
      finalDesc = "Dost";
    }

    final newFriend = FriendModel(
      name: name.trim(),
      phone: phone.trim(),
      desc: finalDesc,
      balance: 0,
      type: 'settled',
      lastMessage: "Khata Banaya gaya",
      lastDate: "Aaj",
    );

    return friendsBox.add(newFriend);
  }

  // Single Friend Transaction Save (Group Split logic removed)
  void saveSingleFriendTransaction({
    required dynamic friendKey,
    required int amount,
    required String txType, // 'diya' ya 'liya'
    required String note,
    required String paymentMode,
  }) {
    if (friendKey == null || amount <= 0) return;

    final FriendModel? friend = friendsBox.get(friendKey);
    if (friend == null) return;

    final noteText = note.trim().isNotEmpty ? note.trim() : "Hisaab Entry";
    final now = DateTime.now();
    final dateStr =
        "${now.day}/${now.month} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    if (txType == 'diya') {
      if (friend.type == 'lena') {
        friend.balance += amount;
      } else if (friend.type == 'dena') {
        if (friend.balance > amount) {
          friend.balance -= amount;
        } else if (friend.balance == amount) {
          friend.balance = 0;
          friend.type = 'settled';
        } else {
          friend.balance = amount - friend.balance;
          friend.type = 'lena';
        }
      } else {
        friend.balance = amount;
        friend.type = 'lena';
      }
    } else {
      if (friend.type == 'dena') {
        friend.balance += amount;
      } else if (friend.type == 'lena') {
        if (friend.balance > amount) {
          friend.balance -= amount;
        } else if (friend.balance == amount) {
          friend.balance = 0;
          friend.type = 'settled';
        } else {
          friend.balance = amount - friend.balance;
          friend.type = 'dena';
        }
      } else {
        friend.balance = amount;
        friend.type = 'dena';
      }
    }

    friend.lastMessage = "$noteText via $paymentMode";
    friend.lastDate = "Aaj";
    friend.history.add({
      "title": noteText,
      "amount": amount,
      "type": txType,
      "date": dateStr,
      "mode": paymentMode,
    });

    friend.save();

    transBox.add(
      TransactionModel(
        date: now,
        title: friend.name,
        subtitle: "$noteText • $paymentMode",
        amount: amount,
        iconCodePoint: txType == 'diya'
            ? Icons.arrow_upward_rounded.codePoint
            : Icons.arrow_downward_rounded.codePoint,
        type: txType == 'diya' ? 'lena' : 'dena',
        mode: paymentMode,
      ),
    );
  }
}

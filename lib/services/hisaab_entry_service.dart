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

  // Balance recalculation helper from history (100% accurate & drift-free)
  static void recalculateFriendBalance(FriendModel friend) {
    int net = 0;
    for (var tx in friend.history) {
      final amount = (tx["amount"] as num?)?.toInt() ?? 0;
      final type = tx["type"] ?? "diya";
      if (type == "diya") {
        net += amount;
      } else if (type == "liya") {
        net -= amount;
      }
    }

    if (net > 0) {
      friend.balance = net;
      friend.type = "lena";
    } else if (net < 0) {
      friend.balance = net.abs();
      friend.type = "dena";
    } else {
      friend.balance = 0;
      friend.type = "settled";
    }

    if (friend.history.isNotEmpty) {
      final last = friend.history.last;
      friend.lastMessage = "${last["title"] ?? "Hisaab"} • ₹${last["amount"]}";
      friend.lastDate = last["date"] ?? "Aaj";
    } else {
      friend.lastMessage = "Khata ready";
      friend.lastDate = "";
    }
  }

  // Single Friend Transaction Save with transKey linking
  Future<void> saveSingleFriendTransaction({
    required dynamic friendKey,
    required int amount,
    required String txType, // 'diya' ya 'liya'
    required String note,
    required String paymentMode,
  }) async {
    if (friendKey == null || amount <= 0) return;

    final FriendModel? friend = friendsBox.get(friendKey);
    if (friend == null) return;

    final noteText = note.trim().isNotEmpty ? note.trim() : "Hisaab Entry";
    final now = DateTime.now();
    final dateStr =
        "${now.day}/${now.month} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    final transKey = await transBox.add(
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

    friend.history.add({
      "id": DateTime.now().microsecondsSinceEpoch.toString(),
      "title": noteText,
      "amount": amount,
      "type": txType,
      "date": dateStr,
      "mode": paymentMode,
      "transKey": transKey,
      "timestamp": now.millisecondsSinceEpoch,
    });

    recalculateFriendBalance(friend);
    await friend.save();
  }

  // Edit single transaction in friend history & sync with transactions_box
  Future<void> editSingleFriendTransaction({
    required FriendModel friend,
    required Map<dynamic, dynamic> targetTx,
    required int newAmount,
    required String newNote,
    required String newPaymentMode,
    required String newType, // 'diya' ya 'liya'
  }) async {
    final oldAmount = (targetTx["amount"] as num?)?.toInt() ?? 0;
    final oldType = targetTx["type"] ?? "diya";

    targetTx["amount"] = newAmount;
    targetTx["title"] = newNote;
    targetTx["mode"] = newPaymentMode;
    targetTx["type"] = newType;

    recalculateFriendBalance(friend);
    await friend.save();

    // Sync with transBox
    final transKey = targetTx["transKey"];
    if (transKey != null && transBox.containsKey(transKey)) {
      final existingTx = transBox.get(transKey);
      if (existingTx != null) {
        final updatedTx = TransactionModel(
          date: existingTx.date,
          title: friend.name,
          subtitle: "$newNote • $newPaymentMode",
          amount: newAmount,
          iconCodePoint: newType == 'diya'
              ? Icons.arrow_upward_rounded.codePoint
              : Icons.arrow_downward_rounded.codePoint,
          type: newType == 'diya' ? 'lena' : 'dena',
          mode: newPaymentMode,
        );
        await transBox.put(transKey, updatedTx);
      }
    } else {
      // Fallback matching if transKey was not present (older data)
      dynamic matchingKey;
      for (var key in transBox.keys) {
        final tx = transBox.get(key);
        if (tx != null &&
            tx.title == friend.name &&
            tx.amount == oldAmount &&
            (oldType == 'diya' ? tx.type == 'lena' : tx.type == 'dena')) {
          matchingKey = key;
          break;
        }
      }
      if (matchingKey != null) {
        final existingTx = transBox.get(matchingKey);
        final updatedTx = TransactionModel(
          date: existingTx?.date ?? DateTime.now(),
          title: friend.name,
          subtitle: "$newNote • $newPaymentMode",
          amount: newAmount,
          iconCodePoint: newType == 'diya'
              ? Icons.arrow_upward_rounded.codePoint
              : Icons.arrow_downward_rounded.codePoint,
          type: newType == 'diya' ? 'lena' : 'dena',
          mode: newPaymentMode,
        );
        await transBox.put(matchingKey, updatedTx);
        targetTx["transKey"] = matchingKey;
        await friend.save();
      }
    }
  }

  // Delete single transaction from friend history & sync with transactions_box
  Future<void> deleteSingleFriendTransaction({
    required FriendModel friend,
    required Map<dynamic, dynamic> targetTx,
  }) async {
    final oldAmount = (targetTx["amount"] as num?)?.toInt() ?? 0;
    final oldType = targetTx["type"] ?? "diya";

    friend.history.remove(targetTx);
    recalculateFriendBalance(friend);
    await friend.save();

    final transKey = targetTx["transKey"];
    if (transKey != null && transBox.containsKey(transKey)) {
      await transBox.delete(transKey);
    } else {
      // Fallback search
      dynamic matchingKey;
      for (var key in transBox.keys) {
        final tx = transBox.get(key);
        if (tx != null &&
            tx.title == friend.name &&
            tx.amount == oldAmount &&
            (oldType == 'diya' ? tx.type == 'lena' : tx.type == 'dena')) {
          matchingKey = key;
          break;
        }
      }
      if (matchingKey != null) {
        await transBox.delete(matchingKey);
      }
    }
  }

  // Clear all friend transactions & clean up transactions_box
  Future<void> clearFriendHistory(FriendModel friend) async {
    for (var tx in friend.history) {
      final transKey = tx["transKey"];
      if (transKey != null && transBox.containsKey(transKey)) {
        await transBox.delete(transKey);
      }
    }
    friend.history.clear();
    friend.balance = 0;
    friend.type = "settled";
    friend.lastMessage = "Chat cleared";
    friend.lastDate = "Aaj";
    await friend.save();
  }
}

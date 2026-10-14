import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/friend_model.dart';
import '../models/transaction_model.dart';

class SyncResult {
  final int downloadedTransactions;
  final int uploadedTransactions;
  final int downloadedExpenses;
  final int uploadedExpenses;
  final int friendsMerged;
  final String message;

  const SyncResult({
    this.downloadedTransactions = 0,
    this.uploadedTransactions = 0,
    this.downloadedExpenses = 0,
    this.uploadedExpenses = 0,
    this.friendsMerged = 0,
    required this.message,
  });
}

class HiveBackupService {
  static final HiveBackupService instance = HiveBackupService._internal();
  HiveBackupService._internal();

  Box<TransactionModel> get _txBox => Hive.box<TransactionModel>('transactions_box');
  Box<FriendModel> get _friendsBox => Hive.box<FriendModel>('friends_box');
  Box<String> get _tagsBox => Hive.box<String>('tags_box');
  Box<Map> get _personalBox => Hive.box<Map>('personal_expenses_box');

  /// 1. Export all Hive data to a structured JSON Map
  Map<String, dynamic> exportAllBoxesToMap() {
    // 1. Transactions
    final List<Map<String, dynamic>> txList = [];
    for (var tx in _txBox.values) {
      txList.add({
        "date": tx.date.toIso8601String(),
        "title": tx.title,
        "subtitle": tx.subtitle,
        "amount": tx.amount,
        "iconCodePoint": tx.iconCodePoint,
        "type": tx.type,
        "mode": tx.mode,
      });
    }

    // 2. Friends
    final List<Map<String, dynamic>> friendsList = [];
    for (var f in _friendsBox.values) {
      friendsList.add({
        "name": f.name,
        "phone": f.phone,
        "desc": f.desc,
        "balance": f.balance,
        "type": f.type,
        "lastMessage": f.lastMessage,
        "lastDate": f.lastDate,
        "history": f.history,
      });
    }

    // 3. Tags
    final List<String> tagsList = _tagsBox.values.toList();

    // 4. Personal Expenses
    final List<Map<String, dynamic>> personalList = [];
    for (var p in _personalBox.values) {
      personalList.add(Map<String, dynamic>.from(p));
    }

    return {
      "app": "Hisaab+",
      "version": "4.4.2",
      "exportDate": DateTime.now().toIso8601String(),
      "transactions": txList,
      "friends": friendsList,
      "tags": tagsList,
      "personalExpenses": personalList,
    };
  }

  /// Export as formatted JSON String
  String exportAllBoxesToJson() {
    final map = exportAllBoxesToMap();
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// 2. Full Overwrite Restore from JSON Map
  Future<void> restoreAllBoxesFromMap(Map<String, dynamic> data) async {
    // Clear existing boxes
    await _txBox.clear();
    await _friendsBox.clear();
    await _tagsBox.clear();
    await _personalBox.clear();

    // 1. Restore Transactions
    if (data["transactions"] is List) {
      for (var item in data["transactions"]) {
        if (item is Map) {
          final tx = TransactionModel(
            date: DateTime.tryParse(item["date"]?.toString() ?? '') ?? DateTime.now(),
            title: item["title"]?.toString() ?? 'Kharcha',
            subtitle: item["subtitle"]?.toString() ?? '',
            amount: (item["amount"] as num?)?.toInt() ?? 0,
            iconCodePoint: (item["iconCodePoint"] as num?)?.toInt() ?? 0,
            type: item["type"]?.toString() ?? 'kharcha',
            mode: item["mode"]?.toString() ?? 'Online UPI',
          );
          await _txBox.add(tx);
        }
      }
    }

    // 2. Restore Friends
    if (data["friends"] is List) {
      for (var item in data["friends"]) {
        if (item is Map) {
          final friend = FriendModel(
            name: item["name"]?.toString() ?? '',
            phone: item["phone"]?.toString() ?? '',
            desc: item["desc"]?.toString() ?? '',
            balance: (item["balance"] as num?)?.toInt() ?? 0,
            type: item["type"]?.toString() ?? 'settled',
            lastMessage: item["lastMessage"]?.toString() ?? '',
            lastDate: item["lastDate"]?.toString() ?? '',
            history: (item["history"] is List)
                ? List<Map<dynamic, dynamic>>.from(item["history"])
                : [],
          );
          await _friendsBox.add(friend);
        }
      }
    }

    // 3. Restore Tags
    if (data["tags"] is List) {
      for (var t in data["tags"]) {
        if (t != null && t.toString().trim().isNotEmpty) {
          await _tagsBox.add(t.toString().trim());
        }
      }
    }

    // 4. Restore Personal Expenses
    if (data["personalExpenses"] is List) {
      for (var p in data["personalExpenses"]) {
        if (p is Map) {
          await _personalBox.add(Map<dynamic, dynamic>.from(p));
        }
      }
    }
  }

  /// 3. SMART DATA SYNC (Two-Way Intelligent Merge)
  /// Scans both app storage & cloud data, downloads missing cloud items into local storage,
  /// preserves and adds new local items into cloud, and returns the merged dataset to upload!
  Future<({SyncResult result, Map<String, dynamic> mergedData})> smartSync(
    Map<String, dynamic> cloudData,
  ) async {
    int downloadedTx = 0;
    int uploadedTx = 0;
    int downloadedExp = 0;
    int uploadedExp = 0;
    int friendsMergedCount = 0;

    // --- A. MERGE TRANSACTIONS ---
    final List<Map<String, dynamic>> localTxList = [];
    final Set<String> localTxFingerprints = {};

    for (var tx in _txBox.values) {
      final fp = "${tx.date.millisecondsSinceEpoch}_${tx.title}_${tx.amount}_${tx.type}";
      localTxFingerprints.add(fp);
      localTxList.add({
        "date": tx.date.toIso8601String(),
        "title": tx.title,
        "subtitle": tx.subtitle,
        "amount": tx.amount,
        "iconCodePoint": tx.iconCodePoint,
        "type": tx.type,
        "mode": tx.mode,
      });
    }

    final List<dynamic> rawCloudTx = (cloudData["transactions"] as List?) ?? [];
    final List<Map<String, dynamic>> mergedTxList = List.from(localTxList);

    for (var item in rawCloudTx) {
      if (item is Map) {
        final date = DateTime.tryParse(item["date"]?.toString() ?? '') ?? DateTime.now();
        final title = item["title"]?.toString() ?? '';
        final amount = (item["amount"] as num?)?.toInt() ?? 0;
        final type = item["type"]?.toString() ?? '';
        final fp = "${date.millisecondsSinceEpoch}_${title}_${amount}_${type}";

        if (!localTxFingerprints.contains(fp)) {
          // Cloud has it, app does not -> Download to app!
          final newTx = TransactionModel(
            date: date,
            title: title,
            subtitle: item["subtitle"]?.toString() ?? '',
            amount: amount,
            iconCodePoint: (item["iconCodePoint"] as num?)?.toInt() ?? 0,
            type: type,
            mode: item["mode"]?.toString() ?? 'Online UPI',
          );
          await _txBox.add(newTx);
          localTxFingerprints.add(fp);
          mergedTxList.add(Map<String, dynamic>.from(item));
          downloadedTx++;
        }
      }
    }

    uploadedTx = localTxList.length - (mergedTxList.length - downloadedTx);
    if (uploadedTx < 0) uploadedTx = 0;

    // --- B. MERGE PERSONAL EXPENSES ---
    final Set<String> localExpFingerprints = {};
    final List<Map<String, dynamic>> localExpList = [];

    for (var exp in _personalBox.values) {
      final ts = exp["timestamp"] ?? 0;
      final title = exp["title"] ?? '';
      final amt = exp["amount"] ?? 0;
      final fp = "${ts}_${title}_${amt}";
      localExpFingerprints.add(fp);
      localExpList.add(Map<String, dynamic>.from(exp));
    }

    final List<dynamic> rawCloudExp = (cloudData["personalExpenses"] as List?) ?? [];
    final List<Map<String, dynamic>> mergedExpList = List.from(localExpList);

    for (var item in rawCloudExp) {
      if (item is Map) {
        final ts = item["timestamp"] ?? 0;
        final title = item["title"] ?? '';
        final amt = item["amount"] ?? 0;
        final fp = "${ts}_${title}_${amt}";

        if (!localExpFingerprints.contains(fp)) {
          // Cloud has it, app does not -> Download to local app!
          await _personalBox.add(Map<dynamic, dynamic>.from(item));
          localExpFingerprints.add(fp);
          mergedExpList.add(Map<String, dynamic>.from(item));
          downloadedExp++;
        }
      }
    }

    uploadedExp = localExpList.length - (mergedExpList.length - downloadedExp);
    if (uploadedExp < 0) uploadedExp = 0;

    // --- C. MERGE FRIENDS & CHAT LEDGERS ---
    final Map<String, FriendModel> localFriendsMap = {};
    for (var f in _friendsBox.values) {
      final key = f.name.trim().toLowerCase();
      localFriendsMap[key] = f;
    }

    final List<dynamic> rawCloudFriends = (cloudData["friends"] as List?) ?? [];
    final List<Map<String, dynamic>> mergedFriendsList = [];

    for (var item in rawCloudFriends) {
      if (item is Map) {
        final name = (item["name"]?.toString() ?? '').trim();
        final key = name.toLowerCase();

        if (!localFriendsMap.containsKey(key)) {
          // Friend in cloud but not in local app -> Add to local app!
          final friend = FriendModel(
            name: name,
            phone: item["phone"]?.toString() ?? '',
            desc: item["desc"]?.toString() ?? '',
            balance: (item["balance"] as num?)?.toInt() ?? 0,
            type: item["type"]?.toString() ?? 'settled',
            lastMessage: item["lastMessage"]?.toString() ?? '',
            lastDate: item["lastDate"]?.toString() ?? '',
            history: (item["history"] is List)
                ? List<Map<dynamic, dynamic>>.from(item["history"])
                : [],
          );
          await _friendsBox.add(friend);
          localFriendsMap[key] = friend;
          friendsMergedCount++;
        } else {
          // Friend in both -> Merge their chat histories without duplicate transactions
          final localFriend = localFriendsMap[key]!;
          final List<dynamic> cloudHist = (item["history"] as List?) ?? [];

          final Set<String> existingTx = {};
          for (var h in localFriend.history) {
            existingTx.add("${h['timestamp']}_${h['amount']}_${h['title']}");
          }

          bool historyUpdated = false;
          for (var ch in cloudHist) {
            if (ch is Map) {
              final fp = "${ch['timestamp']}_${ch['amount']}_${ch['title']}";
              if (!existingTx.contains(fp)) {
                localFriend.history.add(Map<dynamic, dynamic>.from(ch));
                existingTx.add(fp);
                historyUpdated = true;
              }
            }
          }

          if (historyUpdated) {
            await localFriend.save();
            friendsMergedCount++;
          }
        }
      }
    }

    // Prepare complete merged friends list for cloud
    for (var f in _friendsBox.values) {
      mergedFriendsList.add({
        "name": f.name,
        "phone": f.phone,
        "desc": f.desc,
        "balance": f.balance,
        "type": f.type,
        "lastMessage": f.lastMessage,
        "lastDate": f.lastDate,
        "history": f.history,
      });
    }

    // --- D. MERGE TAGS ---
    final Set<String> allTags = Set.from(_tagsBox.values);
    final List<dynamic> cloudTags = (cloudData["tags"] as List?) ?? [];
    for (var t in cloudTags) {
      if (t != null && t.toString().trim().isNotEmpty) {
        final tag = t.toString().trim();
        if (allTags.add(tag)) {
          await _tagsBox.add(tag);
        }
      }
    }

    // Final combined payload to update in Google Drive
    final Map<String, dynamic> mergedPayload = {
      "app": "Hisaab+",
      "version": "4.4.2",
      "exportDate": DateTime.now().toIso8601String(),
      "transactions": mergedTxList,
      "friends": mergedFriendsList,
      "tags": allTags.toList(),
      "personalExpenses": mergedExpList,
    };

    final result = SyncResult(
      downloadedTransactions: downloadedTx,
      uploadedTransactions: uploadedTx,
      downloadedExpenses: downloadedExp,
      uploadedExpenses: uploadedExp,
      friendsMerged: friendsMergedCount,
      message:
          "Sync complete: $downloadedTx tx downloaded, $downloadedExp expenses downloaded, $friendsMergedCount friends synchronized.",
    );

    return (result: result, mergedData: mergedPayload);
  }
}

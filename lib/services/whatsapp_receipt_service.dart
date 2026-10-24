import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/friend_model.dart';
import 'drive_sync_service.dart';

class WhatsAppReceiptService {
  static final WhatsAppReceiptService instance =
      WhatsAppReceiptService._internal();
  WhatsAppReceiptService._internal();

  static const String autoSendSettingKey = 'auto_open_whatsapp_receipt';

  bool get isAutoSendEnabled {
    try {
      if (Hive.isBoxOpen('settings_box')) {
        return Hive.box('settings_box')
            .get(autoSendSettingKey, defaultValue: false);
      }
    } catch (_) {}
    return false;
  }

  set isAutoSendEnabled(bool value) {
    try {
      if (Hive.isBoxOpen('settings_box')) {
        Hive.box('settings_box').put(autoSendSettingKey, value);
      }
    } catch (_) {}
  }

  /// Current user's first/display name (e.g. "Sahil")
  String getUserDisplayName() {
    try {
      // 1. Check DriveSyncService
      final driveUser = DriveSyncService.instance.currentUser;
      if (driveUser?.displayName?.trim().isNotEmpty == true) {
        return driveUser!.displayName!.trim().split(' ').first;
      }

      // 2. Check settings_box
      if (Hive.isBoxOpen('settings_box')) {
        final savedName =
            Hive.box('settings_box').get('user_name') as String?;
        if (savedName != null && savedName.trim().isNotEmpty) {
          return savedName.trim().split(' ').first;
        }
      }
    } catch (e) {
      debugPrint('getUserDisplayName error: $e');
    }
    return "Sahil";
  }

  /// Clean & normalize 10-digit phone number with country code for WhatsApp wa.me
  String? sanitizePhoneNumber(String? rawPhone) {
    if (rawPhone == null) return null;
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;

    if (digits.length == 10) {
      return "91$digits";
    } else if (digits.length == 11 && digits.startsWith('0')) {
      return "91${digits.substring(1)}";
    } else if (digits.length >= 11) {
      return digits;
    }
    return null;
  }

  /// Format receipt text matching exact requested structure
  String generateReceiptText({
    required FriendModel friend,
    required int amount,
    required String txType, // 'diya' ya 'liya'
    required String note,
    DateTime? date,
    String? customUserName,
  }) {
    final entryDate = date ?? DateTime.now();
    final dateFormatted = DateFormat("d MMM yyyy").format(entryDate);
    final userName = customUserName ?? getUserDisplayName();
    final friendName = friend.name.trim();
    final cleanNote = note.trim().isNotEmpty ? note.trim() : "Hisaab Entry";

    // Diya vs Liya label
    final actionLabel =
        txType == 'diya' ? "$userName ne diya" : "$userName ko mila";

    // Friend balance label from friend perspective
    String balanceStatus;
    if (friend.type == 'lena' && friend.balance > 0) {
      balanceStatus = "Dena hai apko )";
    } else if (friend.type == 'dena' && friend.balance > 0) {
      balanceStatus = "Lena hai apko )";
    } else {
      balanceStatus = "Hisaab barabar)";
    }

    final greeting = friendName.isNotEmpty
        ? "Hello $friendName, maine aaj entry note ki hai:"
        : "Hello , maine aaj entry note ki hai:";

    final buffer = StringBuffer();
    buffer.writeln("* Hisaab+ Update:");
    buffer.writeln(greeting);
    buffer.writeln("  -> Balance : ₹$amount ($actionLabel)");
    buffer.writeln("  -> Note: $cleanNote");
    buffer.writeln("  -> Tarikh: $dateFormatted");
    buffer.write(" Abhi Total Balance : ₹${friend.balance} ($balanceStatus");

    return buffer.toString();
  }

  /// Launch WhatsApp or fallback to SharePlus
  Future<bool> sendReceipt({
    required FriendModel friend,
    required int amount,
    required String txType,
    required String note,
    DateTime? date,
    String? customUserName,
  }) async {
    final message = generateReceiptText(
      friend: friend,
      amount: amount,
      txType: txType,
      note: note,
      date: date,
      customUserName: customUserName,
    );

    final cleanPhone = sanitizePhoneNumber(friend.phone);

    if (cleanPhone != null && cleanPhone.isNotEmpty) {
      // Direct WhatsApp link
      final uri = Uri.parse(
        "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}",
      );

      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (e) {
        debugPrint("WhatsApp launchUrl error: $e");
      }

      // Try whatsapp:// scheme fallback
      try {
        final waUri = Uri.parse(
          "whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}",
        );
        final launched = await launchUrl(
          waUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (e) {
        debugPrint("WhatsApp deep-link error: $e");
      }
    }

    // Fallback: Share sheet
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: "Hisaab+ Update - ${friend.name}",
        ),
      );
      return true;
    } catch (e) {
      debugPrint("SharePlus error: $e");
      return false;
    }
  }
}

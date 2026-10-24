import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/friend_model.dart';
import '../services/whatsapp_receipt_service.dart';
import '../theme/app_colors.dart';
import 'custom_toast.dart';

class WhatsAppReceiptSheet extends StatefulWidget {
  final FriendModel friend;
  final int amount;
  final String txType;
  final String note;
  final DateTime? date;

  const WhatsAppReceiptSheet({
    super.key,
    required this.friend,
    required this.amount,
    required this.txType,
    required this.note,
    this.date,
  });

  static Future<void> show({
    required BuildContext context,
    required FriendModel friend,
    required int amount,
    required String txType,
    required String note,
    DateTime? date,
  }) async {
    // Check if auto-send is enabled and phone is available
    if (WhatsAppReceiptService.instance.isAutoSendEnabled &&
        friend.phone.trim().isNotEmpty) {
      await WhatsAppReceiptService.instance.sendReceipt(
        friend: friend,
        amount: amount,
        txType: txType,
        note: note,
        date: date,
      );
      return;
    }

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WhatsAppReceiptSheet(
        friend: friend,
        amount: amount,
        txType: txType,
        note: note,
        date: date,
      ),
    );
  }

  @override
  State<WhatsAppReceiptSheet> createState() => _WhatsAppReceiptSheetState();
}

class _WhatsAppReceiptSheetState extends State<WhatsAppReceiptSheet> {
  late bool _autoSend;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _autoSend = WhatsAppReceiptService.instance.isAutoSendEnabled;
  }

  Future<void> _handleSend() async {
    setState(() => _isSending = true);
    final success = await WhatsAppReceiptService.instance.sendReceipt(
      friend: widget.friend,
      amount: widget.amount,
      txType: widget.txType,
      note: widget.note,
      date: widget.date,
    );

    if (mounted) {
      setState(() => _isSending = false);
      Navigator.of(context).pop();
      if (!success) {
        AppToast.show(
          context,
          title: "WhatsApp open nahi ho paya, share sheet try karein",
          type: ToastType.warning,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final messagePreview = WhatsAppReceiptService.instance.generateReceiptText(
      friend: widget.friend,
      amount: widget.amount,
      txType: widget.txType,
      note: widget.note,
      date: widget.date,
    );

    final bool hasPhone = widget.friend.phone.trim().isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: colors.border, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Header with success badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hisaab Jod Diya Gaya!",
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasPhone
                            ? "${widget.friend.name} ko WhatsApp update bhejein?"
                            : "${widget.friend.name} ko receipt share karein?",
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: colors.textMuted),
                  splashRadius: 20,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Message Preview Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.border,
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 32),
                    child: Text(
                      messagePreview,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: colors.textPrimary,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: messagePreview));
                        AppToast.show(
                          context,
                          title: "Receipt text copy ho gaya!",
                          type: ToastType.success,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Auto-send Toggle Checkbox
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _autoSend = !_autoSend;
                  WhatsAppReceiptService.instance.isAutoSendEnabled = _autoSend;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _autoSend,
                        activeColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _autoSend = val ?? false;
                            WhatsAppReceiptService.instance.isAutoSendEnabled =
                                _autoSend;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Agli baar se seedha WhatsApp kholein",
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                // Dismiss Button
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "Skip / Done",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Primary Send WhatsApp Button
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF047857)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669)
                              .withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                      label: Text(
                        _isSending
                            ? "Khol rahe hain..."
                            : hasPhone
                                ? "WhatsApp Bhejein"
                                : "Share Receipt",
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: _isSending ? null : _handleSend,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

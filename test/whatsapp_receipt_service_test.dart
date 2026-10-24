import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab_plus/models/friend_model.dart';
import 'package:hisaab_plus/services/whatsapp_receipt_service.dart';

void main() {
  group('WhatsAppReceiptService Tests', () {
    final service = WhatsAppReceiptService.instance;

    test('Sanitizes various phone number formats correctly', () {
      expect(service.sanitizePhoneNumber('9876543210'), '919876543210');
      expect(service.sanitizePhoneNumber('+91 98765-43210'), '919876543210');
      expect(service.sanitizePhoneNumber('09876543210'), '919876543210');
      expect(service.sanitizePhoneNumber('+919876543210'), '919876543210');
      expect(service.sanitizePhoneNumber(''), isNull);
      expect(service.sanitizePhoneNumber(null), isNull);
      expect(service.sanitizePhoneNumber('abc'), isNull);
    });

    test('Generates exact requested receipt message for Diya (Lena)', () {
      final friend = FriendModel(
        name: 'Rahul',
        phone: '9876543210',
        desc: 'Dost',
        balance: 1500,
        type: 'lena',
      );

      final date = DateTime(2026, 10, 24);
      final text = service.generateReceiptText(
        friend: friend,
        amount: 500,
        txType: 'diya',
        note: 'Chai aur Samose',
        date: date,
        customUserName: 'Sahil',
      );

      const expected = '''* Hisaab+ Update:
Hello Rahul, maine aaj entry note ki hai:
  -> Balance : ₹500 (Sahil ne diya)
  -> Note: Chai aur Samose
  -> Tarikh: 24 Oct 2026
 Abhi Total Balance : ₹1500 (Dena hai apko )''';

      expect(text, expected);
    });

    test('Generates exact requested receipt message for Liya', () {
      final friend = FriendModel(
        name: 'Rahul',
        phone: '9876543210',
        desc: 'Dost',
        balance: 1000,
        type: 'lena',
      );

      final date = DateTime(2026, 10, 24);
      final text = service.generateReceiptText(
        friend: friend,
        amount: 500,
        txType: 'liya',
        note: 'Payment wapas',
        date: date,
        customUserName: 'Sahil',
      );

      const expected = '''* Hisaab+ Update:
Hello Rahul, maine aaj entry note ki hai:
  -> Balance : ₹500 (Sahil ko mila)
  -> Note: Payment wapas
  -> Tarikh: 24 Oct 2026
 Abhi Total Balance : ₹1000 (Dena hai apko )''';

      expect(text, expected);
    });

    test('Handles settled balance gracefully', () {
      final friend = FriendModel(
        name: 'Aman',
        phone: '9876543210',
        desc: 'Roommate',
        balance: 0,
        type: 'settled',
      );

      final date = DateTime(2026, 10, 24);
      final text = service.generateReceiptText(
        friend: friend,
        amount: 200,
        txType: 'liya',
        note: 'Hisaab barabar',
        date: date,
        customUserName: 'Sahil',
      );

      expect(text, contains('Abhi Total Balance : ₹0 (Hisaab barabar)'));
    });
  });
}

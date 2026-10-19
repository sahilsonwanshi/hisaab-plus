import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab_plus/models/friend_model.dart';
import 'package:hisaab_plus/services/pdf_statement_service.dart';

void main() {
  test('generateStatementPdf creates non-empty valid PDF bytes', () async {
    final friend = FriendModel(
      name: 'Rohan Sharma',
      phone: '9876543210',
      desc: 'Friend',
      balance: 500,
      type: 'lena',
      history: [
        {
          'type': 'diya',
          'amount': 1500,
          'title': 'Dinner bill',
          'mode': 'UPI',
          'date': '19 Oct 2026',
        },
        {
          'type': 'liya',
          'amount': 1000,
          'title': 'Cash return',
          'mode': 'Cash',
          'date': '19 Oct 2026',
        },
      ],
    );

    final bytes = await PdfStatementService.generateStatementPdf(
      friend: friend,
      filteredList: friend.history,
      periodLabel: 'Iss Mahine',
    );

    expect(bytes, isNotNull);
    expect(bytes.isNotEmpty, isTrue);
    // PDF signature check (%PDF-)
    expect(bytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46]));
  });
}

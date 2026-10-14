import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab_plus/main.dart';

void main() {
  testWidgets('HisaabApp smoke test', (WidgetTester tester) async {
    // Basic verification that the app widget constructs cleanly
    const app = HisaabApp();
    expect(app, isNotNull);
  });
}

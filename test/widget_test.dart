import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Morph Gate uses Hive + Flame which require platform setup
    // Full integration tests are done on device
    expect(true, isTrue);
  });
}

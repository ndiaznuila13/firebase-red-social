import 'package:flutter_test/flutter_test.dart';
import 'package:clase23_firebase_demo/main.dart';

void main() {
  testWidgets('TikTokApp instantiation smoke test', (WidgetTester tester) async {
    expect(const TikTokApp(), isNotNull);
  });
}

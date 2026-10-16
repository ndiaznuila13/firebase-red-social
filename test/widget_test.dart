import 'package:flutter_test/flutter_test.dart';
import 'package:clase23_firebase_demo/main.dart';

void main() {
  testWidgets('MyApp smoke test', (WidgetTester tester) async {
    expect(const MyApp(), isNotNull);
  });
}

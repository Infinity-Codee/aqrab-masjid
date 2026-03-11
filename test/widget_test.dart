import 'package:flutter_test/flutter_test.dart';

import 'package:aqrab_masjid/main.dart';

void main() {
  testWidgets('App launches with splash title', (WidgetTester tester) async {
    await tester.pumpWidget(const AqrabMasjidApp());
    expect(find.text('تطبيق أقرب جامع'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/app/app.dart';

void main() {
  testWidgets('FreedomCircle launches into the branded splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FreedomCircleApp());

    expect(find.text('FreedomCircle'), findsOneWidget);
    expect(
      find.text('Grow stronger. Heal together. Walk in faith.'),
      findsOneWidget,
    );
    expect(find.text('Begin'), findsOneWidget);
  });

  testWidgets('Onboarding can advance from splash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FreedomCircleApp());

    await tester.tap(find.text('Begin'));
    await tester.pumpAndSettle();

    expect(find.text('You are not alone'), findsOneWidget);
  });
}

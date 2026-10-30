import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duo/app.dart';

void main() {
  testWidgets('Duo smoke test - unauthenticated user lands on AuthScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DuoApp(),
      ),
    );

    // Initial pump & settle
    await tester.pumpAndSettle();

    // Verify AuthScreen rendered via auth guard
    expect(find.text('duo.'), findsOneWidget);
    expect(find.text('Two people. One little world.'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}

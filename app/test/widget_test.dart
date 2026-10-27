import 'package:flutter_test/flutter_test.dart';
import 'package:thousand/main.dart';

void main() {
  testWidgets('home screen opens the game table', (tester) async {
    await tester.pumpWidget(const ThousandApp());
    expect(find.text('Тысяча'), findsOneWidget);

    await tester.tap(find.text('Играть с ботами'));
    await tester.pumpAndSettle();
    expect(find.text('Вася'), findsWidgets);
    expect(find.text('Петя'), findsWidgets);

    // Let the bots run so pending timers don't leak past the test.
    await tester.pump(const Duration(seconds: 5));
  });
}

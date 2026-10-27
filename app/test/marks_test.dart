import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thousand/widgets/marks.dart';

void main() {
  testWidgets('one icon per bolt and concession', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PenaltyMarks(bolts: 2, concessions: 1)),
    );
    expect(find.byType(BoltIcon), findsNWidgets(2));
    expect(find.byIcon(Icons.edit), findsOneWidget);
  });

  testWidgets('nothing when clean', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PenaltyMarks(bolts: 0, concessions: 0)),
    );
    expect(find.byType(BoltIcon), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
  });
}

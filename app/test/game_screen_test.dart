import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thousand/game_controller.dart';
import 'package:thousand/screens/game_screen.dart';
import 'package:thousand/settings.dart';

void main() {
  const sizes = {
    'phone landscape': Size(844, 390),
    'small phone landscape': Size(640, 360),
    'tablet': Size(1280, 800),
    'phone portrait': Size(390, 844),
  };
  for (final MapEntry(key: name, value: size) in sizes.entries) {
    testWidgets('plays whole rounds without layout errors: $name', (
      tester,
    ) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final c = GameController();
      await tester.pumpWidget(
        SettingsScope(
          settings: Settings.defaults(),
          child: MaterialApp(home: GameScreen(controller: c)),
        ),
      );

      var rounds = 0;
      for (var i = 0; i < 400 && rounds < 3 && !c.game.isOver; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (c.record != null) {
          await tester.tap(find.text('Дальше'));
          rounds++;
        } else {
          c.autoMove();
        }
      }
      expect(rounds, 3);

      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }
}

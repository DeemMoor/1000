import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thousand/screens/settings_screen.dart';
import 'package:thousand/settings.dart';

void main() {
  testWidgets('deck picker saves the chosen deck', (tester) async {
    final settings = Settings.defaults();
    await tester.pumpWidget(
      SettingsScope(
        settings: settings,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    expect(settings.cardStyle, CardStyle.atlas);

    await tester.tap(find.text('Колода'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Английская'));
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(settings.cardStyle, CardStyle.english);

    await tester.tap(find.text('Колода'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Простая'));
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(settings.cardStyle, CardStyle.english);
  });

  testWidgets('ace marriage switch feeds the rules', (tester) async {
    final settings = Settings.defaults();
    await tester.pumpWidget(
      SettingsScope(
        settings: settings,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.tap(find.text('Тузовый марьяж'));
    await tester.pump();
    expect(settings.rules.aceMarriage, isTrue);
  });
}

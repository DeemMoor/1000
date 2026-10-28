import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thousand/settings.dart';
import 'package:thousand/update/release.dart';
import 'package:thousand/update/update_controller.dart';
import 'package:thousand/widgets/update_dialog.dart';

void main() {
  test('versions compare numerically', () {
    expect(isNewer('1.0.10', '1.0.9'), isTrue);
    expect(isNewer('v1.1.0', '1.0.9+42'), isTrue);
    expect(isNewer('1.0.0', '1.0.0+7'), isFalse);
    expect(isNewer('0.9.9', '1.0.0'), isFalse);
    expect(isNewer('2', '1.9.9'), isTrue);
  });

  test('checksum listing is parsed', () {
    const listing = '''
abc123  thousand-1.1.0-windows-setup.exe
DEF456 *thousand-1.1.0.apk
''';
    expect(expectedHash(listing, 'thousand-1.1.0-windows-setup.exe'), 'abc123');
    expect(expectedHash(listing, 'thousand-1.1.0.apk'), 'def456');
    expect(expectedHash(listing, 'missing.exe'), isNull);
  });

  testWidgets('update dialog shows release notes', (tester) async {
    final updates = UpdateController(Settings.defaults())
      ..available = const Release(
        version: '1.1.0',
        notes: '### Новое\n\n- **Онлайн** игра\n- Быстрее боты',
        page: 'https://github.com/DeemMoor/1000/releases/tag/v1.1.0',
        installer: 'https://example.com/thousand-1.1.0-windows-setup.exe',
      );
    await tester.pumpWidget(
      UpdateScope(
        controller: updates,
        child: const MaterialApp(home: Scaffold(body: UpdateDialog())),
      ),
    );
    expect(find.text('Новая версия 1.1.0'), findsOneWidget);
    expect(find.text('Новое'), findsOneWidget);
    expect(find.text('Обновить'), findsOneWidget);
    expect(find.textContaining('Быстрее боты'), findsOneWidget);
  });
}

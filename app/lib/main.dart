import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/game_screen.dart';
import 'screens/settings_screen.dart';
import 'settings.dart';
import 'update/update_controller.dart';
import 'widgets/table_ui.dart';
import 'widgets/update_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Phones: landscape, full screen. No effect on web and desktop.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final settings = await Settings.load();
  final updates = UpdateController(settings)..checkIfDue();
  runApp(ThousandApp(settings: settings, updates: updates));
}

class ThousandApp extends StatelessWidget {
  const ThousandApp({super.key, required this.settings, this.updates});

  final Settings settings;

  /// Null disables update checks (tests).
  final UpdateController? updates;

  @override
  Widget build(BuildContext context) {
    final app = SettingsScope(
      settings: settings,
      child: MaterialApp(
        title: 'Тысяча',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        ),
        home: const HomeScreen(),
      ),
    );
    final updates = this.updates;
    return updates == null ? app : UpdateScope(controller: updates, child: app);
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '1000',
              style: TextStyle(
                color: Colors.white,
                fontSize: 72,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              'Тысяча',
              style: TextStyle(color: Colors.white70, fontSize: 24),
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const GameScreen()),
              ),
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text('Играть с ботами'),
            ),
            const SizedBox(height: 12),
            const OutlinedButton(
              onPressed: null,
              child: Text('Онлайн — скоро'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
              icon: const Icon(Icons.settings),
              label: const Text('Настройки'),
            ),
            if (UpdateController.maybeOf(context)?.available case final r?) ...[
              const SizedBox(height: 24),
              GoldButton(
                'Вышла версия ${r.version}',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const UpdateDialog(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

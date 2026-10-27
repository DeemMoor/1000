import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Phones: landscape, full screen. No effect on web and desktop.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ThousandApp());
}

class ThousandApp extends StatelessWidget {
  const ThousandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Тысяча',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
      ),
      home: const HomeScreen(),
    );
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
          ],
        ),
      ),
    );
  }
}

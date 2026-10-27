import 'package:flutter/material.dart';
import 'package:thousand_engine/thousand_engine.dart' as engine;

import '../settings.dart';
import '../widgets/playing_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Settings.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          const _Header('Графика'),
          ListTile(
            title: const Text('Колода'),
            subtitle: Text(settings.cardStyle.title),
            trailing: PlayingCard(
              const engine.Card(engine.Suit.spades, engine.Rank.queen),
              width: 32,
            ),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => const DeckPicker(),
            ),
          ),
          const _Header('Правила'),
          SwitchListTile(
            title: const Text('Тузовый марьяж'),
            subtitle: const Text(
              'Четыре туза — 200 очков. Действует с новой игры',
            ),
            value: settings.aceMarriage,
            onChanged: (v) => settings.aceMarriage = v,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Shows the queen of spades of every deck; the choice is saved on confirm.
class DeckPicker extends StatefulWidget {
  const DeckPicker({super.key});

  @override
  State<DeckPicker> createState() => _DeckPickerState();
}

class _DeckPickerState extends State<DeckPicker> {
  late CardStyle _selected = Settings.of(context).cardStyle;

  static const _sample = engine.Card(engine.Suit.spades, engine.Rank.queen);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Колода', textAlign: TextAlign.center),
      content: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final style in CardStyle.values)
              GestureDetector(
                onTap: () => setState(() => _selected = style),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(10),
                  color: style == _selected ? Colors.amber : null,
                  child: Column(
                    children: [
                      PlayingCard(_sample, width: 84, style: style),
                      const SizedBox(height: 6),
                      Text(style.title),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            Settings.of(context).cardStyle = _selected;
            Navigator.pop(context);
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

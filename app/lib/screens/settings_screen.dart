import 'dart:math';

import 'package:flutter/material.dart';
import 'package:thousand_engine/thousand_engine.dart' as engine;

import '../settings.dart';
import '../widgets/playing_card.dart';
import '../widgets/table_ui.dart';

const _sample = engine.Card(engine.Suit.spades, engine.Rank.queen);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Settings.of(context);
    return Scaffold(
      body: FeltBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Настройки',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TablePanel(
                    title: 'Графика',
                    padding: EdgeInsets.zero,
                    children: [
                      _Row(
                        title: 'Колода',
                        subtitle: settings.cardStyle.title,
                        trailing: PlayingCard(_sample, width: 40),
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (_) => const DeckPicker(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TablePanel(
                    title: 'Правила',
                    padding: EdgeInsets.zero,
                    children: [
                      _Row(
                        title: 'Тузовый марьяж',
                        subtitle: 'Четыре туза — 200 очков. С новой игры',
                        trailing: Switch(
                          activeThumbColor: Colors.white,
                          activeTrackColor: gold,
                          value: settings.aceMarriage,
                          onChanged: (v) => settings.aceMarriage = v,
                        ),
                        onTap: () =>
                            settings.aceMarriage = !settings.aceMarriage,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// Shows the queen of spades of every deck; the choice is saved on confirm.
class DeckPicker extends StatefulWidget {
  const DeckPicker({super.key});

  @override
  State<DeckPicker> createState() => _DeckPickerState();
}

class _DeckPickerState extends State<DeckPicker> {
  late CardStyle _selected = Settings.of(context).cardStyle;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = min(100.0, (width - 120) / 3 - 24);
    return Dialog(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      child: TablePanel(
        title: 'Графика колоды',
        width: min(520, width - 32),
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final style in CardStyle.values)
                GestureDetector(
                  onTap: () => setState(() => _selected = style),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: style == _selected ? gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlayingCard(_sample, width: cardWidth, style: style),
                        const SizedBox(height: 6),
                        Text(
                          style.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          PanelButtons([
            GoldButton('Отмена', onPressed: () => Navigator.pop(context)),
            GoldButton(
              'Сохранить',
              onPressed: () {
                Settings.of(context).cardStyle = _selected;
                Navigator.pop(context);
              },
            ),
          ]),
        ],
      ),
    );
  }
}

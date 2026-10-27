import 'package:flutter/material.dart';

/// Shared look of the card table: felt, dark panels, gold buttons.
const felt = Color(0xFF1E7A2E);
const feltEdge = Color(0xFF0E4A17);
const gold = Color(0xFFF6C344);
const panelBody = Color(0xFF4A4A4A);
const panelTitle = Color(0xFFE8E8E8);

class FeltBackground extends StatelessWidget {
  const FeltBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: RadialGradient(colors: [felt, feltEdge], radius: 1.2),
    ),
    child: child,
  );
}

/// Light title bar over a dark body, like a dialog lying on the table.
class TablePanel extends StatelessWidget {
  const TablePanel({
    super.key,
    required this.title,
    required this.children,
    this.width,
    this.padding = const EdgeInsets.fromLTRB(12, 16, 12, 16),
  });

  final String title;
  final List<Widget> children;
  final double? width;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 16)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: panelTitle,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            color: panelBody,
            padding: padding,
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ],
      ),
    );
  }
}

class GoldButton extends StatelessWidget {
  const GoldButton(this.label, {super.key, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: gold,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.white24,
      minimumSize: const Size(120, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    ),
    onPressed: onPressed,
    child: Text(label),
  );
}

/// Centered row of buttons that wraps on narrow screens.
class PanelButtons extends StatelessWidget {
  const PanelButtons(this.buttons, {super.key});

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: buttons,
    ),
  );
}

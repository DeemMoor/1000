import 'package:flutter/material.dart';
import 'package:thousand_engine/thousand_engine.dart';

import '../labels.dart';

const suitRed = Color(0xFFC62828);
const suitBlack = Color(0xFF212121);

/// Suit drawn as a shape, so it looks the same everywhere instead of
/// depending on how a font renders ♠♣♦♥.
class SuitIcon extends StatelessWidget {
  const SuitIcon(this.suit, {super.key, this.size = 20, this.color});

  final Suit suit;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _SuitPainter(suit, color ?? (isRed(suit) ? suitRed : suitBlack)),
  );
}

/// Suit on a small white tile: readable on the felt and on dark panels.
class SuitChip extends StatelessWidget {
  const SuitChip(this.suit, {super.key, this.size = 16});

  final Suit suit;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(size * 0.15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(size * 0.25),
    ),
    child: SuitIcon(suit, size: size),
  );
}

/// Text in which ♠♣♦♥ are replaced by [SuitChip]s.
class SuitText extends StatelessWidget {
  const SuitText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  static final _symbols = {for (final s in Suit.values) s.symbol: s};

  @override
  Widget build(BuildContext context) {
    final fontSize =
        style?.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 14;
    final spans = <InlineSpan>[];
    final buffer = StringBuffer();
    for (final char in text.characters) {
      final suit = _symbols[char];
      if (suit == null) {
        buffer.write(char);
        continue;
      }
      if (buffer.isNotEmpty) {
        spans.add(TextSpan(text: buffer.toString()));
        buffer.clear();
      }
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SuitChip(suit, size: fontSize),
        ),
      );
    }
    if (buffer.isNotEmpty) spans.add(TextSpan(text: buffer.toString()));
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      textAlign: textAlign,
    );
  }
}

class _SuitPainter extends CustomPainter {
  _SuitPainter(this.suit, this.color);

  final Suit suit;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width, size.height);
    final paint = Paint()..color = color;
    switch (suit) {
      case Suit.hearts:
        canvas.drawPath(
          Path()
            ..moveTo(0.5, 0.28)
            ..cubicTo(0.5, 0.02, 0.02, 0.0, 0.02, 0.36)
            ..cubicTo(0.02, 0.6, 0.35, 0.76, 0.5, 0.96)
            ..cubicTo(0.65, 0.76, 0.98, 0.6, 0.98, 0.36)
            ..cubicTo(0.98, 0.0, 0.5, 0.02, 0.5, 0.28),
          paint,
        );
      case Suit.diamonds:
        canvas.drawPath(
          Path()
            ..moveTo(0.5, 0.02)
            ..lineTo(0.86, 0.5)
            ..lineTo(0.5, 0.98)
            ..lineTo(0.14, 0.5)
            ..close(),
          paint,
        );
      case Suit.spades:
        canvas.drawPath(
          Path()
            ..moveTo(0.5, 0.02)
            ..cubicTo(0.36, 0.24, 0.02, 0.36, 0.02, 0.6)
            ..cubicTo(0.02, 0.84, 0.32, 0.88, 0.46, 0.72)
            ..lineTo(0.36, 0.98)
            ..lineTo(0.64, 0.98)
            ..lineTo(0.54, 0.72)
            ..cubicTo(0.68, 0.88, 0.98, 0.84, 0.98, 0.6)
            ..cubicTo(0.98, 0.36, 0.64, 0.24, 0.5, 0.02),
          paint,
        );
      case Suit.clubs:
        canvas
          ..drawCircle(const Offset(0.5, 0.26), 0.22, paint)
          ..drawCircle(const Offset(0.25, 0.56), 0.22, paint)
          ..drawCircle(const Offset(0.75, 0.56), 0.22, paint)
          ..drawPath(
            Path()
              ..moveTo(0.5, 0.4)
              ..lineTo(0.64, 0.98)
              ..lineTo(0.36, 0.98)
              ..close(),
            paint,
          );
    }
  }

  @override
  bool shouldRepaint(_SuitPainter old) =>
      old.suit != suit || old.color != color;
}

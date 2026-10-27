import 'package:flutter/material.dart';

/// Bolts ("болт") and concessions ("роспись") a player has collected
/// towards the next penalty, drawn as bolts and pencils.
class PenaltyMarks extends StatelessWidget {
  const PenaltyMarks({
    super.key,
    required this.bolts,
    required this.concessions,
    this.size = 22,
  });

  final int bolts;
  final int concessions;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (bolts == 0 && concessions == 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < bolts; i++)
          Tooltip(
            message: 'Болт',
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.08),
              child: BoltIcon(size: size),
            ),
          ),
        if (bolts > 0 && concessions > 0) SizedBox(width: size * 0.3),
        for (var i = 0; i < concessions; i++)
          Tooltip(
            message: 'Роспись',
            child: Icon(Icons.edit, size: size, color: const Color(0xFFF6C344)),
          ),
      ],
    );
  }
}

class BoltIcon extends StatelessWidget {
  const BoltIcon({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size * 0.6, size), painter: _BoltPainter());
}

class _BoltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final metal = Paint()..color = const Color(0xFFCFD8DC);
    final shade = Paint()..color = const Color(0xFF90A4AE);
    final edge = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.05;

    // Hex head seen from the side: a wide block with chamfered top corners.
    final headH = h * 0.28;
    final head = Path()
      ..moveTo(0, headH)
      ..lineTo(0, headH * 0.3)
      ..lineTo(w * 0.15, 0)
      ..lineTo(w * 0.85, 0)
      ..lineTo(w, headH * 0.3)
      ..lineTo(w, headH)
      ..close();
    canvas
      ..drawPath(head, metal)
      ..drawRect(Rect.fromLTWH(w * 0.33, 0, w * 0.34, headH), shade)
      ..drawPath(head, edge);

    // Shaft with diagonal thread lines and a pointed tip.
    final left = w * 0.25;
    final right = w * 0.75;
    final tip = h * 0.95;
    final shaft = Path()
      ..moveTo(left, headH)
      ..lineTo(right, headH)
      ..lineTo(right, tip - w * 0.15)
      ..lineTo(w * 0.5, tip)
      ..lineTo(left, tip - w * 0.15)
      ..close();
    canvas
      ..drawPath(shaft, metal)
      ..drawPath(shaft, edge);
    final thread = Paint()
      ..color = const Color(0xFF546E7A)
      ..strokeWidth = h * 0.04;
    for (var y = headH + h * 0.1; y < tip - w * 0.2; y += h * 0.11) {
      canvas.drawLine(Offset(left, y + h * 0.05), Offset(right, y), thread);
    }
  }

  @override
  bool shouldRepaint(_BoltPainter oldDelegate) => false;
}

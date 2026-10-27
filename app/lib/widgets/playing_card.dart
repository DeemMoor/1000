import 'package:flutter/material.dart';
import 'package:thousand_engine/thousand_engine.dart' as engine;

import '../labels.dart';

const cardAspect = 1.45;

/// Face-up card. [dimmed] greys out cards that can't be played now.
class PlayingCard extends StatelessWidget {
  const PlayingCard(
    this.card, {
    super.key,
    required this.width,
    this.dimmed = false,
    this.highlighted = false,
    this.tag,
  });

  final engine.Card card;
  final double width;
  final bool dimmed;
  final bool highlighted;

  /// Small label pinned under the card (e.g. who it's given to).
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final color = isRed(card.suit)
        ? const Color(0xFFC62828)
        : const Color(0xFF212121);
    final corner = TextStyle(
      color: color,
      fontSize: width * 0.24,
      fontWeight: FontWeight.w700,
      height: 1,
    );
    final face = Container(
      width: width,
      height: width * cardAspect,
      decoration: BoxDecoration(
        color: dimmed ? const Color(0xFFBDBDBD) : Colors.white,
        borderRadius: BorderRadius.circular(width * 0.09),
        border: Border.all(
          color: highlighted ? Colors.amber : Colors.black26,
          width: highlighted ? 3 : 1,
        ),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 3)],
      ),
      padding: EdgeInsets.all(width * 0.07),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(rankLabel(card.rank), style: corner),
                Text(card.suit.symbol, style: corner),
              ],
            ),
          ),
          Align(
            alignment: const Alignment(0.3, 0.45),
            child: Text(
              card.suit.symbol,
              style: TextStyle(color: color, fontSize: width * 0.55, height: 1),
            ),
          ),
        ],
      ),
    );
    if (tag == null) return face;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        face,
        Positioned(
          left: 0,
          right: 0,
          bottom: -2,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tag!,
                style: TextStyle(
                  fontSize: width * 0.16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CardBack extends StatelessWidget {
  const CardBack({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * cardAspect,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.09),
        border: Border.all(color: Colors.white, width: width * 0.05),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 3)],
      ),
    );
  }
}

/// A row of cards that overlap as much as needed to fit [maxWidth].
class CardFan extends StatelessWidget {
  const CardFan({
    super.key,
    required this.count,
    required this.cardWidth,
    required this.maxWidth,
    required this.itemBuilder,
    this.lift = 0,
  });

  final int count;
  final double cardWidth;
  final double maxWidth;
  final Widget Function(BuildContext, int) itemBuilder;

  /// Extra vertical room so items can be raised (e.g. selected cards).
  final double lift;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return SizedBox(height: cardWidth * cardAspect + lift);
    final natural = cardWidth * 1.05;
    final step = count == 1
        ? 0.0
        : ((maxWidth - cardWidth) / (count - 1)).clamp(0.0, natural);
    final width = cardWidth + step * (count - 1);
    return SizedBox(
      width: width,
      height: cardWidth * cardAspect + lift,
      child: Stack(
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              left: step * i,
              bottom: 0,
              child: itemBuilder(context, i),
            ),
        ],
      ),
    );
  }
}

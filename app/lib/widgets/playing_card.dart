import 'package:flutter/material.dart';

import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:thousand_engine/thousand_engine.dart' as engine;

import '../labels.dart';
import '../settings.dart';
import 'suit_icon.dart';

/// Height to width, matching the 360×540 SVG decks.
const cardAspect = 1.5;

/// Rounded, shadowed frame shared by faces and backs.
class _CardFrame extends StatelessWidget {
  const _CardFrame({
    required this.width,
    required this.child,
    this.highlighted = false,
    this.dimmed = false,
  });

  final double width;
  final Widget child;
  final bool highlighted;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(width * 0.07);
    return Container(
      width: width,
      height: width * cardAspect,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 3)],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        color: dimmed ? Colors.black38 : null,
        border: Border.all(
          color: highlighted ? Colors.amber : Colors.black26,
          width: highlighted ? 3 : 0.5,
        ),
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

/// Face-up card in the deck chosen in [Settings]. [dimmed] darkens cards
/// that can't be played now.
class PlayingCard extends StatelessWidget {
  const PlayingCard(
    this.card, {
    super.key,
    required this.width,
    this.dimmed = false,
    this.highlighted = false,
    this.style,
  });

  final engine.Card card;
  final double width;
  final bool dimmed;
  final bool highlighted;

  /// Overrides the deck from settings (e.g. in the deck picker).
  final CardStyle? style;

  @override
  Widget build(BuildContext context) {
    final settings = Settings.of(context);
    final deck = style ?? settings.cardStyle;
    final dir = deck.assetDir;
    return _CardFrame(
      width: width,
      dimmed: dimmed,
      highlighted: highlighted,
      child: dir == null
          ? _SimpleFace(card, width: width)
          : _art(
              deck == settings.cardStyle ? settings.images.face(card) : null,
              '$dir/${card.id}.svg',
              width,
            ),
    );
  }
}

class CardBack extends StatelessWidget {
  const CardBack({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final settings = Settings.of(context);
    final dir = settings.cardStyle.assetDir;
    return _CardFrame(
      width: width,
      child: dir == null
          ? DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: width * 0.05),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            )
          : _art(settings.images.back, '$dir/back.svg', width),
    );
  }
}

/// Cached raster if the deck is loaded, else the compiled vector asset.
Widget _art(ui.Image? image, String asset, double width) => image != null
    ? RawImage(
        image: image,
        width: width,
        height: width * cardAspect,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.medium,
      )
    : SvgPicture(
        AssetBytesLoader(asset),
        width: width,
        height: width * cardAspect,
        fit: BoxFit.fill,
      );

/// Plain face with large indices: easy to read on small screens.
class _SimpleFace extends StatelessWidget {
  const _SimpleFace(this.card, {required this.width});

  final engine.Card card;
  final double width;

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
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(width * 0.07),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(rankLabel(card.rank), style: corner),
                  SizedBox(height: width * 0.03),
                  SuitIcon(card.suit, size: width * 0.2),
                ],
              ),
            ),
            Align(
              alignment: const Alignment(0.3, 0.45),
              child: SuitIcon(card.suit, size: width * 0.5),
            ),
          ],
        ),
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
  });

  final int count;
  final double cardWidth;
  final double maxWidth;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return SizedBox(height: cardWidth * cardAspect);
    final natural = cardWidth * 1.05;
    final step = count == 1
        ? 0.0
        : ((maxWidth - cardWidth) / (count - 1)).clamp(0.0, natural);
    return SizedBox(
      width: cardWidth + step * (count - 1),
      height: cardWidth * cardAspect,
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

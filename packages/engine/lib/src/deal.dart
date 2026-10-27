import 'dart:math';

import 'card.dart';
import 'hand.dart';
import 'rules.dart';

const playerCount = 3;

int nextPlayer(int player) => (player + 1) % playerCount;

enum RedealReason { poorPrikup, fourNines }

class Deal {
  Deal(this.hands, this.prikup)
    : assert(hands.length == playerCount),
      assert(prikup.length == 3);

  /// 7 cards each, then 3 to the prikup.
  factory Deal.fromDeck(List<Card> deck) {
    assert(deck.length == 24);
    return Deal([
      for (var p = 0; p < playerCount; p++) deck.sublist(p * 7, p * 7 + 7),
    ], deck.sublist(21));
  }

  factory Deal.random([Random? random]) => Deal.fromDeck(Deck.shuffled(random));

  final List<List<Card>> hands;
  final List<Card> prikup;

  RedealReason? redealReason(GameRules rules) {
    if (prikup.points < rules.redealPrikupBelow) return RedealReason.poorPrikup;
    if (rules.redealOnFourNines && hands.any((h) => h.hasFourNines)) {
      return RedealReason.fourNines;
    }
    return null;
  }
}

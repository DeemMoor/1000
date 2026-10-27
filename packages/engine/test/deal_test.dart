import 'dart:math';

import 'package:thousand_engine/thousand_engine.dart';
import 'package:test/test.dart';

List<Card> cards(String ids) => ids.split(' ').map(Card.fromId).toList();

void main() {
  const rules = GameRules();

  test('random deal uses every card once', () {
    final deal = Deal.random(Random(1));
    expect(deal.hands.map((h) => h.length), [7, 7, 7]);
    expect(deal.prikup, hasLength(3));
    expect({...deal.hands.expand((h) => h), ...deal.prikup}, hasLength(24));
  });

  test('redeal on prikup under 5 points', () {
    final poor = Deal(
      [cards('AH'), cards('AS'), cards('AD')],
      cards('9H JS 9C'), // 2 points
    );
    expect(poor.redealReason(rules), RedealReason.poorPrikup);

    final ok = Deal([cards('AH'), cards('AS'), cards('AD')], cards('9H JS QC'));
    expect(ok.redealReason(rules), isNull);
  });

  test('redeal on four nines in one hand', () {
    final deal = Deal(
      [cards('9H 9S 9D 9C AH'), cards('AS'), cards('AD')],
      cards('10H 10S 10D'),
    );
    expect(deal.redealReason(rules), RedealReason.fourNines);
    expect(
      deal.redealReason(const GameRules(redealOnFourNines: false)),
      isNull,
    );
  });

  test('marriage value, ace marriage only when enabled', () {
    final hand = cards('KH QH KS QS AH AS AD AC');
    expect(hand.marriages, [Suit.spades, Suit.hearts]);
    expect(hand.marriageValue(rules), 140);
    expect(hand.marriageValue(const GameRules(aceMarriage: true)), 340);
  });
}

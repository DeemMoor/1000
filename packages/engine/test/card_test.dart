import 'package:thousand_engine/thousand_engine.dart';
import 'package:test/test.dart';

void main() {
  test('deck has 24 unique cards worth 120 points', () {
    expect(Deck.full, hasLength(24));
    expect(Deck.full.toSet(), hasLength(24));
    expect(Deck.full.fold<int>(0, (sum, c) => sum + c.points), 120);
  });

  test('marriage values', () {
    expect(Suit.values.map((s) => s.marriageValue), [40, 60, 80, 100]);
  });

  test('id round-trips', () {
    for (final card in Deck.full) {
      expect(Card.fromId(card.id), card);
    }
  });

  test('ten beats king but loses to ace', () {
    expect(Rank.ten.strength, greaterThan(Rank.king.strength));
    expect(Rank.ace.strength, greaterThan(Rank.ten.strength));
  });
}

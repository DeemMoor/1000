import 'package:thousand_engine/thousand_engine.dart';
import 'package:test/test.dart';

List<Card> cards(String ids) => ids.split(' ').map(Card.fromId).toList();

void main() {
  const rules = GameRules();
  final noMarriage = cards('AH 10H AS');
  final heartsMarriage = cards('KH QH AS');

  Bidding auction({List<List<Card>>? hands, int dealer = 0}) => Bidding(
    rules: rules,
    hands: hands ?? [noMarriage, noMarriage, noMarriage],
    dealer: dealer,
  );

  test('player left of dealer opens with forced 100', () {
    final b = auction(dealer: 2);
    expect(b.highestBidder, 0);
    expect(b.highestBid, 100);
    expect(b.current, 1);
  });

  test('everyone passes: opener plays 100', () {
    final b = auction()
      ..pass(2)
      ..pass(0);
    expect(b.isOver, isTrue);
    expect(b.declarer, 1);
    expect(b.highestBid, 100);
  });

  test('passed players are skipped', () {
    final b = auction()
      ..bid(2, 105)
      ..pass(0)
      ..bid(1, 110);
    expect(b.current, 2);
    b.pass(2);
    expect(b.isOver, isTrue);
    expect(b.declarer, 1);
    expect(b.highestBid, 110);
  });

  test('bids must step by 5 and exceed the current one', () {
    final b = auction();
    expect(b.canBid(2, 100), isFalse);
    expect(b.canBid(2, 103), isFalse);
    expect(b.canBid(2, 105), isTrue);
    expect(b.canBid(0, 105), isFalse, reason: 'not their turn');
    expect(() => b.bid(2, 103), throwsA(isA<IllegalMoveException>()));
  });

  test('above 120 only with a marriage, up to its value', () {
    final b = auction(hands: [noMarriage, noMarriage, heartsMarriage]);
    expect(b.maxBidFor(0), 120);
    expect(b.maxBidFor(2), 220);
    expect(b.canBid(2, 220), isTrue);
    expect(b.canBid(2, 225), isFalse);
    b.bid(2, 125);
    expect(b.canBid(0, 130), isFalse);
  });
}

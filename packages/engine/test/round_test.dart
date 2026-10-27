import 'dart:math';

import 'package:thousand_engine/thousand_engine.dart';
import 'package:test/test.dart';

Card c(String id) => Card.fromId(id);
List<Card> cards(String ids) => ids.split(' ').map(Card.fromId).toList();

/// P0 holds the hearts marriage; prikup is QC JC 9C.
Deal fixedDeal() => Deal([
  cards('KH QH AH 10H AS 10S AD'),
  cards('KS QS JH 9H JS 9S 10D'),
  cards('KD QD JD 9D AC 10C KC'),
], cards('QC JC 9C'));

/// Dealer 2, so P0 opens with 100 and the others pass.
Round wonByP0() => Round(rules: const GameRules(), dealer: 2, deal: fixedDeal())
  ..pass(1)
  ..pass(2);

void main() {
  test('declarer takes the prikup and gives a card to each opponent', () {
    final r = wonByP0();
    expect(r.phase, RoundPhase.exchange);
    expect(r.declarer, 0);
    expect(r.hands[0], hasLength(10));

    r.giveCards(0, toNext: c('9C'), toPrev: c('JC'));
    expect(r.phase, RoundPhase.declaring);
    expect(r.hands.map((h) => h.length), [8, 8, 8]);
    expect(r.hands[1], contains(c('9C')));
    expect(r.hands[2], contains(c('JC')));
  });

  test('raise is capped by marriages in hand', () {
    final r = wonByP0()..giveCards(0, toNext: c('9C'), toPrev: c('JC'));
    expect(r.maxRaise, 220);
    expect(r.canRaiseTo(95), isFalse);
    expect(r.canRaiseTo(225), isFalse);
    r.startPlay(0, raiseTo: 120);
    expect(r.contract, 120);
    expect(r.auctionBid, 100);
  });

  test('concession: declarer loses auction bid, opponents get half', () {
    final r = Round(rules: const GameRules(), dealer: 2, deal: fixedDeal())
      ..pass(1)
      ..bid(2, 105)
      ..pass(0);
    expect(r.declarer, 2);
    r.concede(2);
    expect(r.phase, RoundPhase.finished);
    expect(r.result!.scores, [50, 50, -105]);
    expect(r.result!.isBolt(0), isFalse);
  });

  group('play', () {
    late Round r;
    setUp(() {
      r = wonByP0()
        ..giveCards(0, toNext: c('9C'), toPrev: c('JC'))
        ..startPlay(0, raiseTo: 120);
    });

    test('cannot declare a marriage before taking a trick', () {
      expect(r.canDeclareWith(0, c('KH')), isFalse);
      expect(
        () => r.play(0, c('KH'), declare: true),
        throwsA(isA<IllegalMoveException>()),
      );
    });

    test('must follow suit, highest card of led suit wins', () {
      r.play(0, c('AS'));
      expect(r.legalCards(1).every((card) => card.suit == Suit.spades), isTrue);
      expect(() => r.play(1, c('10D')), throwsA(isA<IllegalMoveException>()));
      r
        ..play(1, c('9S'))
        ..play(2, c('9D'));
      expect(r.lastTrickWinner, 0);
      expect(r.current, 0);
    });

    test('marriage sets trump, players out of suit must trump', () {
      r
        ..play(0, c('AS'))
        ..play(1, c('9S'))
        ..play(2, c('9D'));
      expect(r.canDeclareWith(0, c('QH')), isTrue);
      r.play(0, c('KH'), declare: true);
      expect(r.trump, Suit.hearts);
      expect(r.declared[0], 100);

      r.play(1, c('JH'));
      // P2 has no hearts and no trumps: anything goes.
      expect(r.legalCards(2), hasLength(r.hands[2].length));
      r.play(2, c('KD'));
      expect(r.lastTrickWinner, 0);

      // Lead diamonds: P1 follows with 10D.
      r.play(0, c('AD'));
      expect(r.legalCards(1), [c('10D')]);
    });

    test('out of suit must trump, trump beats the led ace', () {
      r
        ..play(0, c('AS'))
        ..play(1, c('9S'))
        ..play(2, c('9D'))
        ..play(0, c('KH'), declare: true)
        ..play(1, c('JH'))
        ..play(2, c('KD'))
        ..play(0, c('QC'))
        ..play(1, c('9C'))
        ..play(2, c('AC'));
      expect(r.lastTrickWinner, 2);

      // Clubs led; P0 and P1 are out of clubs and must trump.
      r.play(2, c('10C'));
      expect(r.legalCards(0).map((card) => card.suit).toSet(), {Suit.hearts});
      r.play(0, c('QH'));
      expect(r.legalCards(1), [c('9H')]);
      r.play(1, c('9H'));
      expect(r.lastTrickWinner, 0);
    });
  });

  test('random rounds: all 120 card points distributed, scores consistent', () {
    final random = Random(42);
    for (var i = 0; i < 1000; i++) {
      final r = Round(
        rules: const GameRules(aceMarriage: true),
        dealer: i % 3,
        deal: Deal.random(random),
      );
      while (r.phase == RoundPhase.bidding) {
        final p = r.current;
        final next = r.bidding.minNextBid;
        if (random.nextBool() && r.bidding.canBid(p, next)) {
          r.bid(p, next);
        } else {
          r.pass(p);
        }
      }
      final hand = r.hands[r.declarer];
      r.giveCards(r.declarer, toNext: hand[0], toPrev: hand[1]);
      r.startPlay(r.declarer);
      while (r.phase == RoundPhase.playing) {
        final p = r.current;
        final options = r.legalCards(p);
        final card = options[random.nextInt(options.length)];
        r.play(p, card, declare: r.canDeclareWith(p, card));
      }
      final res = r.result!;
      expect(r.taken.expand((t) => t).points, 120);
      expect(res.tricks.reduce((a, b) => a + b), 8);
      expect(res.scores[r.declarer], res.made ? r.contract : -r.contract);
      for (var p = 0; p < 3; p++) {
        if (p != r.declarer) expect(res.scores[p] % 5, 0);
      }
    }
  });
}

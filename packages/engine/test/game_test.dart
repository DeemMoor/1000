import 'dart:math';

import 'package:thousand_engine/thousand_engine.dart';
import 'package:test/test.dart';

Card c(String id) => Card.fromId(id);
List<Card> cards(String ids) => ids.split(' ').map(Card.fromId).toList();

/// P0 holds the hearts marriage and strong cards.
Deal fixedDeal() => Deal([
  cards('KH QH AH 10H AS 10S AD'),
  cards('KS QS JH 9H JS 9S 10D'),
  cards('KD QD JD 9D AC 10C KC'),
], cards('QC JC 9C'));

/// Puts a fixed round in place with dealer 2, so P0 opens.
Round fixedRound(Game g) =>
    g.round = Round(rules: g.rules, dealer: 2, deal: fixedDeal());

/// P0 wins the auction at 100; P1 then concedes nothing, P0 concedes.
void concedeByP0(Game g) {
  fixedRound(g)
    ..pass(1)
    ..pass(2)
    ..concede(0);
}

/// Plays a full round by always choosing the first legal card.
void playOut(Round r) {
  while (r.phase == RoundPhase.playing) {
    final p = r.current;
    final card = r.legalCards(p).first;
    r.play(p, card, declare: r.canDeclareWith(p, card));
  }
}

void main() {
  test('dealer rotates and history grows', () {
    final g = Game(random: Random(1));
    concedeByP0(g);
    final rec = g.completeRound();
    expect(rec.deltas, [-100, 50, 50]);
    expect(g.scores, [-100, 50, 50]);
    expect(g.dealer, 1);
    expect(g.history, hasLength(1));
  });

  test('third concession costs an extra 120', () {
    final g = Game(random: Random(1));
    for (var i = 0; i < 3; i++) {
      concedeByP0(g);
      g.completeRound();
    }
    expect(g.scores[0], -300 - 120);
    expect(g.history.last.events[0], contains(ScoreEvent.concessionPenalty));
    expect(g.concessions[0], 0);
  });

  test('landing exactly on 555 resets to zero', () {
    final g = Game(random: Random(1));
    g.scores[1] = 505;
    concedeByP0(g);
    final rec = g.completeRound();
    expect(g.scores[1], 0);
    expect(rec.events[1], contains(ScoreEvent.pit));
  });

  test('crossing 880 puts a player on the barrel at exactly 880', () {
    final g = Game(random: Random(1));
    g.scores[1] = 860;
    concedeByP0(g);
    final rec = g.completeRound();
    expect(g.scores[1], 880);
    expect(g.onBarrel(1), isTrue);
    expect(rec.events[1], contains(ScoreEvent.barrelOn));
  });

  test('cannot jump over the barrel straight to 1000', () {
    final g = Game(random: Random(1));
    g.scores[1] = 960;
    concedeByP0(g);
    g.completeRound();
    expect(g.isOver, isFalse);
    expect(g.scores[1], 880);
  });

  test('on the barrel: no points as defender, penalty after 3 rounds', () {
    final g = Game(random: Random(1));
    g.scores[1] = 880;
    g.barrel[1] = 0;
    for (var i = 0; i < 2; i++) {
      concedeByP0(g);
      g.completeRound();
      expect(g.scores[1], 880);
    }
    concedeByP0(g);
    final rec = g.completeRound();
    expect(g.scores[1], 760);
    expect(g.onBarrel(1), isFalse);
    expect(rec.events[1], contains(ScoreEvent.barrelPenalty));
  });

  test('making the bid from the barrel wins the game', () {
    final g = Game(random: Random(1));
    g.scores[0] = 880;
    g.barrel[0] = 1;
    final r = fixedRound(g)
      ..pass(1)
      ..pass(2)
      ..giveCards(0, toNext: c('9C'), toPrev: c('JC'))
      ..startPlay(0, raiseTo: 120);
    playOut(r);
    expect(r.result!.made, isTrue);
    g.completeRound();
    expect(g.isOver, isTrue);
    expect(g.winner, 0);
    expect(() => g.completeRound(), throwsA(isA<IllegalMoveException>()));
  });

  test('failing the bid on the barrel drops the player off', () {
    final g = Game(random: Random(1));
    g.scores[2] = 880;
    g.barrel[2] = 0;
    final r = fixedRound(g)
      ..pass(1)
      ..bid(2, 105)
      ..pass(0)
      ..giveCards(2, toNext: c('KC'), toPrev: c('AC'))
      ..startPlay(2, raiseTo: 120);
    playOut(r);
    expect(r.result!.made, isFalse);
    final rec = g.completeRound();
    expect(g.scores[2], 760);
    expect(g.onBarrel(2), isFalse);
    expect(rec.events[2], contains(ScoreEvent.barrelFailed));
  });

  test('random games keep score invariants', () {
    final random = Random(7);
    for (var i = 0; i < 100; i++) {
      final g = Game(random: random, firstDealer: i % 3);
      var rounds = 0;
      while (!g.isOver && rounds++ < 300) {
        final r = g.round;
        while (r.phase == RoundPhase.bidding) {
          final p = r.current;
          if (random.nextInt(3) == 0 &&
              r.bidding.canBid(p, r.bidding.minNextBid)) {
            r.bid(p, r.bidding.minNextBid);
          } else {
            r.pass(p);
          }
        }
        final hand = r.hands[r.declarer];
        r.giveCards(r.declarer, toNext: hand[0], toPrev: hand[1]);
        r.startPlay(r.declarer);
        playOut(r);
        g.completeRound();
        for (var p = 0; p < 3; p++) {
          if (p != g.winner) expect(g.scores[p], lessThanOrEqualTo(880));
          expect(g.scores[p], isNot(555));
          if (g.onBarrel(p)) expect(g.scores[p], 880);
        }
      }
      if (g.isOver) expect(g.scores[g.winner!], greaterThanOrEqualTo(1000));
    }
  });
}

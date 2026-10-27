import 'dart:math';

import 'card.dart';
import 'deal.dart';
import 'hand.dart';
import 'round.dart';

/// Heuristic computer player.
///
/// It only looks at what a real player at seat [me] could see: its own hand,
/// the prikup once revealed, and cards already played. [Round] exposes every
/// hand, so this discipline is on the bot, not enforced by the type system.
class Bot {
  Bot({Random? random, this.samples = 40}) : _random = random ?? Random();

  final Random _random;

  /// Simulated playouts per bidding or contract decision.
  final int samples;

  /// Required chance of making a bid during the auction.
  static const bidConfidence = 0.6;

  /// Auction limit per seat, computed once per round.
  static final _bidLimits = Expando<Map<int, int>>();

  /// Makes one move for [me] if the round is waiting on them.
  /// Returns false when it's not their turn.
  bool act(Round r, int me) {
    switch (r.phase) {
      case RoundPhase.bidding:
        if (r.current != me) return false;
        final amount = chooseBid(r, me);
        amount == null ? r.pass(me) : r.bid(me, amount);
      case RoundPhase.exchange:
        if (r.declarer != me) return false;
        final (toNext, toPrev) = chooseExchange(r, me);
        r.giveCards(me, toNext: toNext, toPrev: toPrev);
      case RoundPhase.declaring:
        if (r.declarer != me) return false;
        final raiseTo = chooseContract(r, me);
        raiseTo == null ? r.concede(me) : r.startPlay(me, raiseTo: raiseTo);
      case RoundPhase.playing:
        if (r.current != me) return false;
        final (card, declare) = choosePlay(r, me);
        r.play(me, card, declare: declare);
      case RoundPhase.finished:
        return false;
    }
    return true;
  }

  // --- Simulation ---

  /// Outcomes of [samples] random layouts of the cards [me] can't see,
  /// played out with this bot's own heuristics: declarer points and the
  /// opponents' combined points. Sorted by declarer points.
  ///
  /// [hand] is what [me] holds now; [given] the cards already passed to
  /// next and previous players (declaring phase), or null before the prikup.
  List<(int, int)> _simulate(
    Round r,
    int me,
    List<Card> hand,
    (Card, Card)? given,
  ) {
    final unknown = Deck.full.toSet()
      ..removeAll(hand)
      ..removeAll(given == null ? const [] : [given.$1, given.$2]);
    final next = nextPlayer(me);
    final prev = nextPlayer(next);
    final results = <(int, int)>[];
    for (var i = 0; i < samples; i++) {
      final rest = unknown.toList()..shuffle(_random);
      final hands = List<List<Card>>.filled(playerCount, const []);
      final List<Card> prikup;
      if (given == null) {
        hands[me] = hand;
        prikup = rest.sublist(14);
      } else {
        // Rebuild an equivalent deal: the prikup brings our 8th card back
        // along with the two we gave away.
        hands[me] = hand.sublist(0, 7);
        prikup = [hand[7], given.$1, given.$2];
      }
      hands[next] = rest.sublist(0, 7);
      hands[prev] = rest.sublist(7, 14);

      final sim = Round(rules: r.rules, dealer: prev, deal: Deal(hands, prikup))
        ..pass(next)
        ..pass(prev);
      final (toNext, toPrev) = given ?? chooseExchange(sim, me);
      sim
        ..giveCards(me, toNext: toNext, toPrev: toPrev)
        ..startPlay(me);
      while (sim.phase == RoundPhase.playing) {
        final p = sim.current;
        final (card, declare) = choosePlay(sim, p);
        sim.play(p, card, declare: declare);
      }
      final points = sim.result!.points;
      results.add((points[me], points[next] + points[prev]));
    }
    return results..sort((a, b) => a.$1.compareTo(b.$1));
  }

  /// Highest declarer score reached in at least [confidence] of outcomes.
  int _quantile(List<(int, int)> sorted, double confidence) =>
      sorted[((1 - confidence) * sorted.length).floor()].$1;

  int _floorToStep(int value, int step) => value ~/ step * step;

  // --- Bidding ---

  int? chooseBid(Round r, int me) {
    final limits = _bidLimits[r] ??= {};
    final limit = limits[me] ??= _floorToStep(
      _quantile(_simulate(r, me, r.hands[me], null), bidConfidence),
      r.rules.bidStep,
    );
    final next = r.bidding.minNextBid;
    return next <= limit && r.bidding.canBid(me, next) ? next : null;
  }

  // --- Prikup ---

  /// How much we want to keep a card; the two lowest are given away.
  int _keepValue(Card card, List<Card> hand) {
    final suit = hand.where((c) => c.suit == card.suit).length;
    var value = card.points * 2;
    if (card.rank == Rank.ace) value += 30;
    if (card.rank == Rank.ten && hand.contains(Card(card.suit, Rank.ace))) {
      value += 25;
    }
    if ((card.rank == Rank.king || card.rank == Rank.queen) &&
        hand.marriages.contains(card.suit)) {
      value += 100;
    }
    // Prefer emptying short suits: a void lets us trump later.
    return value + suit;
  }

  (Card, Card) chooseExchange(Round r, int me) {
    final hand = r.hands[me];
    final sorted = List.of(hand)
      ..sort((a, b) => _keepValue(a, hand).compareTo(_keepValue(b, hand)));
    return (sorted[0], sorted[1]);
  }

  /// Raise target, or null to concede.
  ///
  /// Picks whatever maximizes the expected lead over an average opponent:
  /// playing for each reachable contract, or conceding.
  int? chooseContract(Round r, int me) {
    final outcomes = _simulate(r, me, r.hands[me], (
      r.gaveToNext!,
      r.gaveToPrev!,
    ));
    final opponents =
        outcomes.fold(0, (sum, o) => sum + o.$2) / outcomes.length / 2;

    int? best;
    var bestValue =
        (-r.auctionBid - r.rules.concessionOpponentPoints(r.auctionBid))
            .toDouble();
    for (var c = r.contract; c <= r.maxRaise; c += r.rules.bidStep) {
      final made = outcomes.where((o) => o.$1 >= c).length / outcomes.length;
      final value = made * c - (1 - made) * c - opponents;
      if (value > bestValue) {
        best = c;
        bestValue = value;
      }
    }
    return best;
  }

  // --- Play ---

  /// Cards not in [me]'s hand and not yet played.
  Set<Card> _unseen(Round r, int me) => {...Deck.full}
    ..removeAll([
      ...r.hands[me],
      ...r.taken.expand((t) => t),
      ...r.trick.map((p) => p.card),
    ]);

  /// No unseen card of the same suit outranks [card].
  bool _isMaster(Card card, Set<Card> unseen) => !unseen.any(
    (c) => c.suit == card.suit && c.rank.strength > card.rank.strength,
  );

  bool _beats(Card a, Card b, Suit? trump) {
    if (a.suit == b.suit) return a.rank.strength > b.rank.strength;
    return a.suit == trump;
  }

  Card _cheapest(Iterable<Card> cards) => cards.reduce(
    (a, b) =>
        a.points < b.points ||
            (a.points == b.points && a.rank.strength <= b.rank.strength)
        ? a
        : b,
  );

  (Card, bool) choosePlay(Round r, int me) {
    final legal = r.legalCards(me);
    final unseen = _unseen(r, me);

    if (r.trick.isEmpty) return _lead(r, me, legal, unseen);

    var best = r.trick.first.card;
    for (final p in r.trick.skip(1)) {
      if (_beats(p.card, best, r.trump)) best = p.card;
    }
    final winners = legal.where((c) => _beats(c, best, r.trump)).toList()
      ..sort((a, b) => a.rank.strength.compareTo(b.rank.strength));

    final last = r.trick.length == playerCount - 1;
    if (winners.isNotEmpty) {
      // Last to play: any winner is safe. Otherwise only a card nobody
      // behind us can beat in suit (they may still trump; accept that).
      final safe = last
          ? winners
          : winners.where((c) => c.suit == r.trump || _isMaster(c, unseen));
      if (safe.isNotEmpty) return (safe.first, false);
    }
    return (_cheapest(legal), false);
  }

  (Card, bool) _lead(Round r, int me, List<Card> legal, Set<Card> unseen) {
    // Declare the most valuable marriage we can.
    final declarable = legal.where((c) => r.canDeclareWith(me, c)).toList()
      ..sort((a, b) => _declareValue(b, r).compareTo(_declareValue(a, r)));
    if (declarable.isNotEmpty) {
      final suit = declarable.first.suit;
      final rank = declarable.first.rank;
      // Lead the queen: it risks fewer points than the king.
      return (
        rank == Rank.ace ? declarable.first : Card(suit, Rank.queen),
        true,
      );
    }

    // Cash a master card, preferring trumps to pull them out, then points.
    final masters = legal.where((c) => _isMaster(c, unseen)).toList()
      ..sort((a, b) {
        final t = (b.suit == r.trump ? 1 : 0) - (a.suit == r.trump ? 1 : 0);
        return t != 0 ? t : b.points.compareTo(a.points);
      });
    if (masters.isNotEmpty) return (masters.first, false);

    // Otherwise give away as little as possible, keeping marriages intact.
    final hand = r.hands[me];
    final safe = legal.where(
      (c) =>
          !((c.rank == Rank.king || c.rank == Rank.queen) &&
              hand.marriages.contains(c.suit)),
    );
    return (_cheapest(safe.isEmpty ? legal : safe), false);
  }

  int _declareValue(Card c, Round r) =>
      c.rank == Rank.ace ? r.rules.aceMarriageValue : c.suit.marriageValue;
}

import 'bidding.dart';
import 'card.dart';
import 'deal.dart';
import 'hand.dart';
import 'rules.dart';

enum RoundPhase {
  /// Auction is running.
  bidding,

  /// Declarer has taken the prikup and must give one card to each opponent.
  exchange,

  /// Declarer may raise the bid and start, or concede.
  declaring,

  /// Tricks are being played.
  playing,

  finished,
}

class PlayedCard {
  const PlayedCard(this.player, this.card);

  final int player;
  final Card card;
}

class RoundResult {
  const RoundResult({
    required this.declarer,
    required this.bid,
    required this.conceded,
    required this.points,
    required this.tricks,
    required this.scores,
  });

  final int declarer;

  /// Final bid (after any raise); the auction bid if conceded.
  final int bid;
  final bool conceded;

  /// Raw points per player: cards taken plus declared marriages.
  final List<int> points;

  /// Tricks taken per player.
  final List<int> tricks;

  /// Score change per player for this round, before game-level rules
  /// (barrel, bolts, pit) are applied.
  final List<int> scores;

  bool get made => !conceded && points[declarer] >= bid;

  /// A player who took no tricks gets a bolt (conceded rounds have no play).
  bool isBolt(int player) => !conceded && tricks[player] == 0;
}

/// One round ("кон"): auction, prikup, play and scoring.
class Round {
  Round({required this.rules, required this.dealer, required Deal deal})
    : hands = [for (final h in deal.hands) List.of(h)],
      prikup = List.unmodifiable(deal.prikup) {
    bidding = Bidding(rules: rules, hands: hands, dealer: dealer);
  }

  final GameRules rules;
  final int dealer;

  /// Current cards in hand. Treat as read-only outside the engine.
  final List<List<Card>> hands;

  /// Visible to everyone once the auction is over.
  final List<Card> prikup;

  late final Bidding bidding;

  RoundPhase phase = RoundPhase.bidding;

  int get declarer => bidding.declarer;

  /// Bid won at auction; concession is scored from this.
  int get auctionBid => _auctionBid ?? bidding.highestBid;
  int? _auctionBid;

  /// Current contract: the auction bid, possibly raised after the prikup.
  int get contract => _contract ?? bidding.highestBid;
  int? _contract;

  bool _conceded = false;

  /// Cards the declarer passed on; only the declarer knows both.
  Card? gaveToNext;
  Card? gaveToPrev;

  Suit? trump;

  /// Cards on the table in the current trick, in play order.
  final List<PlayedCard> trick = [];

  /// The last completed trick, kept so the UI can show it.
  List<PlayedCard> lastTrick = const [];
  int? lastTrickWinner;

  /// Whose turn it is during bidding or playing.
  int get current => phase == RoundPhase.bidding ? bidding.current : _current;
  late int _current;

  final List<List<Card>> taken = [[], [], []];
  final List<int> tricks = [0, 0, 0];
  final List<int> declared = [0, 0, 0];

  RoundResult? result;

  // --- Bidding ---

  void bid(int player, int amount) {
    _require(RoundPhase.bidding);
    bidding.bid(player, amount);
    _afterBidding();
  }

  void pass(int player) {
    _require(RoundPhase.bidding);
    bidding.pass(player);
    _afterBidding();
  }

  void _afterBidding() {
    if (!bidding.isOver) return;
    _auctionBid = bidding.highestBid;
    hands[declarer].addAll(prikup);
    phase = RoundPhase.exchange;
  }

  // --- Prikup ---

  void giveCards(int player, {required Card toNext, required Card toPrev}) {
    _require(RoundPhase.exchange);
    final hand = hands[declarer];
    if (player != declarer ||
        toNext == toPrev ||
        !hand.contains(toNext) ||
        !hand.contains(toPrev)) {
      throw IllegalMoveException('invalid exchange by player $player');
    }
    hand
      ..remove(toNext)
      ..remove(toPrev);
    gaveToNext = toNext;
    gaveToPrev = toPrev;
    hands[nextPlayer(declarer)].add(toNext);
    hands[nextPlayer(nextPlayer(declarer))].add(toPrev);
    phase = RoundPhase.declaring;
  }

  /// Highest contract the declarer may raise to with the current hand.
  int get maxRaise =>
      rules.maxBidWithoutMarriage + hands[declarer].marriageValue(rules);

  bool canRaiseTo(int amount) =>
      amount >= contract &&
      amount <= maxRaise &&
      (amount - rules.minBid) % rules.bidStep == 0;

  /// Starts play, optionally raising the contract.
  void startPlay(int player, {int? raiseTo}) {
    _require(RoundPhase.declaring);
    if (player != declarer) {
      throw IllegalMoveException('only the declarer starts play');
    }
    if (raiseTo != null) {
      if (!canRaiseTo(raiseTo)) {
        throw IllegalMoveException('cannot raise to $raiseTo');
      }
      _contract = raiseTo;
    }
    _current = declarer;
    phase = RoundPhase.playing;
  }

  /// "Роспись": allowed once the prikup is seen, before play starts.
  void concede(int player) {
    if (phase != RoundPhase.exchange && phase != RoundPhase.declaring) {
      throw IllegalMoveException('cannot concede now');
    }
    if (player != declarer) {
      throw IllegalMoveException('only the declarer can concede');
    }
    _conceded = true;
    _contract = auctionBid;
    _finish();
  }

  // --- Play ---

  Suit? get ledSuit => trick.isEmpty ? null : trick.first.card.suit;

  /// Follow suit; otherwise trump; otherwise anything.
  List<Card> legalCards(int player) {
    final hand = hands[player];
    final led = ledSuit;
    if (led == null) return List.of(hand);
    final following = hand.where((c) => c.suit == led).toList();
    if (following.isNotEmpty) return following;
    final trumps = hand.where((c) => c.suit == trump).toList();
    if (trumps.isNotEmpty) return trumps;
    return List.of(hand);
  }

  /// Whether leading [card] would declare a marriage (or ace marriage).
  bool canDeclareWith(int player, Card card) {
    if (phase != RoundPhase.playing ||
        player != _current ||
        trick.isNotEmpty ||
        tricks[player] == 0) {
      return false;
    }
    final hand = hands[player];
    if (!hand.contains(card)) return false;
    return switch (card.rank) {
      Rank.king || Rank.queen => hand.marriages.contains(card.suit),
      Rank.ace => rules.aceMarriage && hand.hasFourAces,
      _ => false,
    };
  }

  void play(int player, Card card, {bool declare = false}) {
    _require(RoundPhase.playing);
    if (player != _current) {
      throw IllegalMoveException('not player $player turn');
    }
    if (!legalCards(player).contains(card)) {
      throw IllegalMoveException('player $player cannot play $card');
    }
    if (declare) {
      if (!canDeclareWith(player, card)) {
        throw IllegalMoveException('player $player cannot declare with $card');
      }
      if (card.rank == Rank.ace) {
        declared[player] += rules.aceMarriageValue;
      } else {
        declared[player] += card.suit.marriageValue;
        trump = card.suit;
      }
    }

    hands[player].remove(card);
    trick.add(PlayedCard(player, card));

    if (trick.length < playerCount) {
      _current = nextPlayer(player);
      return;
    }

    final winner = _trickWinner();
    taken[winner].addAll(trick.map((p) => p.card));
    tricks[winner]++;
    lastTrick = List.unmodifiable(trick);
    lastTrickWinner = winner;
    trick.clear();
    _current = winner;

    if (hands.every((h) => h.isEmpty)) _finish();
  }

  int _trickWinner() {
    var best = trick.first;
    for (final p in trick.skip(1)) {
      if (_beats(p.card, best.card)) best = p;
    }
    return best.player;
  }

  bool _beats(Card a, Card b) {
    if (a.suit == b.suit) return a.rank.strength > b.rank.strength;
    return a.suit == trump;
  }

  // --- Scoring ---

  int _roundPoints(int points) =>
      (points + rules.roundTo ~/ 2) ~/ rules.roundTo * rules.roundTo;

  void _finish() {
    final points = [
      for (var p = 0; p < playerCount; p++) taken[p].points + declared[p],
    ];
    final List<int> scores;
    if (_conceded) {
      final share = rules.concessionOpponentPoints(auctionBid);
      scores = [
        for (var p = 0; p < playerCount; p++)
          p == declarer ? -auctionBid : share,
      ];
    } else {
      final made = points[declarer] >= contract;
      scores = [
        for (var p = 0; p < playerCount; p++)
          p == declarer
              ? (made ? contract : -contract)
              : _roundPoints(points[p]),
      ];
    }
    result = RoundResult(
      declarer: declarer,
      bid: contract,
      conceded: _conceded,
      points: points,
      tricks: List.unmodifiable(tricks),
      scores: scores,
    );
    phase = RoundPhase.finished;
  }

  void _require(RoundPhase expected) {
    if (phase != expected) {
      throw IllegalMoveException('expected $expected, but phase is $phase');
    }
  }
}

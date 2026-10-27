import 'card.dart';
import 'deal.dart';
import 'hand.dart';
import 'rules.dart';

class IllegalMoveException implements Exception {
  IllegalMoveException(this.message);

  final String message;

  @override
  String toString() => 'IllegalMoveException: $message';
}

/// Auction ("торговля"). The player left of the dealer opens with a forced
/// [GameRules.minBid]; the rest raise by [GameRules.bidStep] or pass for good.
class Bidding {
  Bidding({
    required this.rules,
    required this._hands,
    required int dealer,
  }) : highestBidder = nextPlayer(dealer),
       highestBid = rules.minBid {
    current = nextPlayer(highestBidder);
  }

  final GameRules rules;
  final List<List<Card>> _hands;
  final Set<int> _passed = {};

  int highestBid;
  int highestBidder;

  /// Whose turn it is. Meaningless once [isOver].
  late int current;

  bool get isOver => _passed.length == playerCount - 1;

  /// Winner of the auction; valid once [isOver].
  int get declarer => highestBidder;

  bool hasPassed(int player) => _passed.contains(player);

  int get minNextBid => highestBid + rules.bidStep;

  /// Above [GameRules.maxBidWithoutMarriage] only by what the player's
  /// marriages can bring in.
  int maxBidFor(int player) =>
      rules.maxBidWithoutMarriage + _hands[player].marriageValue(rules);

  bool canBid(int player, int amount) =>
      !isOver &&
      player == current &&
      amount >= minNextBid &&
      amount <= maxBidFor(player) &&
      (amount - rules.minBid) % rules.bidStep == 0;

  void bid(int player, int amount) {
    if (!canBid(player, amount)) {
      throw IllegalMoveException('player $player cannot bid $amount');
    }
    highestBid = amount;
    highestBidder = player;
    _advance();
  }

  void pass(int player) {
    if (isOver || player != current) {
      throw IllegalMoveException('player $player cannot pass now');
    }
    _passed.add(player);
    _advance();
  }

  void _advance() {
    if (isOver) return;
    do {
      current = nextPlayer(current);
    } while (_passed.contains(current));
  }
}

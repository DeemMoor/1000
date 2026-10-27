import 'dart:math';

import 'bidding.dart';
import 'deal.dart';
import 'round.dart';
import 'rules.dart';

/// Notable things that happened to a player's score in a round.
enum ScoreEvent {
  bolt,
  boltPenalty,
  concessionPenalty,
  barrelOn,
  barrelFailed,
  barrelPenalty,
  pit,
}

class RoundRecord {
  const RoundRecord({
    required this.result,
    required this.deltas,
    required this.scores,
    required this.events,
  });

  final RoundResult result;

  /// Actual score change per player after game-level rules.
  final List<int> deltas;

  /// Scores after this round.
  final List<int> scores;

  final List<List<ScoreEvent>> events;
}

/// A whole match: rounds until someone reaches [GameRules.targetScore].
class Game {
  Game({this.rules = const GameRules(), Random? random, int firstDealer = 0})
    : _random = random ?? Random.secure(),
      dealer = firstDealer {
    round = _newRound();
  }

  final GameRules rules;
  final Random _random;

  final List<int> scores = [0, 0, 0];
  final List<int> bolts = [0, 0, 0];
  final List<int> concessions = [0, 0, 0];

  /// Rounds already spent on the barrel; null when not on it.
  final List<int?> barrel = [null, null, null];

  final List<RoundRecord> history = [];

  int dealer;
  late Round round;

  /// Why the current round had to be redealt, in order (usually empty).
  List<RedealReason> redeals = const [];

  int? winner;

  bool get isOver => winner != null;

  bool onBarrel(int player) => barrel[player] != null;

  Round _newRound() {
    final reasons = <RedealReason>[];
    while (true) {
      final deal = Deal.random(_random);
      final reason = deal.redealReason(rules);
      if (reason == null) {
        redeals = List.unmodifiable(reasons);
        return Round(rules: rules, dealer: dealer, deal: deal);
      }
      reasons.add(reason);
    }
  }

  /// Applies the finished round to the score sheet and deals the next one
  /// unless the game is over.
  RoundRecord completeRound() {
    final result = round.result;
    if (result == null || isOver) {
      throw IllegalMoveException('round is not finished');
    }

    final deltas = <int>[];
    final events = <List<ScoreEvent>>[];
    for (var p = 0; p < playerCount; p++) {
      final e = <ScoreEvent>[];
      final before = scores[p];
      var score = before + _baseDelta(p, result, e);

      if (result.isBolt(p)) {
        e.add(ScoreEvent.bolt);
        if (++bolts[p] >= rules.boltsForPenalty) {
          bolts[p] = 0;
          score -= rules.boltPenalty;
          e.add(ScoreEvent.boltPenalty);
        }
      }
      if (result.conceded && p == result.declarer) {
        if (++concessions[p] >= rules.concessionsForPenalty) {
          concessions[p] = 0;
          score -= rules.concessionPenalty;
          e.add(ScoreEvent.concessionPenalty);
        }
      }

      // Without a barrel rule anyone may finish; otherwise only from it.
      final canFinish = rules.barrelScore <= 0 || onBarrel(p);
      if (score >= rules.targetScore && canFinish) {
        winner ??= p;
        barrel[p] = null;
      } else if (rules.barrelScore > 0 && score >= rules.barrelScore) {
        if (!onBarrel(p)) {
          barrel[p] = 0;
          e.add(ScoreEvent.barrelOn);
        }
        score = rules.barrelScore;
      } else {
        barrel[p] = null;
      }

      if (rules.pitScore > 0 && score == rules.pitScore) {
        score = 0;
        e.add(ScoreEvent.pit);
      }

      scores[p] = score;
      deltas.add(score - before);
      events.add(e);
    }

    final record = RoundRecord(
      result: result,
      deltas: deltas,
      scores: List.unmodifiable(scores),
      events: events,
    );
    history.add(record);

    if (!isOver) {
      dealer = nextPlayer(dealer);
      round = _newRound();
    }
    return record;
  }

  /// Round score with barrel rules: a player on the barrel scores only as
  /// declarer, and gets [GameRules.barrelAttempts] rounds to make it.
  int _baseDelta(int p, RoundResult result, List<ScoreEvent> e) {
    final delta = result.scores[p];
    final attempts = barrel[p];
    if (attempts == null) return delta;

    if (p == result.declarer) {
      if (result.made) return delta;
      barrel[p] = null;
      e.add(ScoreEvent.barrelFailed);
      return delta;
    }
    if (attempts + 1 >= rules.barrelAttempts) {
      barrel[p] = null;
      e.add(ScoreEvent.barrelPenalty);
      return -rules.barrelPenalty;
    }
    barrel[p] = attempts + 1;
    return 0;
  }
}

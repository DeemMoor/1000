import 'dart:math';

import 'package:thousand_engine/thousand_engine.dart';
import 'package:test/test.dart';

/// Lets bots play every seat until the game ends or [maxRounds] pass.
Game playBotGame(Random random, {int maxRounds = 500, GameRules? rules}) {
  final bot = Bot(random: random);
  final g = Game(rules: rules ?? const GameRules(), random: random);
  var rounds = 0;
  while (!g.isOver && rounds++ < maxRounds) {
    final r = g.round;
    while (r.phase != RoundPhase.finished) {
      final acted = [0, 1, 2].any((p) => bot.act(r, p));
      expect(acted, isTrue, reason: 'nobody could move in ${r.phase}');
    }
    g.completeRound();
  }
  return g;
}

void main() {
  test('bot games finish with a winner', () {
    final random = Random(3);
    var made = 0, total = 0;
    for (var i = 0; i < 10; i++) {
      final g = playBotGame(random);
      expect(g.isOver, isTrue, reason: 'game $i stuck at ${g.scores}');
      for (final rec in g.history) {
        if (rec.result.conceded) continue;
        total++;
        if (rec.result.made) made++;
      }
    }
    // Sanity: bots should usually make what they bid.
    expect(made / total, greaterThan(0.5));
  });

  test('bots handle ace marriage rules', () {
    final g = playBotGame(Random(5), rules: const GameRules(aceMarriage: true));
    expect(g.isOver, isTrue);
  });
}

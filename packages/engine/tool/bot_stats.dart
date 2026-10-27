/// Plays bot-only games and prints how often each kind of contract is made.
/// Run: dart run tool/bot_stats.dart
library;
import 'dart:math';

import 'package:thousand_engine/thousand_engine.dart';

void main() {
  final random = Random(3);
  final bot = Bot(random: random);
  final stats = <String, List<int>>{};
  var rounds = 0;
  for (var i = 0; i < 20; i++) {
    final g = Game(random: random);
    while (!g.isOver) {
      final r = g.round;
      var voluntary = false;
      var raised = false;
      while (r.phase != RoundPhase.finished) {
        final before = r.bidding.highestBid;
        final ph = r.phase;
        final c0 = r.contract;
        [0, 1, 2].any((p) => bot.act(r, p));
        if (ph == RoundPhase.bidding && r.bidding.highestBid != before) {
          voluntary = true;
        }
        if (ph == RoundPhase.declaring && r.contract != c0) raised = true;
      }
      final res = r.result!;
      rounds++;
      final key = res.conceded
          ? 'conceded'
          : '${voluntary ? 'bid' : 'forced'}${raised ? '+raise' : ''}';
      final s = stats.putIfAbsent(key, () => [0, 0]);
      s[0]++;
      if (res.made) s[1]++;
      g.completeRound();
    }
  }
  print('rounds/game: ${rounds / 20}');
  stats.forEach(
    (k, v) => print(
      '$k: ${v[0]} rounds, made ${(100 * v[1] / v[0]).toStringAsFixed(0)}%',
    ),
  );
}

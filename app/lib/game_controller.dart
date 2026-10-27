import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:thousand_engine/thousand_engine.dart';

import 'labels.dart';

/// Runs a local game: the human sits at [human], bots take the other seats.
class GameController extends ChangeNotifier {
  GameController({this.rules = const GameRules(), this.human = 0}) {
    newGame();
  }

  final GameRules rules;
  final int human;
  final Bot _bot = Bot();

  static const botDelay = Duration(milliseconds: 700);
  static const trickPause = Duration(milliseconds: 1100);

  late Game game;

  /// The round on screen: the finished one until [nextRound], else current.
  Round get round => _finished ?? game.round;
  Round? _finished;

  final List<String> names = const ['Вы', 'Вася', 'Петя'];

  /// Genitive forms for "для …".
  final List<String> namesGenitive = const ['вас', 'Васи', 'Пети'];

  /// "Вы берёте" / "Вася берёт".
  String says(int seat, String you, String other) =>
      seat == human ? 'Вы $you' : '${names[seat]} $other';

  /// Last auction call per seat for the current round ("100", "Пас").
  final Map<int, String> bidCalls = {};

  /// Cards shown in the middle of the table. Lags behind [Round.trick] so a
  /// finished trick stays visible for a moment.
  List<PlayedCard> table = const [];

  /// Short line about the latest notable event.
  String? message;

  /// Result of the finished round on screen, awaiting [nextRound].
  RoundRecord? record;

  Timer? _timer;
  bool _pausing = false;

  bool get isHumanTurn =>
      !_pausing &&
      switch (round.phase) {
        RoundPhase.bidding || RoundPhase.playing => round.current == human,
        RoundPhase.exchange || RoundPhase.declaring => round.declarer == human,
        RoundPhase.finished => false,
      };

  void newGame() {
    _timer?.cancel();
    game = Game(rules: rules, firstDealer: Random().nextInt(3));
    _finished = null;
    record = null;
    _startRound();
  }

  void _startRound() {
    bidCalls
      ..clear()
      ..[round.bidding.highestBidder] = '${round.bidding.highestBid}';
    table = const [];
    message = game.redeals.isEmpty
        ? null
        : 'Пересдача: ${game.redeals.map(redealLabel).join(', ')}';
    _pausing = false;
    _step();
  }

  // --- Human actions ---

  void bid(int amount) => _humanMove(() => round.bid(human, amount));

  void pass() => _humanMove(() => round.pass(human));

  void giveCards(Card toNext, Card toPrev) =>
      _humanMove(() => round.giveCards(human, toNext: toNext, toPrev: toPrev));

  void startPlay(int contract) => _humanMove(
    () => round.startPlay(
      human,
      raiseTo: contract == round.contract ? null : contract,
    ),
  );

  void concede() => _humanMove(() => round.concede(human));

  void play(Card card, {bool declare = false}) =>
      _humanMove(() => round.play(human, card, declare: declare));

  /// Lets the bot make the human's current move (hint, autoplay, tests).
  void autoMove() {
    if (!isHumanTurn) return;
    _apply(human, () => _bot.act(round, human));
  }

  /// Moves on from the finished round's summary to the next deal.
  void nextRound() {
    if (record == null || game.isOver) return;
    _finished = null;
    record = null;
    _startRound();
  }

  void _humanMove(void Function() move) {
    if (!isHumanTurn) return;
    _apply(human, move);
  }

  // --- Turn loop ---

  void _apply(int seat, void Function() move) {
    final phase = round.phase;
    final bidBefore = round.bidding.highestBid;
    final contractBefore = round.contract;
    final trumpBefore = round.trump;
    final declaredBefore = round.declared[seat];

    move();

    switch (phase) {
      case RoundPhase.bidding:
        final raised = round.bidding.highestBid != bidBefore;
        bidCalls[seat] = raised ? '${round.bidding.highestBid}' : 'Пас';
        if (round.phase == RoundPhase.exchange) {
          message =
              '${says(round.declarer, 'берёте', 'берёт')} прикуп на ${round.contract}';
        }
      case RoundPhase.exchange:
        message = '${says(seat, 'раздаёте', 'раздаёт')} карты из прикупа';
      case RoundPhase.declaring:
        if (round.phase == RoundPhase.finished) {
          message = says(seat, 'расписываетесь', 'расписывается');
        } else if (round.contract != contractBefore) {
          message =
              '${says(seat, 'повышаете', 'повышает')} заказ до ${round.contract}';
        } else {
          message = '${says(seat, 'играете', 'играет')} на ${round.contract}';
        }
      case RoundPhase.playing:
        final gained = round.declared[seat] - declaredBefore;
        if (gained > 0) {
          message = round.trump != trumpBefore
              ? '${names[seat]}: марьяж ${round.trump!.symbol} +$gained'
              : '${names[seat]}: тузовый марьяж +$gained';
        }
      case RoundPhase.finished:
        break;
    }

    if (phase == RoundPhase.playing && round.trick.isEmpty) {
      // A trick just closed: keep it on the table for a moment.
      table = round.lastTrick;
      _pausing = true;
      notifyListeners();
      _timer = Timer(trickPause, () {
        _pausing = false;
        table = round.trick;
        _step();
      });
      return;
    }
    table = List.of(round.trick);
    _step();
  }

  void _step() {
    if (round.phase == RoundPhase.finished) {
      if (record == null) {
        _finished = game.round;
        record = game.completeRound();
      }
      notifyListeners();
      return;
    }
    notifyListeners();
    if (isHumanTurn) return;

    final seat = switch (round.phase) {
      RoundPhase.exchange || RoundPhase.declaring => round.declarer,
      _ => round.current,
    };
    _timer = Timer(botDelay, () => _apply(seat, () => _bot.act(round, seat)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

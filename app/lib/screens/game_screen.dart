import 'dart:math';

import 'package:flutter/material.dart' hide Card;
import 'package:thousand_engine/thousand_engine.dart';

import '../game_controller.dart';
import '../labels.dart';
import '../widgets/playing_card.dart';

const _felt = Color(0xFF1E7A2E);
const _feltEdge = Color(0xFF0E4A17);
const _gold = Color(0xFFF6C344);

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.controller});

  /// Defaults to a fresh local game against bots.
  final GameController? controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final controller = widget.controller ?? GameController();

  /// Cards picked during the prikup exchange: first goes to the left
  /// player (next), second to the right one.
  final List<Card> _give = [];

  /// Amount chosen in the bid / contract panel.
  int? _amount;

  @override
  void dispose() {
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  int get me => controller.human;
  int get left => nextPlayer(me);
  int get right => nextPlayer(left);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.round.phase != RoundPhase.exchange) _give.clear();
        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(colors: [_felt, _feltEdge], radius: 1.2),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, box) => _table(box.maxWidth, box.maxHeight),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _table(double w, double h) {
    final cardWidth = min(w / 9.5, h / 3.4).clamp(40.0, 120.0);
    final cardHeight = cardWidth * cardAspect;
    // The hand sinks partly below the screen edge, like cards held in hand.
    final handVisible = cardHeight * 0.72;
    final lift = cardHeight * 0.18;
    final aboveHand = handVisible + lift + 8;
    final backWidth = cardWidth * 0.5;
    final panel = _panel(w);

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: backWidth * cardAspect + 16,
          bottom: aboveHand,
          child: _centre(cardWidth),
        ),
        Positioned(top: 8, left: 12, child: _opponent(left, backWidth)),
        Positioned(top: 8, right: 12, child: _opponent(right, backWidth)),
        Positioned(top: 8, left: 0, right: 0, child: _roundInfo()),
        Positioned(
          left: 12,
          bottom: aboveHand,
          child: _scoreBlock(me, CrossAxisAlignment.start),
        ),
        Positioned(right: 12, bottom: aboveHand, child: _toolbar()),
        Positioned(
          left: 0,
          right: 0,
          bottom: aboveHand,
          child: Center(child: _status()),
        ),
        Positioned(
          left: 8,
          right: 8,
          bottom: handVisible - cardHeight,
          child: Center(child: _hand(cardWidth, w - 16, lift)),
        ),
        if (panel != null) Center(child: panel),
        if (controller.record != null)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black45,
              child: Center(
                child: SingleChildScrollView(child: _resultPanel()),
              ),
            ),
          ),
      ],
    );
  }

  // --- Players ---

  bool _isActive(int seat) {
    final r = controller.round;
    if (controller.record != null) return false;
    return switch (r.phase) {
      RoundPhase.bidding || RoundPhase.playing => r.current == seat,
      RoundPhase.exchange || RoundPhase.declaring => r.declarer == seat,
      RoundPhase.finished => false,
    };
  }

  /// Bid call during the auction, contract while declaring, tricks in play.
  String? _badge(int seat) {
    final r = controller.round;
    return switch (r.phase) {
      RoundPhase.bidding => controller.bidCalls[seat],
      RoundPhase.exchange ||
      RoundPhase.declaring => r.declarer == seat ? '${r.contract}' : null,
      RoundPhase.playing || RoundPhase.finished =>
        r.tricks[seat] == 0 ? null : 'взяток: ${r.tricks[seat]}',
    };
  }

  Widget _blackBox(String text, {double size = 20, Color? color}) => Container(
    padding: EdgeInsets.symmetric(horizontal: size * 0.4, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color ?? Colors.white,
        fontSize: size,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _opponent(int seat, double backWidth) {
    final isLeft = seat == left;
    final fan = CardFan(
      count: controller.round.hands[seat].length,
      cardWidth: backWidth,
      maxWidth: backWidth * 4.2,
      itemBuilder: (_, _) => CardBack(width: backWidth),
    );
    final badge = controller.round.phase == RoundPhase.bidding
        ? _badge(seat)
        : null;
    final row = [
      fan,
      const SizedBox(width: 10),
      if (badge != null) _blackBox(badge, size: backWidth * 0.5),
    ];
    final align = isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    return Column(
      crossAxisAlignment: align,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: isLeft ? row : row.reversed.toList(),
        ),
        const SizedBox(height: 6),
        _scoreBlock(seat, align),
      ],
    );
  }

  Widget _scoreBlock(int seat, CrossAxisAlignment align) {
    final game = controller.game;
    // Opponents show their auction call next to the card fan instead.
    final badge = seat != me && controller.round.phase == RoundPhase.bidding
        ? null
        : _badge(seat);
    final active = _isActive(seat);
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _blackBox('${game.scores[seat]}', size: 16),
            if (game.onBarrel(seat)) ...[
              const SizedBox(width: 4),
              _blackBox('бочка', size: 12, color: _gold),
            ],
            if (badge != null) ...[
              const SizedBox(width: 6),
              _blackBox(badge, size: 14, color: _gold),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          controller.names[seat],
          style: TextStyle(
            color: active ? _gold : Colors.white70,
            fontSize: 16,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _roundInfo() {
    final r = controller.round;
    final parts = [
      if (r.phase != RoundPhase.bidding)
        'Заказ: ${controller.names[r.declarer]} ${r.contract}',
      if (r.trump != null) 'Козырь ${r.trump!.symbol}',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Center(
      child: Text(
        parts.join('   '),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _toolbar() {
    Widget button(IconData icon, String tip, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.white24,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tip,
          color: Colors.white,
          icon: Icon(icon),
          onPressed: onTap,
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(Icons.list, 'Счёт', () => _showScores(context)),
        button(Icons.refresh, 'Новая игра', () => _confirmNewGame(context)),
        button(Icons.close, 'Выйти', () => Navigator.maybePop(context)),
      ],
    );
  }

  Widget _status() {
    final r = controller.round;
    String? text;
    var color = Colors.white70;
    if (controller.record != null || r.phase == RoundPhase.finished) {
      text = null;
    } else if (controller.isHumanTurn) {
      if (r.phase == RoundPhase.playing) {
        text = 'Ваш ход';
        color = _gold;
      } else if (r.phase == RoundPhase.exchange && _give.length < 2) {
        final to = controller.namesGenitive[_give.isEmpty ? left : right];
        text = 'Выберите карту для $to';
        color = _gold;
      }
    } else if (controller.table.length < playerCount) {
      final seat = switch (r.phase) {
        RoundPhase.exchange || RoundPhase.declaring => r.declarer,
        _ => r.current,
      };
      text = 'Ходит ${controller.names[seat]}…';
    }
    if (text == null) return const SizedBox.shrink();
    return Text(
      text,
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  // --- Table centre ---

  Widget _centre(double cardWidth) {
    final r = controller.round;
    final message = controller.message;
    final small = cardWidth * 0.85;
    return Stack(
      children: [
        if (r.phase == RoundPhase.bidding)
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.all(3),
                    child: CardBack(width: small),
                  ),
              ],
            ),
          ),
        if (r.phase == RoundPhase.exchange || r.phase == RoundPhase.declaring)
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final card in r.prikup)
                  Padding(
                    padding: const EdgeInsets.all(3),
                    child: PlayingCard(card, width: small),
                  ),
              ],
            ),
          ),
        for (final played in controller.table)
          Align(
            alignment: played.player == me
                ? const Alignment(0, 0.9)
                : played.player == left
                ? const Alignment(-0.3, -0.6)
                : const Alignment(0.3, -0.6),
            child: PlayingCard(played.card, width: cardWidth),
          ),
        if (message != null)
          Align(
            alignment: Alignment.topCenter,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _gold, fontSize: 15),
            ),
          ),
      ],
    );
  }

  // --- Panels: auction, contract, exchange ---

  Widget? _panel(double screenWidth) {
    if (!controller.isHumanTurn || controller.record != null) return null;
    final r = controller.round;
    return switch (r.phase) {
      RoundPhase.bidding => _biddingPanel(r, screenWidth),
      RoundPhase.declaring => _contractPanel(r, screenWidth),
      RoundPhase.exchange when _give.length == 2 => _exchangePanel(screenWidth),
      _ => null,
    };
  }

  Widget _dialogFrame({
    required double screenWidth,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: min(440, screenWidth - 24),
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 16)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFFE8E8E8),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            color: const Color(0xFF4A4A4A),
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ],
      ),
    );
  }

  Widget _goldButton(String label, VoidCallback? onPressed) => FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: _gold,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.white24,
      minimumSize: const Size(120, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    ),
    onPressed: onPressed,
    child: Text(label),
  );

  Widget _stepButton(String label, VoidCallback? onPressed) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: SizedBox(
      width: 48,
      height: 44,
      child: FilledButton(
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          disabledBackgroundColor: Colors.white38,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    ),
  );

  /// « − amount + » where « and » jump to the limits.
  Widget _stepper(int amount, int low, int high, int step) {
    void set(int v) => setState(() => _amount = v);
    return FittedBox(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepButton('«', amount > low ? () => set(low) : null),
          _stepButton('−', amount > low ? () => set(amount - step) : null),
          SizedBox(
            width: 96,
            child: Text(
              '$amount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _stepButton('+', amount < high ? () => set(amount + step) : null),
          _stepButton('»', amount < high ? () => set(high) : null),
        ],
      ),
    );
  }

  Widget _buttons(List<Widget> buttons) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: buttons,
    ),
  );

  Widget _biddingPanel(Round r, double screenWidth) {
    final b = r.bidding;
    final low = b.minNextBid;
    final high = b.maxBidFor(me);
    final canBid = low <= high;
    final amount = (_amount ?? low).clamp(low, max(low, high)).toInt();
    return _dialogFrame(
      screenWidth: screenWidth,
      title: 'Заказ',
      children: [
        if (canBid)
          _stepper(amount, low, high, r.rules.bidStep)
        else
          Text(
            'Больше $high без марьяжа не заказать',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        _buttons([
          _goldButton('Пас', () {
            _amount = null;
            controller.pass();
          }),
          _goldButton(
            'Заказать',
            canBid
                ? () {
                    _amount = null;
                    controller.bid(amount);
                  }
                : null,
          ),
        ]),
      ],
    );
  }

  Widget _contractPanel(Round r, double screenWidth) {
    final low = r.contract;
    final high = max(low, r.maxRaise);
    final amount = (_amount ?? low).clamp(low, high);
    final share = r.rules.concessionOpponentPoints(r.auctionBid);
    return _dialogFrame(
      screenWidth: screenWidth,
      title: 'Играем на',
      children: [
        _stepper(amount, low, high, r.rules.bidStep),
        _buttons([
          _goldButton(
            'Расписаться',
            () => _confirmConcede(r.auctionBid, share),
          ),
          _goldButton('Играть', () {
            _amount = null;
            controller.startPlay(amount);
          }),
        ]),
      ],
    );
  }

  Widget _exchangePanel(double screenWidth) {
    final names = controller.names;
    const style = TextStyle(color: Colors.white, fontSize: 18);
    return _dialogFrame(
      screenWidth: screenWidth,
      title: 'Отдать карты',
      children: [
        Text('${cardLabel(_give[0])} → ${names[left]}', style: style),
        Text('${cardLabel(_give[1])} → ${names[right]}', style: style),
        _buttons([
          _goldButton('Заново', () => setState(_give.clear)),
          _goldButton('Отдать', () => controller.giveCards(_give[0], _give[1])),
        ]),
      ],
    );
  }

  Widget _resultPanel() {
    final rec = controller.record!;
    final res = rec.result;
    final game = controller.game;
    final names = controller.names;
    final d = res.declarer;
    final title = res.conceded
        ? '${controller.says(d, 'расписались', 'расписался')} на ${res.bid}'
        : res.made
        ? '${controller.says(d, 'сыграли', 'сыграл')} ${res.bid}'
        : '${controller.says(d, 'не сыграли', 'не сыграл')} ${res.bid}';
    const bold = TextStyle(fontWeight: FontWeight.w600);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {0: FlexColumnWidth(1.4)},
            children: [
              const TableRow(
                children: [
                  Text(''),
                  Text('Очки', style: bold),
                  Text('±', style: bold),
                  Text('Итого', style: bold),
                ],
              ),
              for (var p = 0; p < playerCount; p++)
                TableRow(
                  children: [
                    Text(names[p], style: p == d ? bold : null),
                    Text(res.conceded ? '—' : '${res.points[p]}'),
                    Text(_signed(rec.deltas[p])),
                    Text('${rec.scores[p]}'),
                  ],
                ),
            ],
          ),
          for (var p = 0; p < playerCount; p++)
            if (rec.events[p].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${names[p]}: ${rec.events[p].map(scoreEventLabel).join(', ')}',
                  style: const TextStyle(color: Colors.deepOrange),
                ),
              ),
          const SizedBox(height: 16),
          if (game.isOver) ...[
            Text(
              game.winner == me
                  ? 'Вы победили!'
                  : 'Победил ${names[game.winner!]}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: controller.newGame,
              child: const Text('Новая игра'),
            ),
          ] else
            FilledButton(
              onPressed: controller.nextRound,
              child: const Text('Дальше'),
            ),
        ],
      ),
    );
  }

  String _signed(int v) => v > 0 ? '+$v' : '$v';

  // --- Hand ---

  /// Left to right: spades, clubs, diamonds, hearts; strongest first.
  static const _suitOrder = [
    Suit.spades,
    Suit.clubs,
    Suit.diamonds,
    Suit.hearts,
  ];

  Widget _hand(double cardWidth, double maxWidth, double lift) {
    final r = controller.round;
    final hand = r.hands[me];
    final groups = [
      for (final suit in _suitOrder)
        hand.where((c) => c.suit == suit).toList()
          ..sort((a, b) => b.rank.strength.compareTo(a.rank.strength)),
    ].where((g) => g.isNotEmpty).toList();

    final playing = r.phase == RoundPhase.playing && controller.isHumanTurn;
    final legal = playing ? r.legalCards(me).toSet() : const <Card>{};
    final exchanging = r.phase == RoundPhase.exchange && controller.isHumanTurn;

    // Cards overlap within a suit; suits are separated by a gap. Squeeze
    // both if the hand doesn't fit. The last card of each suit is shown in
    // full, so those widths are fixed.
    var step = cardWidth * 0.62;
    var gap = cardWidth * 0.18;
    final fixed = cardWidth * groups.length;
    final flexible =
        step * (hand.length - groups.length) + gap * (groups.length - 1);
    if (flexible > 0 && fixed + flexible > maxWidth) {
      final scale = ((maxWidth - fixed) / flexible).clamp(0.0, 1.0);
      step *= scale;
      gap *= scale;
    }

    final cards = <Widget>[];
    var x = 0.0;
    for (final (gi, group) in groups.indexed) {
      for (final (ci, card) in group.indexed) {
        cards.add(
          Positioned(
            left: x,
            bottom: 0,
            child: _handCard(card, cardWidth, lift, playing, legal, exchanging),
          ),
        );
        x += ci == group.length - 1 ? cardWidth : step;
      }
      if (gi < groups.length - 1) x += gap;
    }

    return SizedBox(
      width: max(x, 1),
      height: cardWidth * cardAspect + lift,
      child: Stack(clipBehavior: Clip.none, children: cards),
    );
  }

  Widget _handCard(
    Card card,
    double cardWidth,
    double lift,
    bool playing,
    Set<Card> legal,
    bool exchanging,
  ) {
    final picked = _give.contains(card);
    final raised = picked || (playing && legal.contains(card));
    return GestureDetector(
      onTap: () {
        if (exchanging) {
          setState(() {
            if (picked) {
              _give.remove(card);
            } else if (_give.length < 2) {
              _give.add(card);
            }
          });
        } else if (playing && legal.contains(card)) {
          _playCard(card);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: raised ? lift : 0),
        child: PlayingCard(
          card,
          width: cardWidth,
          dimmed: playing && !legal.contains(card),
          highlighted: picked,
        ),
      ),
    );
  }

  Future<void> _playCard(Card card) async {
    final r = controller.round;
    var declare = false;
    if (r.canDeclareWith(me, card)) {
      final ace = card.rank == Rank.ace;
      final value = ace ? r.rules.aceMarriageValue : card.suit.marriageValue;
      final name = ace ? 'тузовый марьяж' : 'марьяж ${card.suit.symbol}';
      final answer = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Объявить $name?'),
          content: Text(
            '+$value очков${ace ? '' : ', ${card.suit.symbol} станет козырем'}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Просто сходить'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Объявить'),
            ),
          ],
        ),
      );
      if (answer == null) return;
      declare = answer;
    }
    controller.play(card, declare: declare);
  }

  // --- Dialogs ---

  Future<void> _confirmConcede(int bid, int share) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Расписаться?'),
        content: Text('Вам −$bid, соперникам по +$share.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Расписаться'),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      _amount = null;
      controller.concede();
    }
  }

  Future<void> _confirmNewGame(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Начать новую игру?'),
        content: const Text('Текущая партия будет потеряна.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Новая игра'),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      _amount = null;
      controller.newGame();
    }
  }

  void _showScores(BuildContext context) {
    final names = controller.names;
    final history = controller.game.history;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(16),
          children: [
            Text('Счёт', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {0: FixedColumnWidth(36)},
              children: [
                TableRow(
                  children: [
                    const Text('#'),
                    for (final n in names)
                      Text(
                        n,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                for (final (i, rec) in history.indexed)
                  TableRow(
                    children: [
                      Text(
                        '${i + 1}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      for (var p = 0; p < playerCount; p++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${rec.scores[p]}  (${_signed(rec.deltas[p])})',
                            style: TextStyle(
                              fontWeight: p == rec.result.declarer
                                  ? FontWeight.w600
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Пока ни одного кона.'),
              ),
          ],
        ),
      ),
    );
  }
}

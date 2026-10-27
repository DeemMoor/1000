import 'card.dart';
import 'rules.dart';

extension HandX on Iterable<Card> {
  int get points => fold(0, (sum, c) => sum + c.points);

  /// Suits in which this hand holds both king and queen.
  List<Suit> get marriages => [
    for (final suit in Suit.values)
      if (contains(Card(suit, Rank.king)) && contains(Card(suit, Rank.queen)))
        suit,
  ];

  bool get hasFourAces => where((c) => c.rank == Rank.ace).length == 4;

  bool get hasFourNines => where((c) => c.rank == Rank.nine).length == 4;

  /// Total value of all marriages this hand could declare.
  int marriageValue(GameRules rules) =>
      marriages.fold(0, (sum, s) => sum + s.marriageValue) +
      (rules.aceMarriage && hasFourAces ? rules.aceMarriageValue : 0);
}

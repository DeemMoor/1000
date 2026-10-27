import 'dart:math';

enum Suit {
  spades('♠', 40),
  clubs('♣', 60),
  diamonds('♦', 80),
  hearts('♥', 100);

  const Suit(this.symbol, this.marriageValue);

  final String symbol;

  /// Points for declaring a king+queen pair of this suit.
  final int marriageValue;
}

enum Rank {
  nine('9', 0),
  jack('J', 2),
  queen('Q', 3),
  king('K', 4),
  ten('10', 10),
  ace('A', 11);

  const Rank(this.label, this.points);

  final String label;
  final int points;

  /// Trick-taking strength: 9 < J < Q < K < 10 < A.
  int get strength => index;
}

class Card implements Comparable<Card> {
  const Card(this.suit, this.rank);

  final Suit suit;
  final Rank rank;

  int get points => rank.points;

  /// Compact id like `AH`, `10S` — stable for serialization.
  String get id => '${rank.label}${suit.name[0].toUpperCase()}';

  static Card fromId(String id) {
    final suitChar = id[id.length - 1];
    final rankLabel = id.substring(0, id.length - 1);
    return Card(
      Suit.values.firstWhere((s) => s.name[0].toUpperCase() == suitChar),
      Rank.values.firstWhere((r) => r.label == rankLabel),
    );
  }

  @override
  int compareTo(Card other) => suit != other.suit
      ? suit.index.compareTo(other.suit.index)
      : rank.strength.compareTo(other.rank.strength);

  @override
  bool operator ==(Object other) =>
      other is Card && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => suit.index * 8 + rank.index;

  @override
  String toString() => '${rank.label}${suit.symbol}';
}

class Deck {
  Deck._();

  static final List<Card> full = List.unmodifiable([
    for (final suit in Suit.values)
      for (final rank in Rank.values) Card(suit, rank),
  ]);

  static List<Card> shuffled([Random? random]) =>
      List.of(full)..shuffle(random ?? Random.secure());
}

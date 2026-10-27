import 'package:thousand_engine/thousand_engine.dart';

String rankLabel(Rank rank) => switch (rank) {
  Rank.nine => '9',
  Rank.ten => '10',
  Rank.jack => 'В',
  Rank.queen => 'Д',
  Rank.king => 'К',
  Rank.ace => 'Т',
};

String cardLabel(Card card) => '${rankLabel(card.rank)}${card.suit.symbol}';

bool isRed(Suit suit) => suit == Suit.hearts || suit == Suit.diamonds;

String redealLabel(RedealReason reason) => switch (reason) {
  RedealReason.poorPrikup => 'в прикупе меньше 5 очков',
  RedealReason.fourNines => 'четыре девятки',
};

String scoreEventLabel(ScoreEvent event) => switch (event) {
  ScoreEvent.bolt => 'болт',
  ScoreEvent.boltPenalty => 'три болта −120',
  ScoreEvent.concessionPenalty => 'три росписи −120',
  ScoreEvent.barrelOn => 'на бочке',
  ScoreEvent.barrelFailed => 'слетел с бочки',
  ScoreEvent.barrelPenalty => 'бочка −120',
  ScoreEvent.pit => 'яма! сброс в 0',
};

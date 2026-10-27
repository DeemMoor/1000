/// Configurable rule set. Defaults match README.md; anything the players
/// may disagree on lives here so the app can expose it in settings.
class GameRules {
  const GameRules({
    this.targetScore = 1000,
    this.minBid = 100,
    this.bidStep = 5,
    this.maxBidWithoutMarriage = 120,
    this.aceMarriage = false,
    this.aceMarriageValue = 200,
    this.redealPrikupBelow = 5,
    this.redealOnFourNines = true,
    this.barrelScore = 880,
    this.barrelAttempts = 3,
    this.barrelPenalty = 120,
    this.boltsForPenalty = 3,
    this.boltPenalty = 120,
    this.concessionsForPenalty = 3,
    this.concessionPenalty = 120,
    this.pitScore = 555,
    this.roundTo = 5,
  });

  final int targetScore;

  final int minBid;
  final int bidStep;

  /// Bidding above this requires a marriage in hand.
  final int maxBidWithoutMarriage;

  /// Four aces declared as a "marriage" (off by default).
  final bool aceMarriage;
  final int aceMarriageValue;

  /// Redeal if the prikup is worth fewer points than this (0 disables).
  final int redealPrikupBelow;

  /// Redeal if any player holds all four nines.
  final bool redealOnFourNines;

  /// "Бочка": reaching this score freezes a player until they make a bid.
  final int barrelScore;
  final int barrelAttempts;
  final int barrelPenalty;

  /// "Болт": a round without a single trick.
  final int boltsForPenalty;
  final int boltPenalty;

  /// "Роспись": the declarer gives up after seeing the prikup.
  final int concessionsForPenalty;
  final int concessionPenalty;

  /// On concession the declarer loses the bid won at auction (before any
  /// raise), and each opponent gets half of it rounded down to [roundTo]:
  /// 105 -> 50, 110 -> 55, 115 -> 55.
  int concessionOpponentPoints(int auctionBid) =>
      auctionBid ~/ 2 ~/ roundTo * roundTo;

  /// "Яма": landing exactly on this score resets it to zero (0 disables).
  final int pitScore;

  /// Defenders' round points are rounded to the nearest multiple of this.
  final int roundTo;
}

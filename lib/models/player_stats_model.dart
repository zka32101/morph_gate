class PlayerStatsModel {
  final int score;
  final int wallsPassed;
  final int maxCombo;
  final int totalGamesPlayed;
  final double clearRate;
  final int jellifyLevel;

  const PlayerStatsModel({
    this.score = 0,
    this.wallsPassed = 0,
    this.maxCombo = 0,
    this.totalGamesPlayed = 0,
    this.clearRate = 0,
    this.jellifyLevel = 0,
  });

  PlayerStatsModel copyWith({
    int? score,
    int? wallsPassed,
    int? maxCombo,
    int? totalGamesPlayed,
    double? clearRate,
    int? jellifyLevel,
  }) {
    return PlayerStatsModel(
      score: score ?? this.score,
      wallsPassed: wallsPassed ?? this.wallsPassed,
      maxCombo: maxCombo ?? this.maxCombo,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      clearRate: clearRate ?? this.clearRate,
      jellifyLevel: jellifyLevel ?? this.jellifyLevel,
    );
  }
}

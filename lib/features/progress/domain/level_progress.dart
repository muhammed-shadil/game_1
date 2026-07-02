/// Persisted result for a single level.
class LevelProgress {
  const LevelProgress({
    required this.levelId,
    this.stars = 0,
    this.bestShots,
    this.completed = false,
  });

  final String levelId;

  /// Best star rating achieved (0..3).
  final int stars;

  /// Fewest shots used on a successful run, or null if never completed.
  final int? bestShots;
  final bool completed;

  LevelProgress merge({int? stars, int? bestShots, bool? completed}) {
    return LevelProgress(
      levelId: levelId,
      stars: stars != null && stars > this.stars ? stars : this.stars,
      bestShots: bestShots == null
          ? this.bestShots
          : (this.bestShots == null
              ? bestShots
              : (bestShots < this.bestShots! ? bestShots : this.bestShots)),
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'stars': stars,
        'bestShots': bestShots,
        'completed': completed,
      };

  factory LevelProgress.fromJson(Map<String, dynamic> json) => LevelProgress(
        levelId: json['levelId'] as String,
        stars: (json['stars'] as num?)?.toInt() ?? 0,
        bestShots: (json['bestShots'] as num?)?.toInt(),
        completed: json['completed'] as bool? ?? false,
      );
}

/// Aggregate player state kept in memory + persisted as a whole.
class PlayerProfile {
  const PlayerProfile({
    this.coins = 0,
    this.progress = const {},
  });

  final int coins;

  /// Keyed by levelId.
  final Map<String, LevelProgress> progress;

  int get totalStars =>
      progress.values.fold(0, (sum, p) => sum + p.stars);

  LevelProgress? forLevel(String id) => progress[id];

  PlayerProfile copyWith({int? coins, Map<String, LevelProgress>? progress}) {
    return PlayerProfile(
      coins: coins ?? this.coins,
      progress: progress ?? this.progress,
    );
  }
}

/// High-level phase of a single play session, surfaced to the Flutter HUD.
enum GamePhase {
  /// Waiting for the player to aim & release the slingshot.
  aiming,

  /// A projectile is in flight / the scene is still moving.
  simulating,

  /// The scene has settled and the level was cleared.
  won,

  /// The scene has settled with shots exhausted and targets remaining.
  lost,
}

/// Immutable outcome handed to the presentation layer when a level resolves.
class GameResult {
  const GameResult({
    required this.won,
    required this.stars,
    required this.shotsUsed,
    required this.targetsRemaining,
  });

  final bool won;
  final int stars;
  final int shotsUsed;

  /// Targets left standing (0 on a win).
  final int targetsRemaining;
}

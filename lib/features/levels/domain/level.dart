import 'package:flame/extensions.dart';

import '../../../core/config/game_config.dart';
import 'level_object.dart';

enum LevelDifficulty {
  tutorial,
  easy,
  medium,
  hard,
  expert,
  challenge,
  bonus;

  static LevelDifficulty parse(String? raw) => switch (raw) {
        'easy' => LevelDifficulty.easy,
        'medium' => LevelDifficulty.medium,
        'hard' => LevelDifficulty.hard,
        'expert' => LevelDifficulty.expert,
        'challenge' => LevelDifficulty.challenge,
        'bonus' => LevelDifficulty.bonus,
        _ => LevelDifficulty.tutorial,
      };

  String get label => switch (this) {
        LevelDifficulty.tutorial => 'Tutorial',
        LevelDifficulty.easy => 'Easy',
        LevelDifficulty.medium => 'Medium',
        LevelDifficulty.hard => 'Hard',
        LevelDifficulty.expert => 'Expert',
        LevelDifficulty.challenge => 'Challenge',
        LevelDifficulty.bonus => 'Bonus',
      };
}

/// Selectable scenery for a level. Each maps to a bundled background image.
/// A level can set this explicitly in JSON; otherwise it's derived from the
/// difficulty so the world visibly changes as the player progresses.
enum BackgroundTheme {
  day,
  sunset,
  night,
  desert,
  snow;

  String get asset => 'assets/images/bg_$name.png';

  static BackgroundTheme parse(String? raw) => switch (raw) {
        'day' => BackgroundTheme.day,
        'sunset' => BackgroundTheme.sunset,
        'night' => BackgroundTheme.night,
        'desert' => BackgroundTheme.desert,
        'snow' => BackgroundTheme.snow,
        _ => BackgroundTheme.day,
      };

  static BackgroundTheme fromDifficulty(LevelDifficulty d) => switch (d) {
        LevelDifficulty.tutorial => BackgroundTheme.day,
        LevelDifficulty.easy => BackgroundTheme.day,
        LevelDifficulty.medium => BackgroundTheme.sunset,
        LevelDifficulty.hard => BackgroundTheme.night,
        LevelDifficulty.expert => BackgroundTheme.desert,
        LevelDifficulty.challenge => BackgroundTheme.snow,
        LevelDifficulty.bonus => BackgroundTheme.snow,
      };
}

/// A fully parsed, immutable level definition. This is the contract a future
/// visual level editor must produce.
class Level {
  const Level({
    required this.id,
    required this.name,
    required this.index,
    required this.difficulty,
    required this.shots,
    required this.worldSize,
    required this.slingshotPosition,
    required this.objects,
    required this.twoStarShots,
    required this.threeStarShots,
    required this.background,
    this.gravityScale = 1.0,
  });

  final String id;
  final String name;

  /// 1-based ordinal used for display + unlock ordering.
  final int index;
  final LevelDifficulty difficulty;

  /// Projectiles available for this level.
  final int shots;

  /// Playfield extents in meters. Used for camera bounds.
  final Vector2 worldSize;
  final Vector2 slingshotPosition;
  final List<LevelObject> objects;

  /// Multiplies the global gravity (gravity switches / low-grav levels).
  final double gravityScale;

  /// Shots-used thresholds for the 2nd and 3rd star. Using fewer shots than or
  /// equal to the threshold earns that star.
  final int twoStarShots;
  final int threeStarShots;

  /// Scenery drawn behind the play area.
  final BackgroundTheme background;

  int get targetCount =>
      objects.where((o) => o.type == LevelObjectType.target).length;

  /// Computes stars (0..3) for a completed level given projectiles used.
  int starsForShots(int shotsUsed) {
    if (shotsUsed <= threeStarShots) return 3;
    if (shotsUsed <= twoStarShots) return 2;
    return 1;
  }

  factory Level.fromJson(Map<String, dynamic> json) {
    Vector2 vec(dynamic v, Vector2 fallback) {
      if (v is List && v.length >= 2) {
        return Vector2((v[0] as num).toDouble(), (v[1] as num).toDouble());
      }
      return fallback;
    }

    final world = vec(json['worldSize'], Vector2(60, 34));
    final shots = (json['shots'] as num?)?.toInt() ?? GameConfig.defaultShots;
    final stars = json['starThresholds'] as Map<String, dynamic>?;
    final difficulty = LevelDifficulty.parse(json['difficulty'] as String?);

    return Level(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled',
      index: (json['index'] as num?)?.toInt() ?? 0,
      difficulty: difficulty,
      background: json['background'] != null
          ? BackgroundTheme.parse(json['background'] as String?)
          : BackgroundTheme.fromDifficulty(difficulty),
      shots: shots,
      worldSize: world,
      gravityScale: (json['gravityScale'] as num?)?.toDouble() ?? 1.0,
      slingshotPosition:
          vec(json['slingshot'], Vector2(world.x * 0.18, world.y * 0.55)),
      objects: ((json['objects'] as List?) ?? const [])
          .map((e) => LevelObject.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      twoStarShots: (stars?['twoStar'] as num?)?.toInt() ?? shots - 1,
      threeStarShots: (stars?['threeStar'] as num?)?.toInt() ?? 1,
    );
  }
}

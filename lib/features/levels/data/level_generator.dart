import 'dart:math' as math;

import 'package:flame/extensions.dart';

import '../domain/level.dart';
import '../domain/level_object.dart';

/// Deterministically builds levels beyond the hand-authored set so the game can
/// offer many stages without 35 fragile JSON files. Each level is seeded by its
/// index (so it's identical every run) and assembled from reusable "structures"
/// — towers, bunkers, pyramids, walled compounds and blast-the-house crates.
///
/// Layouts are designed to always be winnable: every structure exposes a
/// reachable target (on top / behind a low wall) or an explosive crate whose
/// blast clears an otherwise-protected target.
class LevelGenerator {
  const LevelGenerator._();

  static const double _groundTop = 30;
  static const _names = [
    'Skyline', 'Demolition', 'Tremor', 'Aftershock', 'Cross Fire',
    'Stackpile', 'Fault Line', 'Powder Keg', 'Landslide', 'Rampart',
    'Blast Zone', 'Domino', 'Keystone', 'Shockwave', 'Collapse',
    'Barricade', 'Detonator', 'Ricochet', 'Bombard', 'Meltdown',
  ];

  /// Generates levels for the inclusive index range [from]..[to].
  static List<Level> generateRange(int from, int to) =>
      [for (var i = from; i <= to; i++) generate(i)];

  static Level generate(int index) {
    final rng = math.Random(index * 7919);
    final difficulty = _difficultyFor(index);

    final worldW = (60 + (index - 15) * 1.4).clamp(60.0, 88.0);
    final worldSize = Vector2(worldW, 34);

    final objects = <LevelObject>[
      _box(LevelMaterial.ground, worldW / 2, 32, worldW + 30, 4,
          type: LevelObjectType.ground),
    ];

    final structureCount = (2 + (index - 16) ~/ 8).clamp(2, 5);
    final startX = 28.0;
    final endX = worldW - 9;
    for (var i = 0; i < structureCount; i++) {
      final x = structureCount == 1
          ? (startX + endX) / 2
          : startX + (endX - startX) * (i / (structureCount - 1));
      objects.addAll(_structure(x, rng, difficulty));
    }

    final targetCount =
        objects.where((o) => o.type == LevelObjectType.target).length;
    // Generous shot budget so levels stay winnable; harder tiers give less.
    final bonus = switch (difficulty) {
      LevelDifficulty.medium => 2,
      LevelDifficulty.hard => 1,
      _ => 1,
    };
    final shots = (targetCount + bonus).clamp(3, 7);

    return Level(
      id: 'level_${index.toString().padLeft(2, '0')}',
      name: _names[index % _names.length],
      index: index,
      difficulty: difficulty,
      background: BackgroundTheme.fromDifficulty(difficulty),
      shots: shots,
      worldSize: worldSize,
      slingshotPosition: Vector2(9, 26),
      objects: objects,
      twoStarShots: shots - 1,
      threeStarShots: math.max(1, (targetCount / 2).ceil()),
    );
  }

  static LevelDifficulty _difficultyFor(int index) {
    if (index <= 24) return LevelDifficulty.medium;
    if (index <= 33) return LevelDifficulty.hard;
    if (index <= 42) return LevelDifficulty.expert;
    return LevelDifficulty.challenge;
  }

  /// Picks and builds one structure centered on [x].
  static List<LevelObject> _structure(
      double x, math.Random rng, LevelDifficulty d) {
    final patterns = <List<LevelObject> Function()>[
      () => _tower(x, rng),
      () => _bunker(x, rng),
      () => _pyramid(x, rng),
    ];
    if (d.index >= LevelDifficulty.hard.index) {
      patterns.add(() => _house(x, rng)); // blast-the-house (with a crate)
      patterns.add(() => _tallTower(x, rng));
    }
    if (d.index >= LevelDifficulty.expert.index) {
      patterns.add(() => _wallGap(x, rng));
    }
    return patterns[rng.nextInt(patterns.length)]();
  }

  // --- Structure builders (y grows downward; ground surface at _groundTop) ---

  static List<LevelObject> _tower(double x, math.Random rng) {
    final baseMat = rng.nextBool() ? LevelMaterial.stone : LevelMaterial.wood;
    return [
      _box(baseMat, x, _groundTop - 2, 2.4, 4),
      _target(x, _groundTop - 5.5, 2.2, 3),
    ];
  }

  static List<LevelObject> _tallTower(double x, math.Random rng) {
    return [
      _box(LevelMaterial.stone, x, _groundTop - 2, 2.6, 4),
      _box(LevelMaterial.wood, x, _groundTop - 5.5, 2.2, 3),
      _target(x, _groundTop - 8.3, 2, 2.6),
    ];
  }

  static List<LevelObject> _bunker(double x, math.Random rng) {
    return [
      _box(LevelMaterial.stone, x - 2.2, _groundTop - 2, 1, 4),
      _target(x + 0.6, _groundTop - 2, 2.2, 4),
    ];
  }

  static List<LevelObject> _pyramid(double x, math.Random rng) {
    return [
      _box(LevelMaterial.wood, x - 1.3, _groundTop - 2, 2, 4),
      _box(LevelMaterial.wood, x + 1.3, _groundTop - 2, 2, 4),
      _target(x, _groundTop - 5.5, 2.4, 3),
    ];
  }

  /// A walled house that protects a target — the intended solution is to hit
  /// the explosive crate on the roof and let the blast clear the target.
  static List<LevelObject> _house(double x, math.Random rng) {
    return [
      _box(LevelMaterial.stone, x - 2, _groundTop - 3, 1, 6),
      _box(LevelMaterial.stone, x + 2, _groundTop - 3, 1, 6),
      _box(LevelMaterial.wood, x, _groundTop - 6.5, 5, 1),
      _target(x, _groundTop - 2, 2, 4),
      _explosive(x, _groundTop - 7.8, 1.8, 1.8),
    ];
  }

  static List<LevelObject> _wallGap(double x, math.Random rng) {
    return [
      _box(LevelMaterial.stone, x, _groundTop - 6, 1.5, 12),
      _target(x + 4, _groundTop - 2, 2.2, 4),
      _target(x + 6.2, _groundTop - 2, 2.2, 4),
    ];
  }

  // --- Object factories ------------------------------------------------------

  static LevelObject _box(
    LevelMaterial mat,
    double x,
    double y,
    double w,
    double h, {
    LevelObjectType type = LevelObjectType.obstacle,
  }) =>
      LevelObject(
        type: type,
        shape: LevelShape.box,
        material: mat,
        position: Vector2(x, y),
        size: Vector2(w, h),
      );

  static LevelObject _target(double x, double y, double w, double h) =>
      LevelObject(
        type: LevelObjectType.target,
        shape: LevelShape.box,
        material: LevelMaterial.target,
        position: Vector2(x, y),
        size: Vector2(w, h),
      );

  static LevelObject _explosive(double x, double y, double w, double h) =>
      LevelObject(
        type: LevelObjectType.explosive,
        shape: LevelShape.box,
        material: LevelMaterial.wood,
        position: Vector2(x, y),
        size: Vector2(w, h),
      );
}

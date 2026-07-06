import 'package:flame/extensions.dart';

/// The role a body plays in a level. Drives which component is spawned and how
/// win/lose is evaluated.
enum LevelObjectType {
  ground,
  obstacle,
  target,

  /// A crate that detonates when struck hard, blasting nearby bodies and
  /// destroying nearby targets (and chain-triggering other crates).
  explosive,
  unknown;

  static LevelObjectType parse(String? raw) => switch (raw) {
        'ground' => LevelObjectType.ground,
        'obstacle' => LevelObjectType.obstacle,
        'target' => LevelObjectType.target,
        'explosive' => LevelObjectType.explosive,
        _ => LevelObjectType.unknown,
      };
}

/// Collision/visual shape of a body.
enum LevelShape {
  box,
  circle;

  static LevelShape parse(String? raw) =>
      raw == 'circle' ? LevelShape.circle : LevelShape.box;
}

/// Named material preset (resolved against [PhysicsConfig] at spawn time).
enum LevelMaterial {
  wood,
  stone,
  ice,
  metal,
  target,
  ground;

  static LevelMaterial parse(String? raw) => switch (raw) {
        'stone' => LevelMaterial.stone,
        'ice' => LevelMaterial.ice,
        'metal' => LevelMaterial.metal,
        'target' => LevelMaterial.target,
        'ground' => LevelMaterial.ground,
        _ => LevelMaterial.wood,
      };
}

/// A single spawnable entity described by the level JSON. Purely data — the
/// gameplay layer turns this into a Forge2D [BodyComponent].
class LevelObject {
  const LevelObject({
    required this.type,
    required this.shape,
    required this.material,
    required this.position,
    required this.size,
    this.angle = 0,
    this.hitPoints = 1,
  });

  final LevelObjectType type;
  final LevelShape shape;
  final LevelMaterial material;

  /// Center position, in world meters.
  final Vector2 position;

  /// For [LevelShape.box] this is (width, height). For circle, size.x is the
  /// diameter (size.y ignored).
  final Vector2 size;

  /// Rotation in radians.
  final double angle;

  /// How many qualifying hits a target survives before being destroyed.
  final int hitPoints;

  double get radius => size.x / 2;

  factory LevelObject.fromJson(Map<String, dynamic> json) {
    Vector2 vec(dynamic v, {double fallback = 0}) {
      if (v is List && v.length >= 2) {
        return Vector2((v[0] as num).toDouble(), (v[1] as num).toDouble());
      }
      return Vector2.all(fallback);
    }

    return LevelObject(
      type: LevelObjectType.parse(json['type'] as String?),
      shape: LevelShape.parse(json['shape'] as String?),
      material: LevelMaterial.parse(json['material'] as String?),
      position: vec(json['position']),
      size: vec(json['size'], fallback: 1),
      angle: (json['angle'] as num?)?.toDouble() ?? 0,
      hitPoints: (json['hitPoints'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'shape': shape.name,
        'material': material.name,
        'position': [position.x, position.y],
        'size': [size.x, size.y],
        'angle': angle,
        'hitPoints': hitPoints,
      };
}

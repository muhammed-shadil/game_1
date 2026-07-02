import 'package:flame_forge2d/flame_forge2d.dart';

import '../../../levels/domain/level_object.dart';
import 'physics_part.dart';

/// A movable, non-scoring block (wood/stone/ice/metal). Purely structural —
/// the player knocks these around to reach targets.
class Obstacle extends PhysicsPart {
  Obstacle.fromSpec(LevelObject spec)
      : super(
          spawnPosition: spec.position.clone(),
          shape: spec.shape,
          halfSize: spec.shape == LevelShape.circle
              ? Vector2.all(spec.size.x / 2)
              : spec.size / 2,
          bodyType: BodyType.dynamic,
          material: MaterialLibrary.preset(spec.material),
          skin: MaterialLibrary.skin(spec.material),
          spawnAngle: spec.angle,
          priority: 5,
        );
}

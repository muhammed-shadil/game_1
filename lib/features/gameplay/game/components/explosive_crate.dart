import 'dart:math' as math;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/physics_config.dart';
import '../../../levels/domain/level_object.dart';
import 'physics_part.dart';

/// A crate that detonates when struck hard enough, applying a radial blast to
/// nearby bodies and destroying nearby targets. Detonations chain — one crate
/// can set off others in range. The actual blast physics live in
/// [PuzzleGame.onExplosion] so a chain can be resolved centrally.
class ExplosiveCrate extends PhysicsPart with ContactCallbacks {
  ExplosiveCrate.fromSpec(LevelObject spec)
      : super(
          spawnPosition: spec.position.clone(),
          shape: spec.shape,
          halfSize: spec.shape == LevelShape.circle
              ? Vector2.all(spec.size.x / 2)
              : spec.size / 2,
          bodyType: BodyType.dynamic,
          material: PhysicsConfig.wood,
          skin: _skin,
          spawnAngle: spec.angle,
          priority: 9,
        );

  static const MaterialSkin _skin = MaterialSkin(
    Color(0xFF3A2320),
    Color(0xFF5A302A),
    stroke: Color(0xFF20110F),
  );

  bool _armed = true;
  double _pulse = 0;

  bool get armed => _armed;

  @override
  void update(double dt) {
    super.update(dt);
    _pulse = (_pulse + dt) % (math.pi * 2);
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (!_armed) return;
    final closing =
        (contact.bodyA.linearVelocity - contact.bodyB.linearVelocity).length;
    if (closing >= PhysicsConfig.explosiveTriggerSpeed) {
      detonate();
    }
  }

  /// Blows up (once). Safe to call repeatedly / from a chain reaction.
  void detonate() {
    if (!_armed) return;
    _armed = false;
    final at = center.clone();
    game.onExplosion(at);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Pulsing danger core so it's obviously explosive.
    final glow = 0.5 + 0.5 * math.sin(_pulse * 3);
    final r = (shape == LevelShape.circle ? shapeRadius : halfSize.x) * 0.5;
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = Color.lerp(
          const Color(0xFFFF7043),
          const Color(0xFFFFD24C),
          glow,
        )!,
    );
    canvas.drawCircle(
      Offset.zero,
      r * (1.2 + glow * 0.5),
      Paint()
        ..color = const Color(0xFFFF5C3A).withValues(alpha: 0.25 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.35),
    );
  }
}

import 'dart:math' as math;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/physics_config.dart';
import '../../../levels/domain/level_object.dart';
import 'physics_part.dart';

/// A scoring target. The level is won when every [Target] is destroyed.
///
/// A target loses a hit point whenever it's struck above
/// [PhysicsConfig.impactSpeedThreshold] closing speed (by the projectile, or by
/// debris — chain reactions are encouraged). It emits a glow so players can
/// read the objective at a glance.
class Target extends PhysicsPart with ContactCallbacks {
  Target.fromSpec(LevelObject spec)
      : hitPoints = spec.hitPoints,
        super(
          spawnPosition: spec.position.clone(),
          shape: spec.shape,
          halfSize: spec.shape == LevelShape.circle
              ? Vector2.all(spec.size.x / 2)
              : spec.size / 2,
          bodyType: BodyType.dynamic,
          material: MaterialLibrary.preset(LevelMaterial.target),
          skin: MaterialLibrary.skin(LevelMaterial.target),
          spawnAngle: spec.angle,
          priority: 8,
        );

  int hitPoints;
  bool _destroyed = false;
  double _pulse = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _pulse = (_pulse + dt) % (math.pi * 2);
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (_destroyed) return;
    final va = contact.bodyA.linearVelocity;
    final vb = contact.bodyB.linearVelocity;
    final closingSpeed = (va - vb).length;
    if (closingSpeed >= PhysicsConfig.impactSpeedThreshold) {
      _takeHit();
    }
  }

  void _takeHit() {
    hitPoints--;
    if (hitPoints <= 0) {
      _destroy();
    } else {
      // Flash/shake feedback for a non-lethal hit handled by the game.
      game.onTargetHit(center.clone());
    }
  }

  void _destroy() {
    if (_destroyed) return;
    _destroyed = true;
    game.onTargetDestroyed(center.clone());
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    // Pulsing aura behind the target to make objectives pop.
    final glow = 0.5 + 0.5 * math.sin(_pulse * 2);
    final auraRadius = (shape == LevelShape.circle
            ? shapeRadius
            : math.max(halfSize.x, halfSize.y)) +
        0.35 +
        glow * 0.25;
    canvas.drawCircle(
      Offset.zero,
      auraRadius,
      Paint()
        ..color = const Color(0xFFFF6B4A).withValues(alpha: 0.16 + glow * 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.4),
    );

    super.render(canvas);

    // A small inner "core" dot to read as a goal marker.
    canvas.drawCircle(
      Offset.zero,
      0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }
}

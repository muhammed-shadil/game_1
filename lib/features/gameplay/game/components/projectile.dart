import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/physics_config.dart';
import '../../../levels/domain/level_object.dart';
import 'physics_part.dart';

/// The launched projectile ("kinet"). A dense, slightly bouncy sphere with a
/// motion trail and impact feedback. Uses CCD so it can't tunnel through thin
/// walls at high speed.
class Projectile extends PhysicsPart with ContactCallbacks {
  Projectile({required Vector2 position, this.radius = 0.85})
      : super(
          spawnPosition: position.clone(),
          shape: LevelShape.circle,
          halfSize: Vector2.all(radius),
          bodyType: BodyType.dynamic,
          material: PhysicsConfig.projectile,
          skin: _skin,
          bullet: true,
          priority: 12,
        );

  final double radius;

  static const MaterialSkin _skin = MaterialSkin(
    Color(0xFF3B4FD8),
    Color(0xFF7C93FF),
    stroke: Color(0xFF2A369E),
  );

  bool launched = false;
  bool _spent = false;

  /// Recent world positions for the fading trail.
  final List<Vector2> _trail = [];
  static const int _maxTrail = 14;
  double _impactCooldown = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (_impactCooldown > 0) _impactCooldown -= dt;

    if (launched && !_spent) {
      final speed = body.linearVelocity.length;
      if (speed > 2.0) {
        _trail.add(body.position.clone());
        if (_trail.length > _maxTrail) _trail.removeAt(0);
      } else if (_trail.isNotEmpty) {
        _trail.removeAt(0);
      }
    }
  }

  /// Applies the launch impulse (called by the slingshot on release).
  void launch(Vector2 impulse) {
    launched = true;
    body.applyLinearImpulse(impulse);
    // A little spin in the travel direction reads as "thrown", not "slid".
    body.angularVelocity = impulse.x.sign * 4.0;
  }

  /// Marks the projectile as consumed so it stops emitting a trail/feedback
  /// (kept in the world so it can still act as debris).
  void markSpent() => _spent = true;

  @override
  void beginContact(Object other, Contact contact) {
    if (_impactCooldown > 0) return;
    final closing =
        (contact.bodyA.linearVelocity - contact.bodyB.linearVelocity).length;
    if (closing >= PhysicsConfig.impactSpeedThreshold * 0.6) {
      _impactCooldown = 0.12;
      game.onProjectileImpact(center.clone(), closing);
    }
  }

  @override
  void render(Canvas canvas) {
    // Trail: convert stored world positions into body-local offsets.
    if (_trail.length > 1) {
      for (var i = 0; i < _trail.length - 1; i++) {
        final t = i / _trail.length;
        final a = _trail[i] - body.position;
        canvas.drawCircle(
          Offset(a.x, a.y),
          radius * (0.25 + 0.5 * t),
          Paint()
            ..color = _skin.top.withValues(alpha: 0.05 + 0.18 * t)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.15),
        );
      }
    }

    // Outer energy glow.
    canvas.drawCircle(
      Offset.zero,
      radius * 1.5,
      Paint()
        ..color = _skin.top.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.3),
    );

    super.render(canvas);
  }
}

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/config/game_config.dart';
import '../../../../core/config/physics_config.dart';
import '../../../../core/utils/math_utils.dart';
import 'projectile.dart';
import 'trajectory_preview.dart';

/// The elastic launcher. Owns the "held" projectile, converts a drag gesture
/// into a clamped pull, previews the arc, and applies the launch impulse on
/// release. All aim math lives here so the world/game just forward gestures.
class Slingshot extends Component {
  Slingshot({required this.anchor, required this.trajectory});

  /// World position of the pouch (projectile rest point).
  final Vector2 anchor;
  final TrajectoryPreview trajectory;

  Projectile? _held;
  bool _aiming = false;
  final Vector2 _pull = Vector2.zero();

  bool get hasProjectile => _held != null;
  bool get isAiming => _aiming;

  /// Current pouch position (anchor while idle, anchor+pull while drawn back).
  Vector2 get pouch => anchor + _pull;

  /// Loads a projectile and freezes it at the pouch until launched.
  void loadProjectile(Projectile projectile) {
    _held = projectile;
    _pull.setZero();
    projectile.body.setType(BodyType.static);
    projectile.body.setTransform(anchor, 0);
  }

  void startAim() {
    if (_held == null) return;
    _aiming = true;
  }

  /// [worldPoint] is the finger position in world coordinates.
  void updateAim(Vector2 worldPoint) {
    if (!_aiming || _held == null) return;
    _pull.setFrom(
      MathUtils.clampLength(worldPoint - anchor, PhysicsConfig.maxPullDistance),
    );
    _held!.body.setTransform(pouch, 0);
    trajectory.show(pouch, _launchVelocity());
  }

  /// Releases the shot. Returns the launched projectile, or null if the pull
  /// was too small to count (treated as a cancel).
  Projectile? release() {
    trajectory.hide();
    final projectile = _held;
    if (!_aiming || projectile == null) {
      _aiming = false;
      return null;
    }
    _aiming = false;

    if (_pull.length < 0.4) {
      // Cancelled — snap the ball back to rest.
      projectile.body.setTransform(anchor, 0);
      return null;
    }

    projectile.body.setType(BodyType.dynamic);
    final impulse = _launchVelocity() * projectile.body.mass;
    projectile.launch(impulse);

    if (GameConfig.hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }

    _held = null;
    _pull.setZero();
    return projectile;
  }

  /// Resulting launch velocity: opposite the pull, scaled by draw strength.
  Vector2 _launchVelocity() => -_pull * PhysicsConfig.launchPower;

  // --- Visuals (drawn in world space) ---------------------------------------

  static const Color _wood = Color(0xFF8A5A32);
  static const Color _woodLight = Color(0xFFB07A46);
  static const Color _band = Color(0xFF4A2F1C);

  @override
  void render(Canvas canvas) {
    final baseX = anchor.x;
    final baseBottom = Offset(baseX, anchor.y + 3.2);
    final split = Offset(baseX, anchor.y + 0.4);
    final leftTip = Offset(baseX - 0.9, anchor.y - 0.5);
    final rightTip = Offset(baseX + 0.9, anchor.y - 0.5);

    final woodPaint = Paint()
      ..color = _wood
      ..strokeWidth = 0.42
      ..strokeCap = StrokeCap.round;
    final woodHi = Paint()
      ..color = _woodLight
      ..strokeWidth = 0.16
      ..strokeCap = StrokeCap.round;

    // Post + fork.
    canvas.drawLine(baseBottom, split, woodPaint);
    canvas.drawLine(split, leftTip, woodPaint);
    canvas.drawLine(split, rightTip, woodPaint);
    canvas.drawLine(baseBottom, split, woodHi);

    // Elastic bands to the pouch (only the back band shown behind the ball is
    // approximated here; good enough for a clean look).
    final pouchOffset = Offset(pouch.x, pouch.y);
    final bandPaint = Paint()
      ..color = _band
      ..strokeWidth = 0.22
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(leftTip, pouchOffset, bandPaint);
    canvas.drawLine(rightTip, pouchOffset, bandPaint);
  }
}

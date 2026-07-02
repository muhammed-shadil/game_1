import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

/// Dotted arc showing the predicted flight path while aiming.
///
/// It integrates the same ballistic equation the physics engine will use
/// (constant gravity, no drag for the preview) so the guide matches the actual
/// shot closely. Rendered in world space as a fading trail of dots.
class TrajectoryPreview extends Component {
  TrajectoryPreview({required this.gravity, this.samples = 26, this.step = 0.06});

  final Vector2 gravity;

  /// Number of dots to plot.
  final int samples;

  /// Simulated seconds between dots.
  final double step;

  bool visible = false;
  final Vector2 _start = Vector2.zero();
  final Vector2 _velocity = Vector2.zero();

  void show(Vector2 start, Vector2 initialVelocity) {
    visible = true;
    _start.setFrom(start);
    _velocity.setFrom(initialVelocity);
  }

  void hide() => visible = false;

  @override
  void render(Canvas canvas) {
    if (!visible) return;

    for (var i = 1; i <= samples; i++) {
      final t = i * step;
      // p = p0 + v0*t + 0.5*g*t^2
      final x = _start.x + _velocity.x * t + 0.5 * gravity.x * t * t;
      final y = _start.y + _velocity.y * t + 0.5 * gravity.y * t * t;

      final progress = i / samples;
      final radius = 0.22 * (1 - progress * 0.6);
      final alpha = (1 - progress) * 0.75;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }
}

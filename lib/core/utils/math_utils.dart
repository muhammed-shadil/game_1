import 'dart:math' as math;

import 'package:flame/extensions.dart';

/// Small, dependency-free math helpers used across the game + UI layers.
class MathUtils {
  const MathUtils._();

  /// Framerate-independent exponential smoothing factor.
  ///
  /// Use as: `value = lerpDouble(value, target, smoothing(rate, dt))`.
  /// [rate] is roughly "how many e-folds per second"; higher snaps faster.
  static double smoothing(double rate, double dt) {
    return 1 - math.exp(-rate * dt);
  }

  /// Linear interpolation for doubles (dart:ui's lerpDouble is nullable).
  static double lerp(double a, double b, double t) => a + (b - a) * t;

  static double clamp(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  /// Clamps a vector's magnitude to [maxLength], returning a new vector.
  static Vector2 clampLength(Vector2 v, double maxLength) {
    final len = v.length;
    if (len <= maxLength || len == 0) return v.clone();
    return v * (maxLength / len);
  }

  /// Maps [v] from range [inMin, inMax] onto [outMin, outMax] (unclamped).
  static double remap(
    double v,
    double inMin,
    double inMax,
    double outMin,
    double outMax,
  ) {
    if (inMax == inMin) return outMin;
    return outMin + (v - inMin) * (outMax - outMin) / (inMax - inMin);
  }
}

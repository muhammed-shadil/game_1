import 'package:flutter/foundation.dart';

/// Non-physics gameplay + feel constants. Kept separate from [PhysicsConfig]
/// so the two concerns can evolve independently.
class GameConfig {
  const GameConfig._();

  static const String appName = 'Kinetix';
  static const String tagline = 'Physics, perfected.';

  /// Hive box name used for persisted progress.
  static const String progressBoxName = 'progress_box';

  /// Coins awarded per star earned when a level is completed.
  static const int coinsPerStar = 15;

  /// Default number of projectiles a level grants if it does not specify one.
  static const int defaultShots = 3;

  // ---- Camera feel -----------------------------------------------------------

  /// How quickly the camera catches up to its follow target (0..1 per frame,
  /// framerate-independent via exponential smoothing). Lower = floatier.
  static const double cameraFollowLerp = 6.0;

  /// Zoom applied while aiming, as a multiplier of the base fit-zoom.
  static const double aimZoomMultiplier = 1.12;

  /// Max camera shake translation in meters, decays over [shakeDecay] seconds.
  static const double maxShakeIntensity = 0.9;
  static const double shakeDecay = 2.4;

  // ---- Reduced-motion aware durations ---------------------------------------

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 560);

  /// Whether haptics should fire. Toggled by the settings/accessibility layer.
  static bool hapticsEnabled = true;

  /// Whether sound effects and music should play.
  static bool soundEnabled = true;

  /// When true, cosmetic animations are minimised (accessibility).
  static bool reducedMotion = false;

  /// Guard so debug-only asserts/log lines can be stripped in release.
  static bool get verbose => kDebugMode;
}

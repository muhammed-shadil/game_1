import 'dart:math' as math;

import 'package:flame/components.dart';

import '../../../../core/config/game_config.dart';
import '../../../../core/utils/math_utils.dart';

/// A cinematic camera controller.
///
/// Rather than fighting Flame's built-in [FollowBehavior] (which snaps hard and
/// doesn't compose with shake + bounds cleanly), this component owns the
/// viewfinder position directly and each frame:
///   1. eases toward the current follow target (framerate-independent),
///   2. adds decaying trauma-based shake,
///   3. clamps the result to the level bounds so the world never shows voids.
class GameCameraController extends Component {
  GameCameraController({
    required this.camera,
    required this.worldSize,
    required this.viewportWorldSize,
    Vector2? initialTarget,
  }) : _target = (initialTarget ?? worldSize / 2).clone() {
    _position = _clampToBounds(_target.clone());
  }

  final CameraComponent camera;

  /// Full level extents in meters.
  final Vector2 worldSize;

  /// How many world meters are visible (derived from zoom + screen size).
  Vector2 viewportWorldSize;

  final Vector2 _target;
  late Vector2 _position;

  /// 0..1 "trauma"; shake magnitude scales with trauma squared for a punchy,
  /// fast-decaying feel.
  double _trauma = 0;
  final math.Random _rng = math.Random();

  double _followLerp = GameConfig.cameraFollowLerp;

  /// Point the camera should ease toward (world coords).
  void follow(Vector2 worldPoint, {bool snap = false, double? lerp}) {
    _target.setFrom(worldPoint);
    if (lerp != null) _followLerp = lerp;
    if (snap) {
      _position = _clampToBounds(_target.clone());
      camera.viewfinder.position = _position;
    }
  }

  /// Adds camera trauma (0..1). Multiple impacts accumulate up to the cap.
  void addTrauma(double amount) {
    _trauma = MathUtils.clamp(_trauma + amount, 0, 1);
  }

  void setViewportWorldSize(Vector2 size) => viewportWorldSize = size;

  @override
  void update(double dt) {
    super.update(dt);
    if (GameConfig.reducedMotion) {
      _position = _clampToBounds(_target.clone());
      camera.viewfinder.position = _position;
      _trauma = 0;
      return;
    }

    final t = MathUtils.smoothing(_followLerp, dt);
    _position = Vector2(
      MathUtils.lerp(_position.x, _target.x, t),
      MathUtils.lerp(_position.y, _target.y, t),
    );

    final clamped = _clampToBounds(_position);

    // Trauma-based shake: quadratic falloff feels snappier than linear.
    Vector2 shake = Vector2.zero();
    if (_trauma > 0) {
      final magnitude = GameConfig.maxShakeIntensity * _trauma * _trauma;
      shake = Vector2(
        (_rng.nextDouble() * 2 - 1) * magnitude,
        (_rng.nextDouble() * 2 - 1) * magnitude,
      );
      _trauma = math.max(0, _trauma - dt / GameConfig.shakeDecay);
    }

    camera.viewfinder.position = clamped + shake;
  }

  /// Keeps the viewfinder centre so the viewport never extends past the level.
  Vector2 _clampToBounds(Vector2 desired) {
    final halfW = viewportWorldSize.x / 2;
    final halfH = viewportWorldSize.y / 2;

    double x = desired.x;
    double y = desired.y;

    if (worldSize.x <= viewportWorldSize.x) {
      x = worldSize.x / 2; // level narrower than screen: centre it.
    } else {
      x = MathUtils.clamp(x, halfW, worldSize.x - halfW);
    }

    if (worldSize.y <= viewportWorldSize.y) {
      y = worldSize.y / 2;
    } else {
      y = MathUtils.clamp(y, halfH, worldSize.y - halfH);
    }
    return Vector2(x, y);
  }
}

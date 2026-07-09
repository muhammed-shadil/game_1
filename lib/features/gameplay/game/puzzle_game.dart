import 'dart:math' as math;

import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/game_config.dart';
import '../../../core/config/physics_config.dart';
import '../../../core/services/audio_service.dart';
import '../../levels/domain/level.dart';
import 'camera/game_camera_controller.dart';
import 'components/physics_part.dart';
import 'components/projectile.dart';
import 'components/target.dart';
import 'effects/particle_effects.dart';
import 'game_state.dart';
import 'world/puzzle_world.dart';

/// The root Forge2D game for a single level.
///
/// Owns turn/scoring state and exposes it to the Flutter HUD via
/// [ValueNotifier]s (so widgets rebuild without the game knowing about them).
/// Physics + spawning live in [PuzzleWorld]; camera easing in
/// [GameCameraController]; this class is the referee.
class PuzzleGame extends Forge2DGame<PuzzleWorld> {
  PuzzleGame({required this.level, required this.onResolved})
      : super(
          world: PuzzleWorld(level: level),
          gravity: PhysicsConfig.gravity * level.gravityScale,
          zoom: PhysicsConfig.zoom,
        );

  final Level level;

  /// Invoked once when the level is won or lost.
  final void Function(GameResult result) onResolved;

  // --- HUD-facing reactive state ---------------------------------------------
  late final ValueNotifier<int> shotsLeft = ValueNotifier(level.shots);
  late final ValueNotifier<int> targetsLeft = ValueNotifier(level.targetCount);
  final ValueNotifier<GamePhase> phase = ValueNotifier(GamePhase.aiming);

  GameCameraController? cameraController;

  int _shotsUsed = 0;
  int _explosionsThisRun = 0;
  double _settleTimer = 0;
  double _simTime = 0;
  bool _resolved = false;
  Projectile? _activeProjectile;

  // Padding (meters) kept around the level when fitting it to the screen.
  static const double _hPadding = 6;
  static const double _vPadding = 4;

  /// User zoom multiplier on top of the fit-to-level base zoom. 1.0 shows the
  /// whole level; higher zooms in. Adjusted via [zoomIn] / [zoomOut].
  double _zoomFactor = 1.0;
  static const double _minZoomFactor = 1.0;
  static const double _maxZoomFactor = 3.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.zoom = _baseZoom() * _zoomFactor;
    cameraController = GameCameraController(
      camera: camera,
      worldSize: level.worldSize,
      viewportWorldSize: _viewportWorldSize(),
      initialTarget: level.worldSize / 2,
    );
    world.add(cameraController!);

    await world.build();
    await world.loadNextProjectile();
    _focusOnSlingshot(snap: true);
  }

  // --- Camera / zoom ---------------------------------------------------------

  /// Zoom that makes the entire level (plus padding) fit on screen. We take the
  /// smaller of the width/height fits so nothing is ever cropped.
  double _baseZoom() {
    final zx = size.x / (level.worldSize.x + _hPadding);
    final zy = size.y / (level.worldSize.y + _vPadding);
    return math.min(zx, zy);
  }

  Vector2 _viewportWorldSize() => size / camera.viewfinder.zoom;

  void _applyZoom() {
    camera.viewfinder.zoom = _baseZoom() * _zoomFactor;
    cameraController?.setViewportWorldSize(_viewportWorldSize());
  }

  /// Transparent so the painted scene behind the [GameWidget] shows through
  /// (Flame's default background is opaque black).
  @override
  Color backgroundColor() => const Color(0x00000000);

  /// Current absolute camera zoom (pixels per meter). The world snapshots this
  /// at the start of a pinch so it can scale relative to the gesture.
  double get currentZoom => camera.viewfinder.zoom;

  /// Sets an absolute zoom, clamped between "whole level visible" and a sane
  /// max zoom-in. Called continuously during a pinch gesture.
  void setZoom(double desiredZoom) {
    final base = _baseZoom();
    final z = desiredZoom.clamp(base * _minZoomFactor, base * _maxZoomFactor);
    camera.viewfinder.zoom = z;
    _zoomFactor = z / base;
    cameraController?.setViewportWorldSize(_viewportWorldSize());
  }

  /// Pans the camera by a world-space delta (one-finger drag on empty space).
  void panView(Vector2 worldDelta) => cameraController?.panBy(worldDelta);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _applyZoom();
  }

  void _focusOnSlingshot({bool snap = false}) {
    // At base zoom the level is fully visible, so the clamp keeps things
    // centred; when zoomed in this frames the launcher.
    cameraController?.follow(
      world.slingshot.pouch,
      snap: snap,
      lerp: GameConfig.cameraFollowLerp,
    );
  }

  // --- Turn flow -------------------------------------------------------------

  /// Called by the world when the player begins drawing back the slingshot.
  void onAimStart() {
    if (phase.value != GamePhase.aiming) return;
    cameraController?.follow(world.slingshot.pouch, lerp: 10);
  }

  /// Called by the world when a projectile is released.
  void onProjectileLaunched(Projectile projectile) {
    _activeProjectile = projectile;
    _shotsUsed++;
    shotsLeft.value = (shotsLeft.value - 1).clamp(0, level.shots);
    phase.value = GamePhase.simulating;
    _settleTimer = 0;
    _simTime = 0;
    AudioService.instance.launch();

    cameraController
      ?..follow(projectile.center, lerp: GameConfig.cameraFollowLerp)
      ..addTrauma(0.25);
  }

  void onProjectileImpact(Vector2 worldPos, double speed) {
    final intensity =
        (speed / PhysicsConfig.impactSpeedThreshold).clamp(0.4, 2.5);
    world.add(ParticleEffects.impactBurst(
      position: worldPos,
      color: const Color(0xFFFFE0B0),
      intensity: intensity,
    ));
    cameraController?.addTrauma(0.12 * intensity);
    if (speed > PhysicsConfig.impactSpeedThreshold) {
      AudioService.instance.impact();
    }
  }

  void onTargetHit(Vector2 worldPos) {
    world.add(ParticleEffects.impactBurst(
      position: worldPos,
      color: const Color(0xFFFFB07D),
      intensity: 0.8,
    ));
    cameraController?.addTrauma(0.2);
  }

  void onTargetDestroyed(Vector2 worldPos) {
    targetsLeft.value = (targetsLeft.value - 1).clamp(0, level.targetCount);
    world.add(ParticleEffects.impactBurst(
      position: worldPos,
      color: const Color(0xFFFF6B4A),
      intensity: 1.8,
    ));
    cameraController?.addTrauma(0.5);
    AudioService.instance.breakTarget();
  }

  /// Resolves a crate detonation: outward impulse on nearby bodies, destroys
  /// targets in the kill radius, and chain-detonates other crates in range.
  void onExplosion(Vector2 origin) {
    _explosionsThisRun++;
    AudioService.instance.explosion();

    // Big fiery burst + strong shake.
    world.add(ParticleEffects.impactBurst(
      position: origin,
      color: const Color(0xFFFFB03A),
      intensity: 3.0,
    ));
    world.add(ParticleEffects.impactBurst(
      position: origin,
      color: const Color(0xFFFF5A2A),
      intensity: 2.2,
    ));
    cameraController?.addTrauma(0.9);

    // Radial impulse on every dynamic body in range.
    final radius = PhysicsConfig.explosionRadius;
    for (final body in world.physicsWorld.bodies) {
      if (body.bodyType != BodyType.dynamic) continue;
      final delta = body.worldCenter - origin;
      final dist = delta.length;
      if (dist > radius || dist < 0.0001) continue;
      final falloff = 1 - (dist / radius);
      final dir = delta.normalized();
      body.applyLinearImpulse(
        dir * (PhysicsConfig.explosionImpulse * falloff * body.mass),
      );
      body.setAwake(true);
    }

    // Destroy targets within the kill radius.
    final killR = PhysicsConfig.explosionKillRadius;
    for (final target in List.of(world.targets)) {
      if (!target.isMounted) continue;
      if (target.body.worldCenter.distanceTo(origin) <= killR) {
        world.targets.remove(target);
        onTargetDestroyed(target.center.clone());
        target.removeFromParent();
      }
    }

    // Chain-react: detonate other armed crates within blast radius.
    for (final crate in List.of(world.explosives)) {
      if (!crate.isMounted || !crate.armed) continue;
      if (crate.center.distanceTo(origin) <= radius) {
        crate.detonate();
      }
    }
  }

  @override
  void update(double dt) {
    // Clamp long frames so a stall can't explode the simulation.
    final clamped =
        dt > PhysicsConfig.maxFrameDelta ? PhysicsConfig.maxFrameDelta : dt;
    super.update(clamped);

    if (phase.value == GamePhase.simulating && !_resolved) {
      _simTime += clamped;
      _cullOutOfBounds();
      _trackAndDetectSettle(clamped);
    }
  }

  void _trackAndDetectSettle(double dt) {
    // Keep the active projectile framed while it's still lively.
    final projectile = _activeProjectile;
    if (projectile != null && projectile.isMounted) {
      if (projectile.body.linearVelocity.length > 1.5) {
        cameraController?.follow(projectile.center);
      }
    }

    if (_sceneIsResting()) {
      _settleTimer += dt;
      if (_settleTimer >= PhysicsConfig.settleDuration) {
        _resolveTurn();
      }
    } else {
      _settleTimer = 0;
      // Safety net: never let a shot simulate forever (e.g. endless sliding).
      if (_simTime >= PhysicsConfig.maxSimDuration) {
        _resolveTurn();
      }
    }
  }

  bool _sceneIsResting() {
    for (final body in world.physicsWorld.bodies) {
      if (body.bodyType != BodyType.dynamic) continue;
      if (body.linearVelocity.length > PhysicsConfig.sleepLinearVelocity ||
          body.angularVelocity.abs() > PhysicsConfig.sleepAngularVelocity) {
        return false;
      }
    }
    return true;
  }

  /// Removes bodies that have left the play area. Without this a shot (or a
  /// knocked-away piece) that sails off the ground would free-fall forever and
  /// the scene would never come to rest — so the turn would never resolve.
  ///
  /// A target that leaves the level counts as destroyed (knocked out of play).
  void _cullOutOfBounds() {
    final w = level.worldSize;
    final m = PhysicsConfig.outOfBoundsMargin;

    // Only cull below the floor or far off the sides. Do NOT cull for being
    // high up — projectiles legitimately arc above the top of the level and
    // gravity brings them back.
    bool isOut(Vector2 p) => p.y > w.y + m || p.x < -m || p.x > w.x + m;

    // Targets first (so they score as destroyed).
    for (final target in List<Target>.from(world.targets)) {
      if (!target.isMounted) continue;
      if (isOut(target.body.position)) {
        world.targets.remove(target);
        onTargetDestroyed(target.center.clone());
        target.removeFromParent();
      }
    }

    // Any other dynamic body (projectile, obstacle) that fell away.
    for (final body in world.physicsWorld.bodies) {
      if (body.bodyType != BodyType.dynamic) continue;
      if (!isOut(body.position)) continue;
      final data = body.userData;
      if (data is Target) continue; // already handled above
      if (data is PhysicsPart && data.isMounted) {
        data.removeFromParent();
      }
    }
  }

  void _resolveTurn() {
    _settleTimer = 0;
    _simTime = 0;
    if (targetsLeft.value <= 0) {
      _finish(won: true);
    } else if (shotsLeft.value <= 0) {
      _finish(won: false);
    } else {
      // Next shot.
      phase.value = GamePhase.aiming;
      _activeProjectile?.markSpent();
      _activeProjectile = null;
      world.loadNextProjectile();
      _focusOnSlingshot();
    }
  }

  /// Revives a just-lost run by granting one more shot — used by the "Continue"
  /// rewarded-ad flow on the loss overlay. Only valid right after a loss (the
  /// scene is settled with targets remaining); a no-op otherwise.
  void grantExtraShot() {
    if (!_resolved || phase.value != GamePhase.lost) return;
    _resolved = false;
    _settleTimer = 0;
    _simTime = 0;
    shotsLeft.value += 1;
    phase.value = GamePhase.aiming;
    _activeProjectile?.markSpent();
    _activeProjectile = null;
    world.loadNextProjectile();
    _focusOnSlingshot();
  }

  void _finish({required bool won}) {
    if (_resolved) return;
    _resolved = true;
    phase.value = won ? GamePhase.won : GamePhase.lost;

    final stars = won ? level.starsForShots(_shotsUsed) : 0;
    if (won) {
      cameraController?.addTrauma(0.4);
      AudioService.instance.win();
    } else {
      AudioService.instance.fail();
    }
    onResolved(GameResult(
      won: won,
      stars: stars,
      shotsUsed: _shotsUsed,
      targetsRemaining: targetsLeft.value,
      targetsDestroyed: level.targetCount - targetsLeft.value,
      explosionsTriggered: _explosionsThisRun,
    ));
  }

  @override
  void onRemove() {
    shotsLeft.dispose();
    targetsLeft.dispose();
    phase.dispose();
    super.onRemove();
  }
}

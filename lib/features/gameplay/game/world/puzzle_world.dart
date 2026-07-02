import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../../../../core/config/physics_config.dart';
import '../../../levels/domain/level.dart';
import '../../../levels/domain/level_object.dart';
import '../components/explosive_crate.dart';
import '../components/ground.dart';
import '../components/obstacle.dart';
import '../components/projectile.dart';
import '../components/slingshot.dart';
import '../components/target.dart';
import '../components/trajectory_preview.dart';
import '../game_state.dart';
import '../puzzle_game.dart';

/// The Forge2D world for a level. Spawns bodies from the [Level] description
/// and translates touch gestures (received in world coordinates) into slingshot
/// aim/release, camera pan and pinch-zoom. Turn/scoring logic lives in
/// [PuzzleGame].
///
/// Input is handled entirely through [DragCallbacks], which is multi-touch:
/// Flame's `ImmediateMultiDragGestureRecognizer` delivers one independent drag
/// stream per finger (each tagged with a `pointerId`). We track the live
/// pointers ourselves so we can support:
///   - one finger starting on the ball  -> aim & throw
///   - one finger elsewhere             -> pan the camera
///   - two fingers                      -> pinch-zoom
///
/// (We deliberately don't use `ScaleCallbacks`: its dispatcher only produces
/// single-pointer data by piggy-backing on the drag dispatcher, and the drag
/// recognizer tends to win the gesture arena for multi-touch anyway — so we
/// derive the pinch straight from the two drag streams instead.)
class PuzzleWorld extends Forge2DWorld
    with HasGameReference<PuzzleGame>, DragCallbacks {
  PuzzleWorld({required this.level});

  final Level level;

  late final Slingshot slingshot;
  late final TrajectoryPreview trajectory;
  final List<Target> targets = [];
  final List<ExplosiveCrate> explosives = [];

  // Live pointers, keyed by pointerId. Device (screen) positions are used for
  // the pinch distance so changing the zoom doesn't feed back into the gesture;
  // world positions are used for aiming / panning.
  final Map<int, Vector2> _pointerDevice = {};
  final Map<int, Vector2> _pointerWorld = {};

  int? _aimPointer;
  int? _panPointer;

  bool _pinching = false;
  double _pinchStartDistance = 0;
  double _pinchStartZoom = 1;

  /// Spawns every static/dynamic body plus the slingshot + aim preview.
  Future<void> build() async {
    for (final spec in level.objects) {
      switch (spec.type) {
        case LevelObjectType.ground:
          add(Ground.fromSpec(spec));
        case LevelObjectType.obstacle:
          add(Obstacle.fromSpec(spec));
        case LevelObjectType.target:
          final target = Target.fromSpec(spec);
          targets.add(target);
          add(target);
        case LevelObjectType.explosive:
          final crate = ExplosiveCrate.fromSpec(spec);
          explosives.add(crate);
          add(crate);
        case LevelObjectType.unknown:
          break; // Forward-compatible: ignore unrecognised types.
      }
    }

    trajectory = TrajectoryPreview(gravity: gravity)..priority = 15;
    add(trajectory);

    slingshot = Slingshot(
      anchor: level.slingshotPosition.clone(),
      trajectory: trajectory,
    )..priority = 6;
    add(slingshot);
  }

  /// Spawns a fresh projectile and seats it in the slingshot pouch.
  Future<void> loadNextProjectile() async {
    final projectile = Projectile(position: slingshot.anchor.clone());
    // Await so the Forge2D body exists before the slingshot freezes it.
    await add(projectile);
    slingshot.loadProjectile(projectile);
  }

  // --- Input (multi-touch, all via drag streams) ----------------------------

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _pointerDevice[event.pointerId] = event.devicePosition.clone();
    _pointerWorld[event.pointerId] = event.localPosition.clone();

    // A second finger turns the gesture into a pinch-zoom.
    if (_pointerDevice.length >= 2) {
      _beginPinch();
      return;
    }

    // Single finger: grab the ball if the touch starts on/near the pouch while
    // it's the player's turn; otherwise this finger pans the camera.
    final canGrab = game.phase.value == GamePhase.aiming &&
        slingshot.hasProjectile &&
        event.localPosition.distanceTo(slingshot.pouch) <=
            PhysicsConfig.grabRadius;
    if (canGrab) {
      _aimPointer = event.pointerId;
      slingshot.startAim();
      slingshot.updateAim(event.localPosition);
      game.onAimStart();
    } else {
      _panPointer = event.pointerId;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _pointerDevice[event.pointerId] = event.deviceEndPosition.clone();
    _pointerWorld[event.pointerId] = event.localEndPosition.clone();

    if (_pinching) {
      _updatePinch();
      return;
    }
    if (event.pointerId == _aimPointer && slingshot.isAiming) {
      slingshot.updateAim(event.localEndPosition);
    } else if (event.pointerId == _panPointer) {
      game.panView(event.localDelta);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _endPointer(event.pointerId);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _endPointer(event.pointerId);
  }

  void _endPointer(int pointerId) {
    final wasPinching = _pinching;
    _pointerDevice.remove(pointerId);
    _pointerWorld.remove(pointerId);

    // Once fewer than two fingers remain, the pinch is over. We do not resume
    // aiming with the leftover finger to avoid an accidental launch.
    if (wasPinching && _pointerDevice.length < 2) {
      _pinching = false;
      _aimPointer = null;
      _panPointer = null;
    }

    if (pointerId == _aimPointer) {
      if (!wasPinching && slingshot.isAiming) {
        final launched = slingshot.release();
        if (launched != null) game.onProjectileLaunched(launched);
      }
      _aimPointer = null;
    }
    if (pointerId == _panPointer) _panPointer = null;
  }

  void _beginPinch() {
    _pinching = true;
    _aimPointer = null;
    _panPointer = null;
    slingshot.cancelAim(); // don't launch when the player meant to zoom
    final pts = _pointerDevice.values.toList();
    _pinchStartDistance = pts[0].distanceTo(pts[1]);
    _pinchStartZoom = game.currentZoom;
  }

  void _updatePinch() {
    final pts = _pointerDevice.values.toList();
    if (pts.length < 2 || _pinchStartDistance <= 0) return;
    final scale = pts[0].distanceTo(pts[1]) / _pinchStartDistance;
    game.setZoom(_pinchStartZoom * scale);
  }
}

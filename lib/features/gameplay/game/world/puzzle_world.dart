import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../../../levels/domain/level.dart';
import '../../../levels/domain/level_object.dart';
import '../components/ground.dart';
import '../components/obstacle.dart';
import '../components/projectile.dart';
import '../components/slingshot.dart';
import '../components/target.dart';
import '../components/trajectory_preview.dart';
import '../game_state.dart';
import '../puzzle_game.dart';

/// The Forge2D world for a level. Spawns bodies from the [Level] description
/// and translates drag gestures (received in world coordinates) into slingshot
/// aim/release calls. Turn/scoring logic lives in [PuzzleGame].
class PuzzleWorld extends Forge2DWorld
    with HasGameReference<PuzzleGame>, DragCallbacks {
  PuzzleWorld({required this.level});

  final Level level;

  late final Slingshot slingshot;
  late final TrajectoryPreview trajectory;
  final List<Target> targets = [];

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

  // --- Input ----------------------------------------------------------------

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (game.phase.value != GamePhase.aiming || !slingshot.hasProjectile) {
      return;
    }
    slingshot.startAim();
    slingshot.updateAim(event.localPosition);
    game.onAimStart();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!slingshot.isAiming) return;
    slingshot.updateAim(event.localEndPosition);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _completeAim();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _completeAim();
  }

  void _completeAim() {
    final launched = slingshot.release();
    if (launched != null) {
      game.onProjectileLaunched(launched);
    }
  }
}

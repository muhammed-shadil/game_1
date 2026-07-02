# Kinetix — a physics puzzle game

A polished 2D physics puzzle game built with **Flutter**, **Flame** and
**Forge2D (Box2D)**. Drag back the slingshot, read the trajectory arc, and
launch a "kinet" to destroy every glowing target within your shot budget.

> Status: **Increment 1 — playable vertical slice.** Core loop, architecture,
> camera, persistence and UI are in place. See _Roadmap_ for what's next.

## Running

```bash
flutter pub get
flutter run           # runs on the currently connected device / emulator
flutter analyze       # static analysis (currently clean)
flutter test          # domain unit tests
```

The game locks to **landscape**.

## Architecture

Clean, feature-first, modular. Dependencies point inward
(`presentation → application → domain`, with `data` implementing `domain`
interfaces). Riverpod provides DI + reactive state.

```
lib/
  app/                     # composition root: theme, router, MaterialApp
    theme/                 #   Material 3 palette + type scale
    router/                #   GoRouter routes + custom transitions
  core/                    # cross-cutting, feature-agnostic
    config/                #   PhysicsConfig / GameConfig — ALL tuning values
    services/              #   StorageService (Hive wrapper)
    utils/                 #   math helpers (smoothing, clamp, remap)
  features/
    home/presentation      # animated main menu
    levels/                # level model + JSON repository + providers + select UI
      domain/  data/  application/  presentation/
    gameplay/
      game/                # the Flame/Forge2D layer
        world/             #   PuzzleWorld — spawns bodies, routes drag input
        components/        #   Ground, Obstacle, Target, Projectile, Slingshot…
        camera/            #   GameCameraController — follow + clamp + shake
        effects/           #   particle bursts
        puzzle_game.dart   #   PuzzleGame — the referee (turn/scoring state)
      presentation/        #   GamePage, HUD, pause + result overlays
    progress/              # persisted stars/coins (domain + Riverpod notifier)
  shared/widgets/          # reusable UI (Pressable, GlassCard, StarRating…)
assets/levels/             # JSON level definitions + index.json manifest
```

### Key design decisions

- **Config-driven physics.** Gravity, material presets (density/friction/
  restitution), launch power, camera feel and settle thresholds all live in
  `core/config`. No magic numbers in gameplay code.
- **Levels are data, not code.** Every level is a JSON file loaded via a
  manifest (`assets/levels/index.json`). This is the exact contract a future
  visual **level editor** will read/write — no recompile to add content.
- **The game is the referee; the world is the stage.** `PuzzleGame` owns
  turn/score state and win-lose resolution and exposes it to Flutter via
  `ValueNotifier`s (HUD rebuilds without the engine knowing about widgets).
  `PuzzleWorld` only spawns bodies and forwards drag gestures.
- **Custom camera controller** instead of Flame's `FollowBehavior`, so easing,
  edge-clamping and trauma-based shake compose cleanly in one place.
- **Reactive progress** via a Riverpod `Notifier` persisted through Hive as
  JSON (no code-gen adapters, so the schema can evolve freely).

### Gameplay loop

1. `PuzzleGame.onLoad` fits the camera, builds the world from the `Level`, and
   seats a projectile in the slingshot.
2. A drag on the world (world-space coordinates) draws the pouch back; the
   `TrajectoryPreview` integrates the same ballistic equation the engine uses.
3. On release the slingshot applies a mass-scaled impulse; the camera follows
   the shot.
4. `PuzzleGame` watches body velocities; once the scene rests it resolves the
   turn — win (all targets destroyed), lose (shots exhausted), or load the next
   shot. Stars are awarded by shot efficiency.

## Accessibility

`GameConfig.reducedMotion` and `GameConfig.hapticsEnabled` are honoured across
particles, camera shake and button feedback. Colourblind-friendly accent
constants are defined in the palette. Landscape + tablet/desktop safe via a
responsive fit-zoom camera.

## Roadmap (next increments)

- **Mechanics:** ropes, hinges, springs, magnets, explosives, wind, water,
  balloons, pulleys (each maps to a new `LevelObjectType` + component).
- **Audio** service (music + SFX) behind a volume-controlled interface.
- **Meta:** achievements, daily challenge, skins, daily rewards / streak, XP.
- **Settings** screen wired to the existing accessibility flags + theme mode.
- **Visual level editor** producing the existing JSON format.
- **Firebase** leaderboard (architecture already isolates the repository).
```

import 'package:flame/extensions.dart';

/// Central tuning file for the Forge2D simulation.
///
/// Everything that affects how the world *feels* lives here so designers can
/// tune the game without hunting through component code. Values are expressed
/// in Forge2D units (meters, kilograms, seconds). The rendering scale is
/// controlled by [zoom] (pixels-per-meter at the default zoom level).
class PhysicsConfig {
  const PhysicsConfig._();

  /// World gravity. Positive Y points *down* in flame_forge2d's coordinate
  /// space, matching screen coordinates.
  static final Vector2 gravity = Vector2(0, 30.0);

  /// Base pixels-per-meter. The camera adjusts around this to fit a level.
  static const double zoom = 20.0;

  /// How many meters of the world we try to keep visible horizontally. The
  /// camera derives its zoom from this and the physical screen width.
  static const double targetVisibleWidth = 34.0;

  /// Fixed physics timestep clamp. Prevents the tunnelling / explosions that
  /// happen when a single frame is very long (e.g. app resumed from pause).
  static const double maxFrameDelta = 1 / 30;

  /// Global velocity threshold under which a body is considered "at rest".
  /// Used to detect when the shot has settled so we can evaluate win/lose.
  static const double sleepLinearVelocity = 0.35;
  static const double sleepAngularVelocity = 0.35;

  /// Seconds the whole scene must stay below the sleep thresholds before the
  /// turn is considered resolved.
  static const double settleDuration = 0.9;

  /// Hard cap on how long a single shot may simulate before the turn is
  /// force-resolved. Safety net for bodies that never come to rest (e.g. a
  /// piece sliding forever on ice, or a shot that keeps bouncing).
  static const double maxSimDuration = 6.5;

  /// A body whose center leaves the level by more than this margin (meters) is
  /// considered out of play and removed. Targets knocked out of bounds count as
  /// destroyed; anything else is just cleaned up so it can't stall the settle
  /// detector by free-falling forever.
  static const double outOfBoundsMargin = 10.0;

  // ---------------------------------------------------------------------------
  // Material presets — (density, friction, restitution).
  // Restitution == bounciness (0 = no bounce, 1 = perfectly elastic).
  // ---------------------------------------------------------------------------
  static const MaterialPreset projectile =
      MaterialPreset(density: 2.4, friction: 0.55, restitution: 0.18);
  static const MaterialPreset wood =
      MaterialPreset(density: 0.9, friction: 0.6, restitution: 0.08);
  static const MaterialPreset stone =
      MaterialPreset(density: 3.4, friction: 0.75, restitution: 0.04);
  static const MaterialPreset ice =
      MaterialPreset(density: 0.9, friction: 0.02, restitution: 0.05);
  static const MaterialPreset metal =
      MaterialPreset(density: 5.0, friction: 0.4, restitution: 0.12);
  static const MaterialPreset ground =
      MaterialPreset(density: 0.0, friction: 0.85, restitution: 0.0);
  static const MaterialPreset target =
      MaterialPreset(density: 0.7, friction: 0.5, restitution: 0.1);

  // ---------------------------------------------------------------------------
  // Slingshot launcher tuning.
  // ---------------------------------------------------------------------------

  /// Maximum drag distance (meters) from the anchor. Beyond this the pull is
  /// clamped, giving a consistent maximum power regardless of screen size.
  static const double maxPullDistance = 6.0;

  /// Converts pull distance into launch impulse. Higher = more powerful shots.
  static const double launchPower = 9.5;

  /// Impact speed above which a collision counts as "hard" (spawns particles,
  /// shakes the camera, can destroy fragile targets).
  static const double impactSpeedThreshold = 8.0;

  /// Linear/angular damping applied to the projectile in flight for a slightly
  /// weighty, controllable arc (as opposed to a frictionless point mass).
  static const double projectileLinearDamping = 0.02;
  static const double projectileAngularDamping = 0.04;
}

/// Immutable bundle of the three fixture properties that define a material.
class MaterialPreset {
  const MaterialPreset({
    required this.density,
    required this.friction,
    required this.restitution,
  });

  final double density;
  final double friction;
  final double restitution;
}

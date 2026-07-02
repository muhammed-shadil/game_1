import 'dart:ui' as ui;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/physics_config.dart';
import '../../../levels/domain/level_object.dart';
import '../puzzle_game.dart';

/// Visual skin (two-stop gradient + accent) for a material.
class MaterialSkin {
  const MaterialSkin(this.bottom, this.top, {this.stroke, this.opacity = 1});
  final Color bottom;
  final Color top;
  final Color? stroke;
  final double opacity;
}

/// Base class for every rendered rigid body in the puzzle. Handles body
/// creation from a [LevelObject]-style description plus a premium flat-with-
/// depth render (soft shadow, vertical gradient, top highlight, rounded edges).
///
/// Subclasses override behaviour (e.g. destructible targets) but inherit look.
abstract class PhysicsPart extends BodyComponent<PuzzleGame> {
  PhysicsPart({
    required this.spawnPosition,
    required this.shape,
    required this.halfSize,
    required this.bodyType,
    required this.material,
    required this.skin,
    this.spawnAngle = 0,
    this.isSensor = false,
    this.bullet = false,
    super.priority,
  }) : super(renderBody: false);

  final Vector2 spawnPosition;
  final LevelShape shape;

  /// Half-extents for a box; for a circle, halfSize.x is the radius.
  final Vector2 halfSize;
  final BodyType bodyType;
  final MaterialPreset material;
  final MaterialSkin skin;
  final double spawnAngle;
  final bool isSensor;

  /// Enables continuous collision detection (prevents fast bodies tunnelling
  /// through thin walls). Only worth it for the projectile.
  final bool bullet;

  double get shapeRadius => halfSize.x;

  /// Corner rounding in meters, proportional but capped so big blocks don't
  /// look like pills.
  double get _cornerRadius {
    final minSide = 2 * (halfSize.x < halfSize.y ? halfSize.x : halfSize.y);
    final r = minSide * 0.18;
    return r > 0.5 ? 0.5 : r;
  }

  @override
  Body createBody() {
    final def = BodyDef(
      type: bodyType,
      position: spawnPosition,
      angle: spawnAngle,
      userData: this,
      bullet: bullet,
      linearDamping: bodyType == BodyType.dynamic ? 0.03 : 0,
      angularDamping: bodyType == BodyType.dynamic ? 0.04 : 0,
    );
    final newBody = world.createBody(def);

    final Shape fixtureShape;
    if (shape == LevelShape.circle) {
      fixtureShape = CircleShape()..radius = shapeRadius;
    } else {
      fixtureShape = PolygonShape()..setAsBoxXY(halfSize.x, halfSize.y);
    }

    newBody.createFixture(
      FixtureDef(
        fixtureShape,
        density: material.density,
        friction: material.friction,
        restitution: material.restitution,
        isSensor: isSensor,
      ),
    );
    return newBody;
  }

  // --- Rendering -------------------------------------------------------------
  // The canvas is already translated to the body centre and rotated by the
  // body angle (see BodyComponent.renderTree), so we draw around the origin.

  @override
  void render(Canvas canvas) {
    if (shape == LevelShape.circle) {
      _renderCircleSkin(canvas);
    } else {
      _renderBoxSkin(canvas);
    }
  }

  void _renderBoxSkin(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: halfSize.x * 2,
      height: halfSize.y * 2,
    );
    final rrect =
        RRect.fromRectAndRadius(rect, Radius.circular(_cornerRadius));

    // Soft drop shadow.
    final shadow = RRect.fromRectAndRadius(
      rect.shift(const Offset(0.12, 0.18)),
      Radius.circular(_cornerRadius),
    );
    canvas.drawRRect(
      shadow,
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.22),
    );

    // Body gradient.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          [
            skin.top.withValues(alpha: skin.opacity),
            skin.bottom.withValues(alpha: skin.opacity),
          ],
        ),
    );

    // Top highlight line for a subtle lit edge.
    final hlInset = _cornerRadius * 0.6;
    canvas.drawLine(
      Offset(rect.left + hlInset, rect.top + 0.12),
      Offset(rect.right - hlInset, rect.top + 0.12),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28 * skin.opacity)
        ..strokeWidth = 0.08
        ..strokeCap = StrokeCap.round,
    );

    // Crisp outline.
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.06
        ..color = (skin.stroke ?? skin.bottom)
            .withValues(alpha: 0.55 * skin.opacity),
    );
  }

  void _renderCircleSkin(Canvas canvas) {
    final r = shapeRadius;

    canvas.drawCircle(
      const Offset(0.12, 0.18),
      r,
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.22),
    );

    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(-r * 0.3, -r * 0.35),
          r * 1.5,
          [
            skin.top.withValues(alpha: skin.opacity),
            skin.bottom.withValues(alpha: skin.opacity),
          ],
        ),
    );

    // Specular highlight.
    canvas.drawCircle(
      Offset(-r * 0.32, -r * 0.34),
      r * 0.24,
      Paint()..color = Colors.white.withValues(alpha: 0.35 * skin.opacity),
    );

    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.06
        ..color = (skin.stroke ?? skin.bottom)
            .withValues(alpha: 0.55 * skin.opacity),
    );
  }
}

/// Registry mapping level materials to their physics preset + visual skin.
class MaterialLibrary {
  const MaterialLibrary._();

  static MaterialPreset preset(LevelMaterial m) => switch (m) {
        LevelMaterial.wood => PhysicsConfig.wood,
        LevelMaterial.stone => PhysicsConfig.stone,
        LevelMaterial.ice => PhysicsConfig.ice,
        LevelMaterial.metal => PhysicsConfig.metal,
        LevelMaterial.target => PhysicsConfig.target,
        LevelMaterial.ground => PhysicsConfig.ground,
      };

  static MaterialSkin skin(LevelMaterial m) => switch (m) {
        LevelMaterial.wood => const MaterialSkin(
            Color(0xFF9E6B3B),
            Color(0xFFC9924F),
            stroke: Color(0xFF6F4A28),
          ),
        LevelMaterial.stone => const MaterialSkin(
            Color(0xFF6B7488),
            Color(0xFF9BA6BC),
            stroke: Color(0xFF4B5266),
          ),
        LevelMaterial.ice => const MaterialSkin(
            Color(0xFF7FC6EC),
            Color(0xFFD6F2FF),
            stroke: Color(0xFF9FDDF5),
            opacity: 0.82,
          ),
        LevelMaterial.metal => const MaterialSkin(
            Color(0xFF7C8598),
            Color(0xFFC2CBDD),
            stroke: Color(0xFF565E70),
          ),
        LevelMaterial.target => const MaterialSkin(
            Color(0xFFFF6B4A),
            Color(0xFFFFB07D),
            stroke: Color(0xFFD8452A),
          ),
        LevelMaterial.ground => const MaterialSkin(
            Color(0xFF2F6B44),
            Color(0xFF4C9A63),
            stroke: Color(0xFF245033),
          ),
      };
}

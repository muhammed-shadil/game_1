import 'dart:ui' as ui;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../../../levels/domain/level_object.dart';
import 'physics_part.dart';

/// Static terrain. Rendered with a grassy lit top edge over a darker soil body
/// for a bit of depth, instead of the generic rounded block.
class Ground extends PhysicsPart {
  Ground.fromSpec(LevelObject spec)
      : super(
          spawnPosition: spec.position.clone(),
          shape: LevelShape.box,
          halfSize: spec.size / 2,
          bodyType: BodyType.static,
          material: MaterialLibrary.preset(LevelMaterial.ground),
          skin: MaterialLibrary.skin(LevelMaterial.ground),
          spawnAngle: spec.angle,
          priority: 2,
        );

  static const Color _soilTop = Color(0xFF6B4A2F);
  static const Color _soilBottom = Color(0xFF4A3220);
  static const Color _grass = Color(0xFF5FB878);

  @override
  void render(Canvas canvas) {
    final w = halfSize.x * 2;
    final h = halfSize.y * 2;
    final rect =
        Rect.fromCenter(center: Offset.zero, width: w, height: h);

    // Soil body.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          const [_soilTop, _soilBottom],
        ),
    );

    // Grass cap along the top surface.
    final grassRect = Rect.fromLTWH(rect.left, rect.top, w, h * 0.16);
    canvas.drawRect(grassRect, Paint()..color = _grass);
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.top),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = 0.08,
    );
  }
}

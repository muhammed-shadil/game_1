import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/game_config.dart';

/// Factory for one-shot particle bursts. Each returns a self-removing
/// [ParticleSystemComponent] the world can add at a point of impact.
class ParticleEffects {
  const ParticleEffects._();

  static final math.Random _rng = math.Random();

  /// A radial spray of debris that arcs under gravity — used for hits and
  /// destruction. [intensity] scales speed + count for bigger impacts.
  static Component impactBurst({
    required Vector2 position,
    required Color color,
    double intensity = 1,
  }) {
    final count = GameConfig.reducedMotion
        ? 6
        : (10 + (intensity * 8)).clamp(6, 30).toInt();

    return ParticleSystemComponent(
      position: position.clone(),
      priority: 20,
      particle: Particle.generate(
        count: count,
        lifespan: 0.55 + _rng.nextDouble() * 0.25,
        generator: (i) {
          final angle = _rng.nextDouble() * math.pi * 2;
          final speed = (1.6 + _rng.nextDouble() * 4.2) * intensity;
          final velocity = Vector2(math.cos(angle), math.sin(angle)) * speed
            ..y -= _rng.nextDouble() * 2.2; // bias upward for a lively pop
          return AcceleratedParticle(
            speed: velocity,
            acceleration: Vector2(0, 14),
            child: CircleParticle(
              radius: 0.1 + _rng.nextDouble() * 0.2,
              paint: Paint()
                ..color = color.withValues(
                  alpha: 0.7 + _rng.nextDouble() * 0.3,
                ),
            ),
          );
        },
      ),
    );
  }

  /// A quick soft dust puff, e.g. when a body settles onto the ground.
  static Component dustPuff({
    required Vector2 position,
    Color color = const Color(0xFFCFC3A8),
  }) {
    return ParticleSystemComponent(
      position: position.clone(),
      priority: 18,
      particle: Particle.generate(
        count: GameConfig.reducedMotion ? 4 : 8,
        lifespan: 0.5,
        generator: (i) {
          final angle = -math.pi / 2 + (_rng.nextDouble() - 0.5) * 1.4;
          final speed = 1.0 + _rng.nextDouble() * 1.6;
          return AcceleratedParticle(
            speed: Vector2(math.cos(angle), math.sin(angle)) * speed,
            acceleration: Vector2(0, 3),
            child: CircleParticle(
              radius: 0.16 + _rng.nextDouble() * 0.18,
              paint: Paint()..color = color.withValues(alpha: 0.5),
            ),
          );
        },
      ),
    );
  }
}

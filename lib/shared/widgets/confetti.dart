import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/config/game_config.dart';

/// A self-contained confetti burst for celebratory moments (e.g. a level win).
///
/// Pure Flutter + a single [AnimationController] — no packages. Pieces fall
/// from the top with gravity, drift, and spin, fading out near the end. Honors
/// the reduced-motion setting (renders nothing when enabled).
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.pieces = 90,
    this.duration = const Duration(milliseconds: 2600),
  });

  final int pieces;
  final Duration duration;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Confetto> _confetti;

  static const _palette = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.tertiary,
    AppColors.success,
    AppColors.warning,
    AppColors.star,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final rng = math.Random();
    _confetti = List.generate(widget.pieces, (i) {
      return _Confetto(
        nx: rng.nextDouble(),
        ny0: -0.1 - rng.nextDouble() * 0.4,
        vy: 0.5 + rng.nextDouble() * 0.7,
        vx: (rng.nextDouble() - 0.5) * 0.5,
        size: 6 + rng.nextDouble() * 8,
        rotation: rng.nextDouble() * math.pi,
        rotationSpeed: (rng.nextDouble() - 0.5) * 8,
        color: _palette[rng.nextInt(_palette.length)],
        wobble: rng.nextDouble() * math.pi * 2,
      );
    });
    if (!GameConfig.reducedMotion) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (GameConfig.reducedMotion) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_confetti, _controller.value),
        ),
      ),
    );
  }
}

class _Confetto {
  _Confetto({
    required this.nx,
    required this.ny0,
    required this.vy,
    required this.vx,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.wobble,
  });

  final double nx; // normalized start x (0..1)
  final double ny0; // normalized start y (fractions of height, negative = above)
  final double vy; // fall speed (fractions of height / progress)
  final double vx; // horizontal drift
  final double size;
  final double rotation;
  final double rotationSpeed;
  final Color color;
  final double wobble;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.confetti, this.t);

  final List<_Confetto> confetti;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final c in confetti) {
      final y = (c.ny0 + c.vy * t) * size.height;
      if (y > size.height + 20) continue;
      // Gentle horizontal wobble + drift.
      final x = (c.nx + c.vx * t) * size.width +
          math.sin(c.wobble + t * 6) * 10;

      final fade = t < 0.8 ? 1.0 : (1 - (t - 0.8) / 0.2).clamp(0.0, 1.0);
      paint.color = c.color.withValues(alpha: fade);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(c.rotation + c.rotationSpeed * t);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: c.size, height: c.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

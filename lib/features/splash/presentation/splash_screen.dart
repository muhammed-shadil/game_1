import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/config/game_config.dart';
import '../../../shared/widgets/gradient_scaffold.dart';

/// Branded launch screen. A glowing "kinet" orb pops in inside an orbiting ring
/// of trajectory dots (echoing the in-game aim preview), the wordmark reveals,
/// then it auto-advances to the home menu.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // One-shot intro (orb pop + wordmark reveal). Its completion routes home.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: GameConfig.reducedMotion
        ? const Duration(milliseconds: 900)
        : const Duration(milliseconds: 2400),
  );

  // Continuous ring rotation. Paused entirely under reduced-motion.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    if (!GameConfig.reducedMotion) _spin.repeat();
    _intro
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          context.goNamed(Routes.home);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Staged sub-curves off the single intro timeline.
    final orbPop = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    );
    final titleReveal = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.45, 0.8, curve: Curves.easeOutCubic),
    );
    final taglineReveal = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.6, 0.95, curve: Curves.easeOut),
    );

    return GradientScaffold(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Emblem: orbiting ring + glowing orb ---
            SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _spin,
                    builder: (context, _) => CustomPaint(
                      size: const Size.square(190),
                      painter: _OrbitDotsPainter(
                        rotation: _spin.value * 2 * math.pi,
                      ),
                    ),
                  ),
                  ScaleTransition(
                    scale: Tween(begin: 0.0, end: 1.0).animate(orbPop),
                    child: const _KinetOrb(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // --- Wordmark ---
            FadeTransition(
              opacity: titleReveal,
              child: ScaleTransition(
                scale: Tween(begin: 0.9, end: 1.0).animate(titleReveal),
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [AppColors.primary, AppColors.tertiary],
                  ).createShader(rect),
                  child: Text(
                    GameConfig.appName,
                    style: AppTextStyles.display.copyWith(
                      color: Colors.white,
                      fontSize: 58,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            FadeTransition(
              opacity: taglineReveal,
              child: Text(
                GameConfig.tagline,
                style: AppTextStyles.title.copyWith(
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // --- Subtle loading pulse ---
            FadeTransition(
              opacity: taglineReveal,
              child: const _LoadingDots(),
            ),
          ],
        ),
      ),
    );
  }
}

/// The glowing periwinkle sphere — the game's projectile, used as the logo.
class _KinetOrb extends StatelessWidget {
  const _KinetOrb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.4),
          radius: 1.1,
          colors: [Color(0xFF9FB2FF), Color(0xFF3B4FD8)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.6),
            blurRadius: 44,
            spreadRadius: 4,
          ),
        ],
        border: Border.all(color: const Color(0xFFB9C6FF), width: 1.5),
      ),
      child: Align(
        alignment: const Alignment(-0.4, -0.45),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

/// Draws a ring of fading dots that reads as a spinning trajectory arc,
/// mirroring the dotted aim preview in gameplay.
class _OrbitDotsPainter extends CustomPainter {
  const _OrbitDotsPainter({required this.rotation});

  final double rotation;

  static const int _count = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    for (var i = 0; i < _count; i++) {
      final progress = i / _count;
      final angle = rotation + progress * 2 * math.pi;
      final offset = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      // Comet-style fade so the ring looks like it's travelling.
      final alpha = (0.12 + progress * 0.7).clamp(0.0, 1.0);
      final dotRadius = 1.4 + progress * 2.6;
      final color = Color.lerp(AppColors.tertiary, AppColors.primary, progress)!
          .withValues(alpha: alpha);
      canvas.drawCircle(offset, dotRadius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_OrbitDotsPainter old) => old.rotation != rotation;
}

/// Three softly pulsing dots as a lightweight "loading" cue.
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = (_c.value + i * 0.2) % 1.0;
          final scale = 0.6 + 0.4 * math.sin(phase * math.pi).abs();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.35 + 0.4 * scale),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

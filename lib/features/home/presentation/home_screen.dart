import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/config/game_config.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/pressable.dart';
import '../../progress/application/progress_providers.dart';

/// Animated main menu. Title breathes, buttons stagger in, coins are shown in a
/// glass chip. Play routes to level select.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(progressProvider).coins;
    final totalStars = ref.watch(progressProvider).totalStars;

    return GradientScaffold(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(coins: coins, stars: totalStars),
            const Spacer(),
            const _AnimatedTitle(),
            const SizedBox(height: 40),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    _EntranceItem(
                      delayMs: 120,
                      child: _PrimaryPlayButton(
                        onTap: () => context.pushNamed(Routes.levels),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _EntranceItem(
                      delayMs: 220,
                      child: Row(
                        children: [
                          Expanded(
                            child: _SecondaryButton(
                              icon: Icons.grid_view_rounded,
                              label: 'Levels',
                              onTap: () => context.pushNamed(Routes.levels),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SecondaryButton(
                              icon: Icons.settings_rounded,
                              label: 'Settings',
                              onTap: () => _showComingSoon(context, 'Settings'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Text(
              '${GameConfig.appName} · v1.0',
              textAlign: TextAlign.center,
              style: AppTextStyles.label
                  .copyWith(color: Colors.white.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — coming soon')),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.coins, required this.stars});
  final int coins;
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _StatChip(icon: Icons.star_rounded, color: AppColors.star, value: stars),
        const SizedBox(width: 10),
        _StatChip(
            icon: Icons.monetization_on_rounded,
            color: AppColors.warning,
            value: coins),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.icon, required this.color, required this.value});
  final IconData icon;
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      radius: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          // Animated counter for a bit of polish.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: GameConfig.slow,
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              v.round().toString(),
              style: AppTextStyles.counter.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedTitle extends StatefulWidget {
  const _AnimatedTitle();

  @override
  State<_AnimatedTitle> createState() => _AnimatedTitleState();
}

class _AnimatedTitleState extends State<_AnimatedTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScaleTransition(
          scale: Tween(begin: 0.98, end: 1.02).animate(
            CurvedAnimation(parent: _c, curve: Curves.easeInOut),
          ),
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [AppColors.primary, AppColors.tertiary],
            ).createShader(rect),
            child: Text(
              GameConfig.appName,
              textAlign: TextAlign.center,
              style: AppTextStyles.display.copyWith(
                color: Colors.white,
                fontSize: 64,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          GameConfig.tagline,
          textAlign: TextAlign.center,
          style: AppTextStyles.title
              .copyWith(color: Colors.white.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}

class _PrimaryPlayButton extends StatelessWidget {
  const _PrimaryPlayButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: 'Play',
      onPressed: onTap,
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 30),
              const SizedBox(width: 8),
              Text('PLAY',
                  style: AppTextStyles.button
                      .copyWith(color: Colors.white, fontSize: 22)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: label,
      onPressed: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        radius: 18,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: AppTextStyles.button.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// Slides + fades a child up on first build for a staggered entrance.
class _EntranceItem extends StatelessWidget {
  const _EntranceItem({required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: GameConfig.slow,
      curve: Interval(
        (delayMs / 800).clamp(0, 1),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, (1 - v) * 24), child: child),
      ),
      child: child,
    );
  }
}

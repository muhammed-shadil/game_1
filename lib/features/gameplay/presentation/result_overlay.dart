import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/config/game_config.dart';
import '../../../shared/widgets/confetti.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/star_rating.dart';

/// Victory / failure dialog. Blurs the frozen game behind it, springs a card in
/// and reveals earned stars. Used for both outcomes via [won].
class ResultOverlay extends StatelessWidget {
  const ResultOverlay({
    super.key,
    required this.won,
    required this.stars,
    required this.coinsEarned,
    required this.onRetry,
    required this.onHome,
    this.onNext,
  });

  final bool won;
  final int stars;
  final int coinsEarned;
  final VoidCallback onRetry;
  final VoidCallback onHome;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: GameConfig.medium,
      curve: Curves.easeOut,
      builder: (context, t, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12 * t, sigmaY: 12 * t),
              child: Container(color: Colors.black.withValues(alpha: 0.45 * t)),
            ),
            // Celebratory confetti behind the card (wins only).
            if (won) const Positioned.fill(child: ConfettiBurst()),
            // Centre when it fits; scroll when the screen is too short
            // (small landscape phones) so content is never clipped.
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Transform.scale(
                        scale: 0.85 + 0.15 * t,
                        child: Opacity(opacity: t.clamp(0, 1), child: child),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: _Card(
        won: won,
        stars: stars,
        coinsEarned: coinsEarned,
        onRetry: onRetry,
        onHome: onHome,
        onNext: onNext,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.won,
    required this.stars,
    required this.coinsEarned,
    required this.onRetry,
    required this.onHome,
    required this.onNext,
  });

  final bool won;
  final int stars;
  final int coinsEarned;
  final VoidCallback onRetry;
  final VoidCallback onHome;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final accent = won ? AppColors.success : AppColors.danger;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkAlt,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.3),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 650),
              curve: Curves.elasticOut,
              builder: (context, v, child) => Transform.scale(
                scale: GameConfig.reducedMotion ? 1.0 : v.clamp(0.0, 1.3),
                child: child,
              ),
              child: _ResultEmblem(won: won),
            ),
            const SizedBox(height: 12),
            Text(
              won ? 'Level Complete!' : 'Out of Shots',
              style: AppTextStyles.headline.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            if (won) ...[
              StarRating(stars: stars, size: 38, animate: true, spacing: 6),
              const SizedBox(height: 12),
              _CoinReward(coins: coinsEarned),
            ] else
              Text(
                'So close — give it another go.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body
                    .copyWith(color: Colors.white.withValues(alpha: 0.7)),
              ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _OverlayButton(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    onTap: onHome,
                    filled: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OverlayButton(
                    icon: Icons.refresh_rounded,
                    label: 'Retry',
                    onTap: onRetry,
                    filled: !won || onNext == null,
                  ),
                ),
                if (won && onNext != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OverlayButton(
                      icon: Icons.arrow_forward_rounded,
                      label: 'Next',
                      onTap: onNext!,
                      filled: true,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Outcome medallion: a gradient-filled emblem with a soft glow. A gold trophy
/// (with sparkles) for a win; a warm "aim again" bullseye for a loss — more
/// inviting than a frowny face and on-theme for a slingshot game.
class _ResultEmblem extends StatelessWidget {
  const _ResultEmblem({required this.won});

  final bool won;

  @override
  Widget build(BuildContext context) {
    final gradient = won
        ? const [AppColors.star, AppColors.warning]
        : const [AppColors.secondary, AppColors.danger];
    final glow = won ? AppColors.warning : AppColors.danger;
    final icon = won ? Icons.emoji_events_rounded : Icons.adjust_rounded;

    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Medallion.
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  gradient.first.withValues(alpha: 0.28),
                  gradient.last.withValues(alpha: 0.10),
                ],
              ),
              border: Border.all(color: gradient.first.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: 0.45),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
            // Gradient-filled icon for a richer, less flat look.
            child: ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ).createShader(rect),
              child: Icon(icon, color: Colors.white, size: 48),
            ),
          ),
          // Sparkles for a win.
          if (won && !GameConfig.reducedMotion) ...[
            Positioned(
              top: 2,
              right: 8,
              child: Icon(Icons.auto_awesome,
                  color: AppColors.star.withValues(alpha: 0.95), size: 20),
            ),
            Positioned(
              bottom: 6,
              left: 4,
              child: Icon(Icons.auto_awesome,
                  color: AppColors.star.withValues(alpha: 0.7), size: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _CoinReward extends StatelessWidget {
  const _CoinReward({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    if (coins <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.monetization_on_rounded,
            color: AppColors.warning, size: 22),
        const SizedBox(width: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: coins.toDouble()),
          duration: GameConfig.slow,
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Text(
            '+${v.round()}',
            style: AppTextStyles.counter.copyWith(color: AppColors.warning),
          ),
        ),
      ],
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.filled,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: label,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: filled
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDeep])
              : null,
          color: filled ? null : Colors.white.withValues(alpha: 0.08),
          border: filled
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: AppTextStyles.label.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

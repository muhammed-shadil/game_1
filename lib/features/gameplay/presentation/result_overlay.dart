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
    this.coinsDoubled = false,
    this.onDoubleCoins,
    this.onContinueWithAd,
  });

  final bool won;
  final int stars;
  final int coinsEarned;
  final VoidCallback onRetry;
  final VoidCallback onHome;
  final VoidCallback? onNext;

  /// True once the win coins have been doubled via a rewarded ad — hides the
  /// "double" button and reflects the boosted total.
  final bool coinsDoubled;

  /// Rewarded-ad hook on a win: doubles [coinsEarned]. Null hides the button
  /// (no ad ready / ads unavailable). The parent presents the ad and awards.
  final VoidCallback? onDoubleCoins;

  /// Rewarded-ad hook on a loss: watch an ad to get one more shot and resume.
  /// The parent presents the ad, grants the shot and dismisses this overlay.
  final VoidCallback? onContinueWithAd;

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
        coinsDoubled: coinsDoubled,
        onDoubleCoins: onDoubleCoins,
        onContinueWithAd: onContinueWithAd,
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
    required this.coinsDoubled,
    required this.onDoubleCoins,
    required this.onContinueWithAd,
  });

  final bool won;
  final int stars;
  final int coinsEarned;
  final VoidCallback onRetry;
  final VoidCallback onHome;
  final VoidCallback? onNext;
  final bool coinsDoubled;
  final VoidCallback? onDoubleCoins;
  final VoidCallback? onContinueWithAd;

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
              // Rewarded ad: watch to double the coins just earned.
              if (onDoubleCoins != null && !coinsDoubled && coinsEarned > 0) ...[
                const SizedBox(height: 16),
                _RewardAdButton(
                  icon: Icons.monetization_on_rounded,
                  label: 'Double Coins',
                  accent: AppColors.warning,
                  onTap: onDoubleCoins!,
                ),
              ],
            ] else ...[
              Text(
                'So close — give it another go.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body
                    .copyWith(color: Colors.white.withValues(alpha: 0.7)),
              ),
              // Rewarded ad: watch to earn one more shot and continue this run.
              if (onContinueWithAd != null) ...[
                const SizedBox(height: 18),
                _RewardAdButton(
                  icon: Icons.sports_baseball_rounded,
                  label: 'Continue  •  +1 Shot',
                  accent: AppColors.success,
                  onTap: onContinueWithAd!,
                ),
              ],
            ],
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

/// A rewarded-ad call-to-action: a bright gradient pill with a small "Ad" chip
/// so it reads as an optional bonus, never a forced interruption.
class _RewardAdButton extends StatelessWidget {
  const _RewardAdButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: label,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [
            accent.withValues(alpha: 0.85),
            accent.withValues(alpha: 0.55),
          ]),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            // Tiny "Ad" badge — sets the expectation that a video will play.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 14),
                  Text('Ad',
                      style: AppTextStyles.label.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
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

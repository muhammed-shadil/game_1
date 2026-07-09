import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/ad_service.dart';
import '../../../shared/widgets/confetti.dart';
import '../../../shared/widgets/pressable.dart';
import '../../progress/application/progress_providers.dart';
import '../application/daily_providers.dart';

/// Shows the daily-reward dialog. Displays a 7-day streak track and lets the
/// player claim today's coins (once per day).
Future<void> showDailyRewardDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(24),
      child: _DailyRewardCard(),
    ),
  );
}

class _DailyRewardCard extends ConsumerStatefulWidget {
  const _DailyRewardCard();

  @override
  ConsumerState<_DailyRewardCard> createState() => _DailyRewardCardState();
}

class _DailyRewardCardState extends ConsumerState<_DailyRewardCard> {
  bool _claimedNow = false;
  int _reward = 0;
  bool _doubled = false;
  bool _adBusy = false;

  /// Rewarded ad: watch to double today's claimed reward (once).
  Future<void> _watchAdToDouble() async {
    if (_adBusy || _doubled || _reward <= 0) return;
    _adBusy = true;
    final earned = await AdService.instance.showRewarded();
    if (!mounted) {
      _adBusy = false;
      return;
    }
    if (earned) {
      await ref.read(progressProvider.notifier).awardCoins(_reward);
      if (!mounted) return;
      setState(() {
        _reward *= 2;
        _doubled = true;
      });
    }
    _adBusy = false;
  }

  @override
  Widget build(BuildContext context) {
    final daily = ref.read(dailyProvider.notifier);
    final dailyState = ref.watch(dailyProvider);
    final canClaim = daily.canClaim && !_claimedNow;
    final streak = _claimedNow ? dailyState.streak : daily.pendingStreak;

    return Stack(
      children: [
        if (_claimedNow) const Positioned.fill(child: ConfettiBurst()),
        Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceDarkAlt,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.star.withValues(alpha: 0.4)),
          ),
          // Scrollable so the card shrink-wraps its content but never overflows
          // on short landscape screens (the extra rewarded-ad button can push
          // the fixed layout past the available height otherwise).
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.star,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Daily Reward',
                  style: AppTextStyles.headline.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  _claimedNow
                      ? 'Come back tomorrow!'
                      : (canClaim
                            ? 'Day $streak — claim your coins!'
                            : 'Already claimed today'),
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 18),
                _StreakTrack(currentStreak: streak, notifier: daily),
                const SizedBox(height: 22),
                if (_claimedNow)
                  _RewardBadge(coins: _reward)
                else
                  Pressable(
                    semanticLabel: 'Claim',
                    onPressed: canClaim
                        ? () async {
                            final r = await daily.claim();
                            if (!context.mounted) return;
                            setState(() {
                              _claimedNow = true;
                              _reward = r;
                            });
                          }
                        : () => Navigator.of(context).pop(),
                    child: _ActionButton(
                      label: canClaim ? 'Claim Reward' : 'Close',
                      filled: canClaim,
                    ),
                  ),
                if (_claimedNow) ...[
                  // Rewarded ad: watch to double today's reward (once). Only
                  // offered when an ad is actually ready to show.
                  if (!_doubled && AdService.instance.isRewardedReady) ...[
                    const SizedBox(height: 12),
                    Pressable(
                      semanticLabel: 'Double reward',
                      onPressed: _watchAdToDouble,
                      child: const _ActionButton(
                        label: 'Double Reward  ▶ Ad',
                        filled: false,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Pressable(
                    semanticLabel: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    child: const _ActionButton(label: 'Awesome!', filled: true),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StreakTrack extends StatelessWidget {
  const _StreakTrack({required this.currentStreak, required this.notifier});
  final int currentStreak;
  final DailyNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (i) {
        final day = i + 1;
        final reached = day <= currentStreak;
        final reward = notifier.rewardForStreak(day);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          width: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: reached
                ? AppColors.star.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: reached
                  ? AppColors.star
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            children: [
              Text(
                'D$day',
                style: AppTextStyles.label.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Icon(
                Icons.monetization_on_rounded,
                color: reached ? AppColors.warning : Colors.white24,
                size: 16,
              ),
              Text(
                '$reward',
                style: AppTextStyles.label.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.monetization_on_rounded,
          color: AppColors.warning,
          size: 26,
        ),
        const SizedBox(width: 6),
        Text(
          '+$coins',
          style: AppTextStyles.display.copyWith(
            color: AppColors.warning,
            fontSize: 34,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.filled});
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: filled
            ? const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDeep],
              )
            : null,
        color: filled ? null : Colors.white.withValues(alpha: 0.08),
      ),
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

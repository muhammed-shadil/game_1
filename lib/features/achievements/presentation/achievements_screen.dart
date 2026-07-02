import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/pressable.dart';
import '../application/achievements_providers.dart';
import '../domain/achievement.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementsProvider);
    final unlockedCount = state.unlockedCount;

    return GradientScaffold(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Pressable(
                  semanticLabel: 'Back',
                  onPressed: () => context.pop(),
                  child: GlassCard(
                    padding: const EdgeInsets.all(10),
                    radius: 14,
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Text('Achievements',
                    style:
                        AppTextStyles.headline.copyWith(color: Colors.white)),
                const Spacer(),
                Text('$unlockedCount / ${kAchievements.length}',
                    style: AppTextStyles.counter
                        .copyWith(color: AppColors.star)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: kAchievements.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final a = kAchievements[i];
                  return _AchievementTile(
                    achievement: a,
                    unlocked: state.unlocked.contains(a.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.unlocked});
  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Opacity(
        opacity: unlocked ? 1 : 0.55,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: unlocked
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.tertiary])
                    : null,
                color: unlocked ? null : Colors.white.withValues(alpha: 0.08),
              ),
              child: Icon(
                unlocked ? achievement.icon : Icons.lock_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(achievement.title,
                      style: AppTextStyles.title
                          .copyWith(color: Colors.white, fontSize: 16)),
                  Text(achievement.description,
                      style: AppTextStyles.label.copyWith(
                          color: Colors.white.withValues(alpha: 0.6))),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: AppColors.warning, size: 18),
                const SizedBox(width: 4),
                Text('${achievement.coinReward}',
                    style: AppTextStyles.label.copyWith(
                        color: unlocked ? AppColors.warning : Colors.white54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

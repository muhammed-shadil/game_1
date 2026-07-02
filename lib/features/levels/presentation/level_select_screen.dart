import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/star_rating.dart';
import '../../progress/application/progress_providers.dart';
import '../application/level_providers.dart';
import '../domain/level.dart';

/// Grid of levels with unlock gating + per-level star ratings.
class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(levelsProvider);

    return GradientScaffold(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onBack: () => context.pop()),
            const SizedBox(height: 12),
            Expanded(
              child: levelsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Failed to load levels:\n$e',
                      textAlign: TextAlign.center),
                ),
                data: (levels) => _LevelGrid(levels: levels),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Pressable(
          semanticLabel: 'Back',
          onPressed: onBack,
          child: GlassCard(
            padding: const EdgeInsets.all(10),
            radius: 14,
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        const SizedBox(width: 16),
        Text('Select Level',
            style: AppTextStyles.headline.copyWith(color: Colors.white)),
      ],
    );
  }
}

class _LevelGrid extends ConsumerWidget {
  const _LevelGrid({required this.levels});
  final List<Level> levels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild when progress changes (unlocks / new stars).
    ref.watch(progressProvider);
    final notifier = ref.read(progressProvider.notifier);
    final orderedIds = levels.map((l) => l.id).toList();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisExtent: 150,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: levels.length,
      itemBuilder: (context, i) {
        final level = levels[i];
        final progress = ref.watch(progressProvider).forLevel(level.id);
        final unlocked = notifier.isUnlocked(level.id, orderedIds);
        return _LevelCard(
          level: level,
          stars: progress?.stars ?? 0,
          unlocked: unlocked,
          onTap: unlocked
              ? () => context.pushNamed(
                    Routes.play,
                    pathParameters: {'id': level.id},
                  )
              : null,
        );
      },
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.onTap,
  });

  final Level level;
  final int stars;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onTap,
      semanticLabel: 'Level ${level.index}: ${level.name}',
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDeep],
                    ),
                  ),
                  child: Center(
                    child: Text('${level.index}',
                        style: AppTextStyles.title
                            .copyWith(color: Colors.white)),
                  ),
                ),
                if (!unlocked)
                  const Icon(Icons.lock_rounded, color: Colors.white54)
                else
                  StarRating(stars: stars, size: 18),
              ],
            ),
            const Spacer(),
            Text(
              level.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title.copyWith(
                color: Colors.white.withValues(alpha: unlocked ? 1 : 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              level.difficulty.label,
              style: AppTextStyles.label
                  .copyWith(color: Colors.white.withValues(alpha: 0.55)),
            ),
          ],
        ),
      ),
    );
  }
}

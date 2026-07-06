import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/storage_service.dart';
import '../../gameplay/game/game_state.dart';
import '../../levels/application/level_providers.dart';
import '../../progress/application/progress_providers.dart';
import '../domain/achievement.dart';

/// Persisted achievement state: which are unlocked + cumulative counters that
/// aren't derivable from level progress.
class AchievementsState {
  const AchievementsState({
    this.unlocked = const {},
    this.totalExplosions = 0,
    this.totalTargets = 0,
  });

  final Set<String> unlocked;
  final int totalExplosions;
  final int totalTargets;

  int get unlockedCount => unlocked.length;

  AchievementsState copyWith({
    Set<String>? unlocked,
    int? totalExplosions,
    int? totalTargets,
  }) =>
      AchievementsState(
        unlocked: unlocked ?? this.unlocked,
        totalExplosions: totalExplosions ?? this.totalExplosions,
        totalTargets: totalTargets ?? this.totalTargets,
      );
}

final achievementsProvider =
    NotifierProvider<AchievementsNotifier, AchievementsState>(
        AchievementsNotifier.new);

class AchievementsNotifier extends Notifier<AchievementsState> {
  static const _key = '__achievements__';

  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  AchievementsState build() {
    final raw = _storage.readMap(_key);
    return AchievementsState(
      unlocked: ((raw['unlocked'] as List?)?.cast<String>() ?? const [])
          .toSet(),
      totalExplosions: (raw['totalExplosions'] as num?)?.toInt() ?? 0,
      totalTargets: (raw['totalTargets'] as num?)?.toInt() ?? 0,
    );
  }

  /// Call after a level resolves (and after progress has been recorded). Updates
  /// counters, unlocks any newly-earned achievements and pays out their coins.
  /// Returns the list of achievements unlocked by this run (for UI feedback).
  Future<List<Achievement>> recordRun(GameResult result) async {
    final totalExplosions = state.totalExplosions + result.explosionsTriggered;
    final totalTargets = state.totalTargets + result.targetsDestroyed;

    final progress = ref.read(progressProvider);
    final completed =
        progress.progress.values.where((p) => p.completed).length;
    final threeStars =
        progress.progress.values.where((p) => p.stars >= 3).length;
    final totalLevels =
        ref.read(levelsProvider).asData?.value.length ?? completed;

    final ctx = AchievementContext(
      won: result.won,
      shotsUsed: result.shotsUsed,
      stars: result.stars,
      completedLevels: completed,
      threeStarLevels: threeStars,
      totalExplosions: totalExplosions,
      totalTargets: totalTargets,
      totalLevels: totalLevels,
    );

    final unlocked = Set<String>.from(state.unlocked);
    final newly = <Achievement>[];
    var coins = 0;
    for (final a in kAchievements) {
      if (!unlocked.contains(a.id) && a.isUnlocked(ctx)) {
        unlocked.add(a.id);
        newly.add(a);
        coins += a.coinReward;
      }
    }

    state = state.copyWith(
      unlocked: unlocked,
      totalExplosions: totalExplosions,
      totalTargets: totalTargets,
    );
    await _persist();

    if (coins > 0) {
      await ref.read(progressProvider.notifier).awardCoins(coins);
    }
    return newly;
  }

  Future<void> _persist() => _storage.writeMap(_key, {
        'unlocked': state.unlocked.toList(),
        'totalExplosions': state.totalExplosions,
        'totalTargets': state.totalTargets,
      });
}

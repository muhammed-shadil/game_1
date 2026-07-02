import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/game_config.dart';
import '../../../core/services/storage_service.dart';
import '../domain/level_progress.dart';

/// Injected at app bootstrap via a [ProviderScope] override once Hive is ready.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError(
    'storageServiceProvider must be overridden in main() with an initialized '
    'StorageService instance.',
  );
});

/// Reactive player profile (coins + per-level progress), persisted to disk.
final progressProvider =
    NotifierProvider<ProgressNotifier, PlayerProfile>(ProgressNotifier.new);

class ProgressNotifier extends Notifier<PlayerProfile> {
  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  PlayerProfile build() {
    final records = _storage.readAllLevelRecords();
    final progress = <String, LevelProgress>{
      for (final entry in records.entries)
        entry.key: LevelProgress.fromJson(entry.value),
    };
    return PlayerProfile(coins: _storage.readCoins(), progress: progress);
  }

  /// Records a completed run, awarding coins for *newly earned* stars and
  /// keeping the best result. No-op for a worse or equal result.
  Future<void> recordCompletion({
    required String levelId,
    required int stars,
    required int shotsUsed,
  }) async {
    final previous =
        state.forLevel(levelId) ?? LevelProgress(levelId: levelId);
    final updated = previous.merge(
      stars: stars,
      bestShots: shotsUsed,
      completed: true,
    );

    // Award coins only for the delta in stars, so replaying can't farm coins.
    final gainedStars = (updated.stars - previous.stars).clamp(0, 3);
    final newCoins = state.coins + gainedStars * GameConfig.coinsPerStar;

    final newProgress =
        Map<String, LevelProgress>.from(state.progress)..[levelId] = updated;
    state = state.copyWith(coins: newCoins, progress: newProgress);

    await _storage.writeLevelRecord(levelId, updated.toJson());
    await _storage.writeCoins(newCoins);
  }

  /// A level is unlocked if it's the first, or the previous one is completed.
  bool isUnlocked(String levelId, List<String> orderedIds) {
    final idx = orderedIds.indexOf(levelId);
    if (idx <= 0) return true;
    final prev = state.forLevel(orderedIds[idx - 1]);
    return prev?.completed ?? false;
  }

  Future<void> resetAll() async {
    await _storage.clearAll();
    state = const PlayerProfile();
  }
}

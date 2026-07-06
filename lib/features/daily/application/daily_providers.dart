import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/storage_service.dart';
import '../../progress/application/progress_providers.dart';

/// Persisted daily-reward state: the day of the last claim + the current login
/// streak.
class DailyState {
  const DailyState({this.lastClaimYmd, this.streak = 0});

  final String? lastClaimYmd;
  final int streak;

  DailyState copyWith({String? lastClaimYmd, int? streak}) => DailyState(
        lastClaimYmd: lastClaimYmd ?? this.lastClaimYmd,
        streak: streak ?? this.streak,
      );
}

final dailyProvider =
    NotifierProvider<DailyNotifier, DailyState>(DailyNotifier.new);

class DailyNotifier extends Notifier<DailyState> {
  static const _key = '__daily__';
  static const int baseReward = 20;
  static const int perDayBonus = 10;
  static const int maxStreakForReward = 7;

  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  DailyState build() {
    final raw = _storage.readMap(_key);
    return DailyState(
      lastClaimYmd: raw['lastClaimYmd'] as String?,
      streak: (raw['streak'] as num?)?.toInt() ?? 0,
    );
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// True if the reward hasn't been claimed today yet.
  bool get canClaim => state.lastClaimYmd != _ymd(DateTime.now());

  /// The streak the player *would* reach by claiming now.
  int get pendingStreak {
    final today = DateTime.now();
    final yesterday = _ymd(today.subtract(const Duration(days: 1)));
    return state.lastClaimYmd == yesterday ? state.streak + 1 : 1;
  }

  int rewardForStreak(int streak) =>
      baseReward + streak.clamp(1, maxStreakForReward) * perDayBonus;

  /// Claims today's reward (once per calendar day). Returns coins awarded, or 0
  /// if already claimed today.
  Future<int> claim() async {
    if (!canClaim) return 0;
    final today = DateTime.now();
    final newStreak = pendingStreak;
    final reward = rewardForStreak(newStreak);

    state = DailyState(lastClaimYmd: _ymd(today), streak: newStreak);
    await _storage.writeMap(_key, {
      'lastClaimYmd': state.lastClaimYmd,
      'streak': state.streak,
    });
    await ref.read(progressProvider.notifier).awardCoins(reward);
    return reward;
  }
}

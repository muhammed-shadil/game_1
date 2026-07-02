import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/level_repository.dart';
import '../domain/level.dart';

/// Provides the level repository. Swap the concrete implementation here (e.g.
/// for a remote/Firebase-backed source) without touching consumers.
final levelRepositoryProvider = Provider<LevelRepository>((ref) {
  return AssetLevelRepository();
});

/// All levels, sorted by [Level.index]. Cached by the repository.
final levelsProvider = FutureProvider<List<Level>>((ref) {
  return ref.watch(levelRepositoryProvider).loadAll();
});

/// A single level by id, resolved from the loaded set.
final levelByIdProvider = FutureProvider.family<Level, String>((ref, id) async {
  final levels = await ref.watch(levelsProvider.future);
  return levels.firstWhere(
    (l) => l.id == id,
    orElse: () => throw StateError('Level "$id" not found'),
  );
});

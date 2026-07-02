import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/level.dart';
import 'level_generator.dart';

/// Loads level definitions from bundled JSON assets.
///
/// The indirection through an `index.json` manifest means new levels can be
/// added (by an editor or by hand) without recompiling: drop a `<id>.json` in
/// `assets/levels/` and add its filename to the manifest.
abstract interface class LevelRepository {
  Future<List<Level>> loadAll();
  Future<Level> loadById(String id);
}

class AssetLevelRepository implements LevelRepository {
  AssetLevelRepository({this.basePath = 'assets/levels', this.totalLevels = 50});

  final String basePath;

  /// Total number of playable levels. Hand-authored levels come from JSON; the
  /// remainder are procedurally generated so the game offers many stages.
  final int totalLevels;

  /// Simple in-memory cache; levels are immutable so this is safe.
  List<Level>? _cache;

  @override
  Future<List<Level>> loadAll() async {
    if (_cache != null) return _cache!;

    final manifestRaw = await rootBundle.loadString('$basePath/index.json');
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    final files = (manifest['levels'] as List).cast<String>();

    final levels = <Level>[];
    for (final file in files) {
      final raw = await rootBundle.loadString('$basePath/$file');
      levels.add(Level.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    }

    // Fill up to [totalLevels] with generated stages after the authored ones.
    final authoredMax =
        levels.fold(0, (m, l) => l.index > m ? l.index : m);
    if (authoredMax < totalLevels) {
      levels.addAll(LevelGenerator.generateRange(authoredMax + 1, totalLevels));
    }

    levels.sort((a, b) => a.index.compareTo(b.index));
    return _cache = List.unmodifiable(levels);
  }

  @override
  Future<Level> loadById(String id) async {
    final all = await loadAll();
    return all.firstWhere(
      (l) => l.id == id,
      orElse: () => throw StateError('Level "$id" not found'),
    );
  }
}

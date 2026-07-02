import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/level.dart';

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
  AssetLevelRepository({this.basePath = 'assets/levels'});

  final String basePath;

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

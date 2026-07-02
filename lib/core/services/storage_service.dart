import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../config/game_config.dart';

/// Thin persistence layer over Hive.
///
/// We store JSON strings rather than registering TypeAdapters so the schema can
/// evolve freely (and to avoid code-generation in this layer). Higher layers
/// deal in domain objects; this class only knows primitives.
class StorageService {
  StorageService(this._box);

  final Box<String> _box;

  static const String _coinsKey = '__coins__';
  static const String _settingsKey = '__settings__';
  static const String _levelPrefix = 'level:';

  /// Opens Hive and the progress box. Call once during app bootstrap.
  static Future<StorageService> initialize() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>(GameConfig.progressBoxName);
    return StorageService(box);
  }

  int readCoins() {
    final raw = _box.get(_coinsKey);
    return raw == null ? 0 : int.tryParse(raw) ?? 0;
  }

  Future<void> writeCoins(int coins) =>
      _box.put(_coinsKey, coins.toString());

  /// Reads persisted app settings as a raw map (empty if never saved).
  Map<String, dynamic> readSettings() {
    final raw = _box.get(_settingsKey);
    return raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> writeSettings(Map<String, dynamic> settings) =>
      _box.put(_settingsKey, jsonEncode(settings));

  /// Returns every persisted level record as raw maps, keyed by levelId.
  Map<String, Map<String, dynamic>> readAllLevelRecords() {
    final result = <String, Map<String, dynamic>>{};
    for (final key in _box.keys) {
      if (key is String && key.startsWith(_levelPrefix)) {
        final raw = _box.get(key);
        if (raw == null) continue;
        final id = key.substring(_levelPrefix.length);
        result[id] = jsonDecode(raw) as Map<String, dynamic>;
      }
    }
    return result;
  }

  Future<void> writeLevelRecord(String levelId, Map<String, dynamic> record) =>
      _box.put('$_levelPrefix$levelId', jsonEncode(record));

  Future<void> clearAll() => _box.clear();
}

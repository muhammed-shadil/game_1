import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/game_config.dart';
import '../../../core/services/audio_service.dart';
import '../../progress/application/progress_providers.dart';
import '../domain/app_settings.dart';

/// Reactive, persisted user settings. Also mirrors the feel flags into
/// [GameConfig] (which the game engine reads) whenever they change.
final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final raw = ref.read(storageServiceProvider).readSettings();
    final settings =
        raw.isEmpty ? const AppSettings() : AppSettings.fromJson(raw);
    _applyToGameConfig(settings);
    return settings;
  }

  void _applyToGameConfig(AppSettings s) {
    GameConfig.hapticsEnabled = s.haptics;
    GameConfig.reducedMotion = s.reducedMotion;
    GameConfig.soundEnabled = s.soundEnabled;
  }

  Future<void> _update(AppSettings next) async {
    state = next;
    _applyToGameConfig(next);
    await ref.read(storageServiceProvider).writeSettings(next.toJson());
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> setHaptics(bool value) =>
      _update(state.copyWith(haptics: value));

  Future<void> setReducedMotion(bool value) =>
      _update(state.copyWith(reducedMotion: value));

  Future<void> setSoundEnabled(bool value) async {
    await _update(state.copyWith(soundEnabled: value));
    AudioService.instance.onSoundEnabledChanged(value);
  }
}

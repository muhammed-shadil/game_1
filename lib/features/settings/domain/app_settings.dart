import 'package:flutter/material.dart' show ThemeMode;

/// Immutable user preferences. Persisted as JSON and applied to the app
/// (theme) and to the game feel flags in `GameConfig`.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.haptics = true,
    this.reducedMotion = false,
    this.soundEnabled = true,
  });

  final ThemeMode themeMode;
  final bool haptics;

  /// Minimises cosmetic animations (camera shake, particles, button springs).
  final bool reducedMotion;

  /// Kept for the (architecture-ready) audio layer; toggled here so the UI is
  /// complete even before sound is wired up.
  final bool soundEnabled;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? haptics,
    bool? reducedMotion,
    bool? soundEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      haptics: haptics ?? this.haptics,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'haptics': haptics,
        'reducedMotion': reducedMotion,
        'soundEnabled': soundEnabled,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: ThemeMode.values.firstWhere(
          (m) => m.name == json['themeMode'],
          orElse: () => ThemeMode.dark,
        ),
        haptics: json['haptics'] as bool? ?? true,
        reducedMotion: json['reducedMotion'] as bool? ?? false,
        soundEnabled: json['soundEnabled'] as bool? ?? true,
      );
}

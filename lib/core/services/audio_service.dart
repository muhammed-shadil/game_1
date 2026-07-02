import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

import '../config/game_config.dart';

/// Central sound manager. A singleton (not a widget-tree provider) because the
/// Flame game — which lives outside the widget tree — needs to trigger SFX.
///
/// Every call is fail-safe: audio problems on a device/emulator must never
/// interrupt gameplay, so failures are swallowed. Playback is gated by
/// [GameConfig.soundEnabled], which the settings layer keeps in sync.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  static const _sfx = <String>[
    'tap.wav',
    'launch.wav',
    'impact.wav',
    'break.wav',
    'explosion.wav',
    'win.wav',
    'fail.wav',
  ];
  static const _music = 'music.wav';

  bool _ready = false;
  bool _musicPlaying = false;

  Future<void> init() async {
    try {
      await FlameAudio.audioCache.loadAll([..._sfx, _music]);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  bool get _on => GameConfig.soundEnabled;

  Future<void> _guard(Future<Object?> Function() action) async {
    if (!_ready || !_on) return;
    try {
      await action();
    } catch (_) {/* ignore audio failures */}
  }

  void _play(String file, {double volume = 1}) =>
      unawaited(_guard(() => FlameAudio.play(file, volume: volume)));

  // SFX ----------------------------------------------------------------------
  void tap() => _play('tap.wav', volume: 0.5);
  void launch() => _play('launch.wav', volume: 0.8);
  void impact() => _play('impact.wav', volume: 0.7);
  void breakTarget() => _play('break.wav', volume: 0.8);
  void explosion() => _play('explosion.wav', volume: 0.9);
  void win() => _play('win.wav', volume: 0.9);
  void fail() => _play('fail.wav', volume: 0.8);

  // Music --------------------------------------------------------------------
  void startMusic() {
    if (!_ready || !_on || _musicPlaying) return;
    _musicPlaying = true;
    unawaited(_guard(() => FlameAudio.bgm.play(_music, volume: 0.35)));
  }

  void stopMusic() {
    _musicPlaying = false;
    unawaited(_guard(() => FlameAudio.bgm.stop()));
  }

  /// Called when the sound setting changes.
  void onSoundEnabledChanged(bool enabled) {
    if (enabled) {
      startMusic();
    } else {
      _musicPlaying = false;
      // Pause without the _on gate (which is now false).
      if (_ready) {
        unawaited(FlameAudio.bgm.pause().catchError((_) {}));
      }
    }
  }
}

import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

import '../config/game_config.dart';

/// Central sound manager. A singleton (not a widget-tree provider) because the
/// Flame game — which lives outside the widget tree — needs to trigger SFX.
///
/// Every call is fail-safe: audio problems on a device/emulator must never
/// interrupt gameplay, so failures are swallowed. Playback is gated by
/// [GameConfig.soundEnabled], which the settings layer keeps in sync.
///
/// ## Why pools instead of [FlameAudio.play]
///
/// `FlameAudio.play` allocates a *brand-new* [AudioPlayer] — a native
/// `MediaPlayer` on Android — on every single call. During a physics scene,
/// impacts/breaks/explosions fire SFX in rapid bursts, so that churns the
/// native audio system (constant `setMode`/`setSpeakerphoneOn`, decoder
/// setup) which stutters the game, and leaks native handles until Android
/// hits its concurrent-player limit and kills the app. An [AudioPool]
/// pre-warms a small fixed set of players per sound and recycles them, so no
/// per-shot allocation ever happens. This is how games with fast, repetitive
/// SFX are expected to use flame_audio.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  /// SFX file -> max simultaneous players kept in its pool. Sounds that can
  /// overlap (impacts during a collapse, chained explosions) get a few
  /// players; one-shot outcome stingers only need one.
  static const Map<String, int> _sfx = <String, int>{
    'tap.wav': 2,
    'launch.wav': 2,
    'impact.wav': 4,
    'break.wav': 4,
    'explosion.wav': 3,
    'win.wav': 1,
    'fail.wav': 1,
  };
  static const _music = 'music.wav';

  final Map<String, AudioPool> _pools = {};
  bool _ready = false;
  bool _musicPlaying = false;

  Future<void> init() async {
    try {
      // Music streams through the shared bgm player (a single reused player),
      // so it just needs to be in the cache — no pool. initialize() registers
      // the bgm as a lifecycle observer so it auto-pauses when the app is
      // backgrounded and resumes on return (frees the player + audio focus).
      await FlameAudio.bgm.initialize();
      await FlameAudio.audioCache.load(_music);

      // Pre-create one reusable pool per SFX. minPlayers: 1 warms a player up
      // front so the first shot has no allocation latency.
      for (final entry in _sfx.entries) {
        _pools[entry.key] = await FlameAudio.createPool(
          entry.key,
          minPlayers: 1,
          maxPlayers: entry.value,
        );
      }
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  bool get _on => GameConfig.soundEnabled;

  void _play(String file, {double volume = 1}) {
    if (!_ready || !_on) return;
    final pool = _pools[file];
    if (pool == null) return;
    // Fire-and-forget: reuse a pooled player. Swallow any playback error so an
    // audio hiccup can never interrupt gameplay.
    unawaited(pool.start(volume: volume).then((_) {}, onError: (_) {}));
  }

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
    unawaited(
      FlameAudio.bgm.play(_music, volume: 0.35).catchError((_) {}),
    );
  }

  void stopMusic() {
    _musicPlaying = false;
    if (!_ready) return;
    unawaited(FlameAudio.bgm.stop().catchError((_) {}));
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

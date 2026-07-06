// Synthesizes the game's sound effects + a seamless music loop as 16-bit PCM
// WAV files. Run once with:  dart run tool/gen_audio.dart
//
// These are procedurally generated placeholders — clean and functional — that
// can be swapped for professionally produced audio later without code changes.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int sr = 44100;

void main() {
  final dir = Directory('assets/audio');
  dir.createSync(recursive: true);

  _write('tap.wav', _tap());
  _write('launch.wav', _launch());
  _write('impact.wav', _impact());
  _write('break.wav', _break());
  _write('explosion.wav', _explosion());
  _write('win.wav', _win());
  _write('fail.wav', _fail());
  _write('music.wav', _music());
  stdout.writeln('Audio generated in ${dir.path}');
}

// --- Synths ------------------------------------------------------------------

List<double> _tap() {
  return _render(0.07, (t, d) {
    final env = math.exp(-t * 45);
    return 0.5 * env * math.sin(2 * math.pi * 1150 * t);
  });
}

List<double> _launch() {
  // Rising whoosh: swept tone + airy noise.
  final rng = math.Random(1);
  return _render(0.28, (t, d) {
    final p = t / d;
    final freq = 320 + 700 * p;
    final env = math.sin(math.pi * p); // fade in/out
    final tone = 0.35 * math.sin(2 * math.pi * freq * t);
    final noise = 0.15 * (rng.nextDouble() * 2 - 1) * (1 - p);
    return env * (tone + noise);
  });
}

List<double> _impact() {
  final rng = math.Random(2);
  return _render(0.16, (t, d) {
    final env = math.exp(-t * 26);
    final thud = 0.6 * math.sin(2 * math.pi * 150 * t);
    final click = 0.2 * (rng.nextDouble() * 2 - 1) * math.exp(-t * 80);
    return env * (thud + click);
  });
}

List<double> _break() {
  final rng = math.Random(3);
  return _render(0.18, (t, d) {
    final env = math.exp(-t * 22);
    final noise = (rng.nextDouble() * 2 - 1);
    final ping = 0.3 * math.sin(2 * math.pi * 900 * t);
    return 0.5 * env * (noise * 0.7 + ping);
  });
}

List<double> _explosion() {
  final rng = math.Random(4);
  return _render(0.6, (t, d) {
    final env = math.exp(-t * 6.5);
    final rumble = 0.5 * math.sin(2 * math.pi * 55 * t);
    final noise = 0.6 * (rng.nextDouble() * 2 - 1);
    return (0.75 * env * (rumble + noise)).clamp(-1.0, 1.0);
  });
}

List<double> _win() {
  // Bright ascending arpeggio C5 E5 G5 C6.
  final notes = [523.25, 659.25, 783.99, 1046.5];
  return _sequence(notes, 0.13, (t, dur) {
    final env = math.sin(math.pi * (t / dur)) * math.exp(-t * 2.5);
    return env;
  });
}

List<double> _fail() {
  // Two descending notes.
  final notes = [392.0, 261.63];
  return _sequence(notes, 0.22, (t, dur) => math.exp(-t * 5));
}

/// A seamless 8-second ambient pad. Integer frequencies over an integer number
/// of seconds start and end at zero phase, so the loop has no click.
List<double> _music() {
  const dur = 8.0;
  final chord = [110, 165, 220, 330]; // A2 E3 A3 E4-ish
  return _render(dur, (t, d) {
    var s = 0.0;
    for (final f in chord) {
      s += math.sin(2 * math.pi * f * t);
    }
    s /= chord.length;
    // Slow tremolo, 2 full cycles across the loop (seamless).
    final trem = 0.75 + 0.25 * math.sin(2 * math.pi * (2 / dur) * t);
    return 0.28 * s * trem;
  });
}

// --- Helpers -----------------------------------------------------------------

/// Renders a mono buffer of [seconds] using [fn](t, duration) -> sample.
List<double> _render(double seconds, double Function(double t, double d) fn) {
  final n = (seconds * sr).round();
  final out = List<double>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    out[i] = fn(i / sr, seconds);
  }
  return out;
}

/// Concatenates [notes], each held for [each] seconds, shaped by [env](t,dur).
List<double> _sequence(
    List<double> notes, double each, double Function(double t, double dur) env) {
  final out = <double>[];
  for (final f in notes) {
    final n = (each * sr).round();
    for (var i = 0; i < n; i++) {
      final t = i / sr;
      out.add(0.4 * env(t, each) * math.sin(2 * math.pi * f * t));
    }
  }
  return out;
}

void _write(String name, List<double> samples) {
  final n = samples.length;
  final bytes = ByteData(44 + n * 2);
  void s(int off, String v) {
    for (var i = 0; i < v.length; i++) {
      bytes.setUint8(off + i, v.codeUnitAt(i));
    }
  }

  final dataSize = n * 2;
  s(0, 'RIFF');
  bytes.setUint32(4, 36 + dataSize, Endian.little);
  s(8, 'WAVE');
  s(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little); // PCM
  bytes.setUint16(22, 1, Endian.little); // mono
  bytes.setUint32(24, sr, Endian.little);
  bytes.setUint32(28, sr * 2, Endian.little); // byte rate
  bytes.setUint16(32, 2, Endian.little); // block align
  bytes.setUint16(34, 16, Endian.little); // bits
  s(36, 'data');
  bytes.setUint32(40, dataSize, Endian.little);
  for (var i = 0; i < n; i++) {
    final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    bytes.setInt16(44 + i * 2, v, Endian.little);
  }
  File('assets/audio/$name').writeAsBytesSync(bytes.buffer.asUint8List());
}

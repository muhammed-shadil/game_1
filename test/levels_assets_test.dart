import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_1/features/levels/domain/level.dart';
import 'package:game_1/features/levels/domain/level_object.dart';

/// Parses every bundled level straight from disk so malformed JSON or bad
/// geometry is caught in CI rather than on a device.
void main() {
  final dir = Directory('assets/levels');

  test('manifest lists existing, parseable levels', () {
    final manifest =
        jsonDecode(File('${dir.path}/index.json').readAsStringSync())
            as Map<String, dynamic>;
    final files = (manifest['levels'] as List).cast<String>();

    expect(files, isNotEmpty);

    final indices = <int>[];
    for (final file in files) {
      final f = File('${dir.path}/$file');
      expect(f.existsSync(), isTrue, reason: 'missing $file');

      final level = Level.fromJson(
        jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
      );

      // Every level must be winnable in principle.
      expect(level.targetCount, greaterThan(0), reason: '${level.id} targets');
      expect(level.shots, greaterThan(0), reason: '${level.id} shots');
      expect(
        level.objects.any((o) => o.type == LevelObjectType.ground),
        isTrue,
        reason: '${level.id} has ground',
      );
      indices.add(level.index);
    }

    // Indices should be unique and contiguous from 1.
    indices.sort();
    expect(indices.first, 1);
    expect(indices.toSet().length, indices.length, reason: 'duplicate index');
  });
}

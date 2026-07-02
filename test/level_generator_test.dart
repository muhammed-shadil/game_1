import 'package:flutter_test/flutter_test.dart';
import 'package:game_1/features/levels/data/level_generator.dart';
import 'package:game_1/features/levels/domain/level_object.dart';

void main() {
  test('generated levels 16..50 are well-formed and winnable-by-construction',
      () {
    final levels = LevelGenerator.generateRange(16, 50);
    expect(levels.length, 35);

    for (final l in levels) {
      expect(l.index, inInclusiveRange(16, 50));
      expect(l.targetCount, greaterThan(0), reason: '${l.id} has targets');
      expect(l.shots, greaterThanOrEqualTo(3), reason: '${l.id} shots');
      expect(
        l.objects.any((o) => o.type == LevelObjectType.ground),
        isTrue,
        reason: '${l.id} has ground',
      );
      // Enough shots to clear if a chunk of targets are hit per shot.
      expect(l.shots, greaterThanOrEqualTo((l.targetCount / 3).ceil()));
    }

    // Deterministic: same index -> identical layout.
    final a = LevelGenerator.generate(30);
    final b = LevelGenerator.generate(30);
    expect(a.objects.length, b.objects.length);
    expect(a.name, b.name);
  });
}

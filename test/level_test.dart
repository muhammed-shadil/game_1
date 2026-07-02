import 'package:flutter_test/flutter_test.dart';
import 'package:game_1/features/levels/domain/level.dart';
import 'package:game_1/features/levels/domain/level_object.dart';

void main() {
  group('Level parsing', () {
    test('parses a minimal level and derives defaults', () {
      final level = Level.fromJson({
        'id': 'demo',
        'name': 'Demo',
        'index': 1,
        'shots': 3,
        'worldSize': [60, 34],
        'slingshot': [9, 26],
        'objects': [
          {
            'type': 'target',
            'shape': 'box',
            'material': 'target',
            'position': [40, 28],
            'size': [2, 4],
          },
        ],
        'starThresholds': {'twoStar': 2, 'threeStar': 1},
      });

      expect(level.id, 'demo');
      expect(level.targetCount, 1);
      expect(level.objects.single.type, LevelObjectType.target);
      expect(level.worldSize.x, 60);
    });
  });

  group('Star scoring', () {
    final level = Level.fromJson({
      'id': 'demo',
      'name': 'Demo',
      'index': 1,
      'shots': 3,
      'starThresholds': {'twoStar': 2, 'threeStar': 1},
      'objects': const [],
    });

    test('fewer shots earns more stars', () {
      expect(level.starsForShots(1), 3);
      expect(level.starsForShots(2), 2);
      expect(level.starsForShots(3), 1);
    });
  });
}

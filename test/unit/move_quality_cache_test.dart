import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/game/presentation/providers/move_quality_cache.dart';
import 'package:tavli/features/game/domain/engine/move_quality.dart';

void main() {
  group('MoveQualityCache', () {
    test('returns null on miss', () {
      final cache = MoveQualityCache();
      expect(
        cache.read(boardHash: 1, selectedPoint: 13, dice: const [3, 5]),
        isNull,
      );
    });

    test('returns the stored map after write', () {
      final cache = MoveQualityCache();
      cache.write(
        boardHash: 1,
        selectedPoint: 13,
        dice: const [3, 5],
        qualities: const {16: MoveQuality.best, 18: MoveQuality.good},
      );
      final hit = cache.read(boardHash: 1, selectedPoint: 13, dice: const [3, 5]);
      expect(hit, isNotNull);
      expect(hit![16], equals(MoveQuality.best));
      expect(hit[18], equals(MoveQuality.good));
    });

    test('dice ordering does not affect the cache key', () {
      final cache = MoveQualityCache();
      cache.write(
        boardHash: 1,
        selectedPoint: 13,
        dice: const [3, 5],
        qualities: const {16: MoveQuality.best},
      );
      expect(
        cache.read(boardHash: 1, selectedPoint: 13, dice: const [5, 3]),
        isNotNull,
      );
    });

    test('different board hash misses', () {
      final cache = MoveQualityCache();
      cache.write(
        boardHash: 1,
        selectedPoint: 13,
        dice: const [3, 5],
        qualities: const {16: MoveQuality.best},
      );
      expect(
        cache.read(boardHash: 2, selectedPoint: 13, dice: const [3, 5]),
        isNull,
      );
    });

    test('invalidate clears all entries', () {
      final cache = MoveQualityCache();
      cache.write(
        boardHash: 1,
        selectedPoint: 13,
        dice: const [3, 5],
        qualities: const {16: MoveQuality.best},
      );
      cache.invalidate();
      expect(
        cache.read(boardHash: 1, selectedPoint: 13, dice: const [3, 5]),
        isNull,
      );
    });
  });
}

import 'package:tavli_bot/tavli_bot.dart';
import 'package:test/test.dart';

void main() {
  const ms = Duration(milliseconds: 1);

  test('easy: 0-ply, noisy, half the plays', () {
    final p = LevelProfile.of(BotLevel.easy);
    expect(p.depth, 0);
    expect(p.expertTwoPly, isFalse);
    expect(p.noise, 0.12);
    expect(p.topFraction, 0.5);
    expect(p.cascadeSamples, 8);
    expect(p.budget, ms * 7);
    expect(p.cascadeBudget, ms * 14);
  });

  test('medium: 1-ply, K 3 -> 6', () {
    final p = LevelProfile.of(BotLevel.medium);
    expect(p.depth, 1);
    expect(p.expertTwoPly, isFalse);
    expect((p.k, p.kMax), (3, 6));
    expect(p.noise, 0.04);
    expect(p.topFraction, 0.2);
    expect(p.cascadeSamples, 24);
    expect(p.budget, ms * 27);
    expect(p.cascadeBudget, ms * 54);
  });

  test('hard: 1-ply, K 6 -> 16', () {
    final p = LevelProfile.of(BotLevel.hard);
    expect(p.depth, 1);
    expect(p.expertTwoPly, isFalse);
    expect((p.k, p.kMax), (6, 16));
    expect(p.noise, 0.01);
    expect(p.topFraction, 0.05);
    expect(p.cascadeSamples, 64);
    expect(p.budget, ms * 100);
    expect(p.cascadeBudget, ms * 200);
  });

  test('expert: 1-ply + 2-ply top-2, K 8 -> 32, no noise, best only', () {
    final p = LevelProfile.of(BotLevel.expert);
    expect(p.depth, 1);
    expect(p.expertTwoPly, isTrue);
    expect((p.k, p.kMax), (8, 32));
    expect(p.noise, 0);
    expect(p.topFraction, 0);
    expect(p.cascadeSamples, 128);
    expect(p.budget, ms * 270);
    expect(p.cascadeBudget, ms * 540);
  });

  test('every level: cascade budget is 2x, K <= kMax, levels get stronger', () {
    LevelProfile? prev;
    for (final l in BotLevel.values) {
      final p = LevelProfile.of(l);
      expect(p.cascadeBudget, p.budget * 2, reason: '$l');
      expect(p.k, lessThanOrEqualTo(p.kMax), reason: '$l');
      if (prev != null) {
        expect(p.budget, greaterThan(prev.budget), reason: '$l');
        expect(p.noise, lessThan(prev.noise), reason: '$l');
        expect(p.cascadeSamples, greaterThan(prev.cascadeSamples));
      }
      prev = p;
    }
    expect(BotLevel.values, [
      BotLevel.easy,
      BotLevel.medium,
      BotLevel.hard,
      BotLevel.expert,
    ]);
  });
}

import 'dart:math';

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../../benchmark/bench_fixtures.dart';
import '../support/cascades.dart';
import '../support/plays.dart';
import '../support/positions.dart';

typedef S = Side;

final _gul = Variant.gulBara.rules;

/// [pl] is a complete legal play of [t] from [start].
void expectLegalPlay(PlayTree t, Position start, Play pl) {
  final n = t.walk(pl.steps);
  expect(n, isNotNull, reason: 'leaves the tree: ${pl.steps}');
  expect(n!.isComplete, isTrue, reason: 'incomplete: ${pl.steps}');
  expect(n.finalPosition, pl.finalPosition);
  expect(after(start, S.one, _gul, pl.steps), pl.finalPosition);
  expect(() => pl.steps.add(const Step(1, 0, 1)), throwsUnsupportedError);
}

/// Prefers checkers on low own pips, quadratically, so siblings differ.
double lowCheckers(BoardView p) {
  var sum = 0;
  for (var pip = 1; pip <= 25; pip++) {
    sum += pip * pip * p.count(S.one, pip);
  }
  return -sum.toDouble();
}

/// Cases with more finals than a sample asks for, plus the small ones.
Map<String, (Position, List<int>)> get _cases => {
      ...smallCascades,
      'opening 1s': (Position.forRules(_gul), cascadeQueue(1)),
      'midgame 2s': (
        posSame(
          one: {24: 11, 20: 1, 17: 1, 15: 1, 9: 1},
          two: {24: 11, 22: 1, 19: 1, 16: 1, 10: 1},
        ),
        cascadeQueue(2),
      ),
    };

void main() {
  test('requires a lazy tree', () {
    final eager = generatePlays(
        Position.forRules(_gul), S.one, const [6, 5], _gul, TurnContext());
    expect(() => CascadeWalker(eager), throwsArgumentError);
  });

  group('sampleCompletions', () {
    _cases.forEach((name, c) {
      test(name, () {
        final (p, q) = c;
        final t = generateCascade(p, S.one, q, _gul, TurnContext());
        final w = CascadeWalker(t);
        final got = w.sampleCompletions(8, Random(42));
        expect(got, isNotEmpty);
        expect(got.length, lessThanOrEqualTo(8));
        final finals = {for (final pl in got) pl.finalPosition};
        expect(finals, hasLength(got.length), reason: 'distinct finals');
        for (final pl in got) {
          expectLegalPlay(t, p, pl);
        }

        // The same seed gives the same result, even on a fresh tree.
        final again =
            CascadeWalker(generateCascade(p, S.one, q, _gul, TurnContext()))
                .sampleCompletions(8, Random(42));
        expect([for (final pl in again) pl.finalPosition],
            [for (final pl in got) pl.finalPosition]);
        expect([for (final pl in again) pl.steps],
            [for (final pl in got) pl.steps]);
      });
    });

    test('a large tree yields exactly n distinct finals', () {
      final (p, q) = _cases['opening 1s']!;
      final t = generateCascade(p, S.one, q, _gul, TurnContext());
      expect(() => t.enumerateFinals(limit: 8), throwsStateError);
      expect(CascadeWalker(t).sampleCompletions(8, Random(1)), hasLength(8));
    });

    test('stop is checked before each walk', () {
      // worstCascade: about 1 s for sample(8) without a stop.
      const f = worstCascade;
      final p = f.position;
      final t = generateCascade(p, f.side, f.dice, _gul, TurnContext());
      final sw = Stopwatch()..start();
      var checks = 0;
      final got = CascadeWalker(t)
          .sampleCompletions(8, Random(3), stop: () => checks++ >= 1);
      sw.stop();
      expect(got.length, lessThanOrEqualTo(1));
      // Two checks = one walk; the clock only catches a regression to a
      // full sample (one walk is ~140 ms asserts on; the bound leaves room
      // for parallel test load, like cascade_lazy_test's).
      expect(checks, 2);
      expect(sw.elapsedMilliseconds, lessThan(2000));
      for (final pl in got) {
        expect(t.walk(pl.steps)?.finalPosition, pl.finalPosition);
      }
      // Stopped up front: nothing.
      expect(CascadeWalker(t).sampleCompletions(8, Random(3), stop: () => true),
          isEmpty);
    });

    test('n <= 0 gives nothing', () {
      final (p, q) = _cases['opening 1s']!;
      final t = generateCascade(p, S.one, q, _gul, TurnContext());
      expect(CascadeWalker(t).sampleCompletions(0, Random(1)), isEmpty);
    });
  });

  group('greedyCompletion', () {
    _cases.forEach((name, c) {
      test(name, () {
        final (p, q) = c;
        final t = generateCascade(p, S.one, q, _gul, TurnContext());
        final pl = CascadeWalker(t).greedyCompletion(lowCheckers);
        expectLegalPlay(t, p, pl);

        // At every node the chosen child scores at least as well as each
        // sibling.
        var node = t.root;
        var prefix = <Step>[];
        for (final chosen in pl.steps) {
          final mine = lowCheckers(after(p, S.one, _gul, [...prefix, chosen]));
          for (final s in node.nextSteps) {
            final theirs = lowCheckers(after(p, S.one, _gul, [...prefix, s]));
            expect(mine, greaterThanOrEqualTo(theirs),
                reason: '$name at $prefix: $chosen vs $s');
          }
          node = node.child(chosen)!;
          prefix = [...prefix, chosen];
        }
        expect(node.isComplete, isTrue);
      });
    });
  });
}

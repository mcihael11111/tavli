import 'dart:math';

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../../benchmark/bench_fixtures.dart';
import '../support/cascades.dart';
import '../support/plays.dart';
import '../support/positions.dart';

typedef S = Side;

final _gul = Variant.gulBara.rules;

/// The 21 distinct rolls: 6 doubles as `[d, d, d, d]`, 15 as `[a, b]`.
final _rolls = [
  for (var a = 1; a <= 6; a++)
    for (var b = a; b <= 6; b++) a == b ? [a, a, a, a] : [b, a],
];

/// [steps] form a complete legal path of [t] ending at [f], and replaying
/// them through `StepRules` from [start] reproduces [f].
void expectPlayPath(PlayTree t, Position start, Side s, VariantRules rules,
    List<Step> steps, Position f) {
  final n = t.walk(steps);
  expect(n, isNotNull, reason: 'path leaves the tree: $steps');
  expect(n!.isComplete, isTrue, reason: 'path is not complete: $steps');
  expect(n.finalPosition, f);
  expect(after(start, s, rules, steps), f);
}

/// [p] with one opponent checker of [me] moved from its pip 5 to 4.
Position _moveOpponent(Position p, Side me) {
  final j = p.toJson();
  final key = me.opponent == S.one ? 'one' : 'two';
  final counts = [...(j[key]! as List).cast<int>()];
  expect(counts[5], greaterThan(0));
  counts[5]--;
  counts[4]++;
  return Position.fromJson({...j, key: counts});
}

void main() {
  test('21 rolls', () => expect(_rolls, hasLength(21)));

  group('plays() and pathTo on normal trees', () {
    for (final v in Variant.values) {
      test(v.name, () {
        final rules = v.rules;
        final positions = randomReachablePositions(v, 20, Random(7));
        for (var i = 0; i < positions.length; i++) {
          final p = positions[i];
          final side = i.isEven ? S.one : S.two;
          for (final dice in _rolls) {
            final t = generatePlays(p, side, dice, rules, TurnContext());
            final plays = t.plays();
            final why = '$v $p $side $dice';
            expect(plays.length, t.finals.length, reason: why);
            expect({for (final pl in plays) pl.finalPosition}, t.finals,
                reason: why);
            for (final pl in plays) {
              expect(() => pl.steps.add(const Step(1, 0, 1)),
                  throwsUnsupportedError);
              expect(pl.steps, isNotEmpty, reason: why);
              expect(pl.steps.length, lessThanOrEqualTo(t.diceUsed),
                  reason: why);
              expectPlayPath(t, p, side, rules, pl.steps, pl.finalPosition);
              final path = t.pathTo(pl.finalPosition);
              expect(path, isNotNull, reason: why);
              expectPlayPath(t, p, side, rules, path!, pl.finalPosition);
            }
            // The start is never a final (every step moves a checker).
            expect(t.pathTo(p), isNull, reason: why);
            // Nor is a one-step prefix of a longer play.
            if (t.diceUsed >= 2) {
              final s0 = t.root.nextSteps.first;
              final mid = after(p, side, rules, [s0]);
              if (!t.finals.contains(mid)) {
                expect(t.pathTo(mid), isNull, reason: why);
              }
            }
          }
        }
      });
    }
  });

  test('plays() order is by first discovery in the DFS', () {
    final p = Position.forRules(Variant.portes.rules);
    final t = generatePlays(
        p, S.one, const [3, 1], Variant.portes.rules, TurnContext());
    final want = <Position>[];
    for (final q in sequencesOf(t)) {
      final f = t.walk(q)!.finalPosition!;
      if (!want.contains(f)) want.add(f);
    }
    expect([for (final pl in t.plays()) pl.finalPosition], want);
  });

  test('a tree without a play has no plays', () {
    // Side one's last checker is on the bar; side two closes every entry
    // point (its home, my 19..24).
    final p = pos(
      one: {},
      barOne: 1,
      two: {1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 6: 2, 7: 3},
    );
    final t = generatePlays(
        p, S.one, const [6, 5], Variant.portes.rules, TurnContext());
    expect(t.hasPlay, isFalse);
    expect(t.plays(), isEmpty);
    expect(t.pathTo(p), isNull);
  });

  group('lazy cascade trees', () {
    test('plays() throws StateError', () {
      final t = generateCascade(
          Position.forRules(_gul), S.one, cascadeQueue(6), _gul, TurnContext());
      expect(t.isLazy, isTrue);
      expect(t.plays, throwsStateError);
    });

    test('pathTo on worstCascade: non-finals are rejected fast', () {
      const f = worstCascade;
      final p = f.position;
      final t = generateCascade(p, f.side, f.dice, _gul, TurnContext());
      final w = CascadeWalker(t);
      final real = w.sampleCompletions(3, Random(5));
      expect(real, isNotEmpty);
      final half = real.first.steps.sublist(0, real.first.steps.length ~/ 2);
      final nonFinals = {
        'start': p,
        'half a play': after(p, f.side, _gul, half),
        // A real final with the opponent changed: no play moves the
        // opponent in a block game.
        'opponent moved': _moveOpponent(real.first.finalPosition, f.side),
      };
      nonFinals.forEach((name, target) {
        final sw = Stopwatch()..start();
        expect(t.pathTo(target), isNull, reason: name);
        sw.stop();
        // Asserts on; unpruned, 'start' walks the whole tree.
        expect(sw.elapsedMilliseconds, lessThan(200), reason: name);
      });
      // Real finals still resolve (walker steps and pathTo agree on the
      // final, not necessarily on the path).
      for (final pl in [
        ...real,
        w.greedyCompletion((b) => -b.pipCount(f.side).toDouble())
      ]) {
        final path = t.pathTo(pl.finalPosition);
        expect(path, isNotNull);
        expectPlayPath(t, p, f.side, _gul, path!, pl.finalPosition);
      }
    });

    test('pathTo finds every final of random cascades (prune soundness)', () {
      final rng = Random(11);
      var checked = 0;
      final positions = randomReachablePositions(Variant.gulBara, 30, rng);
      for (var i = 0; i < positions.length; i++) {
        final p = positions[i];
        final side = i.isEven ? S.one : S.two;
        for (var d = 1; d <= 6; d++) {
          final t =
              generateCascade(p, side, cascadeQueue(d), _gul, TurnContext());
          Set<Position> finals;
          try {
            finals = t.enumerateFinals(limit: 60);
          } on StateError {
            continue; // too many to check them all here
          }
          for (final f in finals) {
            final path = t.pathTo(f);
            expect(path, isNotNull, reason: '$p $side $d $f');
            expectPlayPath(t, p, side, _gul, path!, f);
            checked++;
          }
        }
      }
      expect(checked, greaterThan(200));
    });

    smallCascades.forEach((name, c) {
      test('pathTo every final: $name', () {
        final (p, q) = c;
        final t = generateCascade(p, S.one, q, _gul, TurnContext());
        final finals = t.enumerateFinals();
        expect(finals, isNotEmpty);
        for (final f in finals) {
          final path = t.pathTo(f);
          expect(path, isNotNull, reason: '$f');
          expectPlayPath(t, p, S.one, _gul, path!, f);
        }
        expect(t.pathTo(p), isNull);
      });
    });
  });
}

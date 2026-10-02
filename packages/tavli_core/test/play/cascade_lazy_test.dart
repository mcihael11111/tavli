import 'dart:collection';

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';

typedef S = Side;

final _gul = Variant.gulBara.rules;
final _ctx = TurnContext();

/// Brute force without any max-playable search: expand every distinct
/// (position, context) level by level along the queue. A game-ending step
/// counts as playing the whole queue (matrix A4).
({int used, Set<Position> finals}) bruteForce(
  Position p,
  Side s,
  List<int> queue,
  VariantRules rules,
) {
  final steps = StepRules(rules), v = StepValidators(rules);
  var level = <(Position, TurnContext)>{(p, _ctx.withDice(queue))};
  final ended = <Position>{};
  var depth = 0;
  while (depth < queue.length) {
    final next = <(Position, TurnContext)>{};
    for (final (pos, ctx) in level) {
      final m = pos.toMutable();
      for (final step in steps.basicSteps(m, s, queue[depth])) {
        if (!v.allowsBefore(m, s, step, ctx)) continue;
        final a = steps.apply(m, s, step);
        if (!v.checksAfter || v.allowsAfter(m, s, a, ctx)) {
          final f = m.freeze();
          if (endsGame(f, rules, s)) {
            ended.add(f);
          } else {
            next.add((f, v.next(ctx, a)));
          }
        }
        steps.undo(m, s, a);
      }
    }
    if (next.isEmpty) break;
    level = next;
    depth++;
  }
  if (ended.isNotEmpty) {
    return (
      used: queue.length,
      finals: {
        ...ended,
        if (depth == queue.length)
          for (final (f, _) in level) f,
      },
    );
  }
  return (
    used: depth,
    finals: {
      if (depth > 0)
        for (final (f, _) in level) f,
    },
  );
}

/// Walks every node of [t] once and returns the finals of complete nodes,
/// checking that incomplete nodes always continue and that complete nodes
/// sit at [PlayTree.diceUsed] steps (or ended the game).
Set<Position> walkAll(PlayTree t, Side s, VariantRules rules) {
  final seen = HashSet<PlayNode>.identity();
  final finals = <Position>{};
  void visit(PlayNode n, int depth) {
    if (!seen.add(n)) return;
    final f = n.finalPosition;
    if (f != null) {
      expect(n.nextSteps, isEmpty);
      expect(depth == t.diceUsed || endsGame(f, rules, s), isTrue);
      finals.add(f);
      return;
    }
    expect(n.nextSteps, isNotEmpty, reason: 'dead end at depth $depth');
    for (final step in n.nextSteps) {
      visit(n.child(step)!, depth + 1);
    }
  }

  if (t.hasPlay) visit(t.root, 0);
  return finals;
}

void main() {
  test('searchedStates counts the cascade search; 0 for eager trees', () {
    final rules = Variant.gulBara.rules;
    final p = posSame(
      one: {24: 1, 13: 2, 1: 12},
      two: {24: 12, 9: 1, 8: 1, 7: 1},
    );
    final eager = generatePlays(p, Side.one, [6, 5], rules, TurnContext());
    expect(eager.searchedStates, 0);
    final t =
        generateCascade(p, Side.one, cascadeQueue(4), rules, TurnContext());
    final built = t.searchedStates;
    expect(built, greaterThan(0));
    var n = t.root;
    while (!n.isComplete) {
      n = n.child(n.nextSteps.first)!;
    }
    expect(t.searchedStates, greaterThanOrEqualTo(built));
    // Deterministic: a fresh tree walked the same way counts the same.
    final again =
        generateCascade(p, Side.one, cascadeQueue(4), rules, TurnContext());
    expect(again.searchedStates, built);
  });

  group('lazy cascade tree', () {
    final cases = <String, (Position, List<int>)>{
      // Stuck checker on 24 (my 21, 20, 19 closed), 2 movers on 13; the
      // queue runs out of room in the 5s.
      'fails mid-queue': (
        posSame(
          one: {24: 1, 13: 2, 1: 12},
          two: {24: 12, 9: 1, 8: 1, 7: 1},
        ),
        cascadeQueue(4),
      ),
      // From random play: failing cascades with several finals.
      'random A (11 of 16, 8 finals)': (
        posSame(
          one: {24: 3, 21: 1, 19: 1, 12: 1, 11: 2, 4: 2, 2: 3, 1: 2},
          two: {19: 4, 18: 2, 11: 1, 5: 1, 4: 1, 3: 1, 2: 1, 1: 4},
        ),
        cascadeQueue(3),
      ),
      'random B (7 of 8, 9 finals)': (
        posSame(
          one: {23: 1, 21: 1, 17: 1, 16: 2, 4: 5, 1: 5},
          two: {22: 1, 17: 4, 15: 2, 10: 1, 3: 3, 2: 2, 1: 2},
        ),
        cascadeQueue(5),
      ),
      // Bear-off: some lines end the game early (A4).
      'game-ending lines': (
        posSame(one: {6: 2, 4: 1, 3: 1}, two: {24: 15}),
        cascadeQueue(2),
      ),
      'full queue': (
        posSame(one: {24: 2, 18: 1, 1: 12}, two: {24: 15}),
        cascadeQueue(5),
      ),
      'remainder queue': (
        posSame(one: {24: 2, 18: 1, 1: 12}, two: {24: 15}),
        const [5, 5, 6, 6],
      ),
    };
    cases.forEach((name, c) {
      test('lazy walk == brute force: $name', () {
        final (p, q) = c;
        final t = generateCascade(p, S.one, q, _gul, _ctx);
        final want = bruteForce(p, S.one, q, _gul);
        expect(t.diceUsed, want.used);
        expect(t.remainder, q.sublist(want.used));
        expect(walkAll(t, S.one, _gul), want.finals);
        expect(t.enumerateFinals(), want.finals);
        expect(t.isForced, want.finals.length == 1);
        expect(t.hasPlay, want.used > 0);
      });
    });

    test('a lazy tree has no materialized finals', () {
      final t = generateCascade(
          Position.forRules(_gul), S.one, cascadeQueue(6), _gul, _ctx);
      expect(t.isLazy, isTrue);
      expect(() => t.finals, throwsStateError);
      expect(() => t.enumerateFinals(limit: 0), throwsStateError);
      final eager = generatePlays(
          Position.forRules(_gul), S.one, const [6, 5], _gul, _ctx);
      expect(eager.isLazy, isFalse);
      expect(eager.enumerateFinals(), eager.finals);
    });

    test('rules with play filters are rejected', () {
      expect(
        () => generateCascade(Position.forRules(Variant.fevga.rules), S.one,
            cascadeQueue(3), Variant.fevga.rules, _ctx),
        throwsArgumentError,
      );
    });

    test('budget: bad early cascades build and walk fast', () {
      // Asserts are on under `dart test`; the asserts-off target is
      // <= 50 ms per build. This bound only catches regressions.
      final positions = [
        Position.forRules(_gul),
        posSame(
          one: {24: 11, 20: 1, 17: 1, 15: 1, 9: 1},
          two: {24: 11, 22: 1, 19: 1, 16: 1, 10: 1},
        ),
        // The worst failing cascade seen in random play: 23 of 24 dice, and
        // proving 24 unreachable visits ~117k states (~200 ms asserts-off).
        posSame(
          one: {
            24: 2,
            19: 1,
            18: 1,
            16: 1,
            14: 1,
            13: 3,
            4: 2,
            3: 1,
            2: 1,
            1: 2
          },
          two: {24: 6, 22: 1, 21: 1, 20: 2, 19: 3, 17: 1, 5: 1},
        ),
      ];
      for (final p in positions) {
        for (final d in [1, 2, 3]) {
          final sw = Stopwatch()..start();
          final t = generateCascade(p, S.one, cascadeQueue(d), _gul, _ctx);
          // Walk one line to completion, expanding a node per step.
          var n = t.root;
          var steps = 0;
          while (!n.isComplete) {
            n = n.child(n.nextSteps.first)!;
            steps++;
          }
          sw.stop();
          expect(steps, t.diceUsed);
          expect(sw.elapsedMilliseconds, lessThan(2000), reason: '$p $d');
        }
      }
    });
  });
}

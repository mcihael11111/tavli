/// Differential fuzz of the cascade pruning bound (SP3 Task 1): pruned
/// [generateCascade] against the plain search ([generateCascadeUnpruned])
/// on random reachable Gul Bara positions x both sides x every cascade
/// queue and random remainder tails.
///
/// Positions: `TAVLI_CASCADE_FUZZ_POSITIONS` reachable ones plus as many
/// synthetic ones (default [_defaultPositions] each).
/// The SP3 Task 1 run (>= 1M finals compared) is
/// `TAVLI_CASCADE_FUZZ_POSITIONS=300 dart test --tags fuzz
/// test/fuzz/cascade_prune_fuzz_test.dart`.
// Totals are printed for the report.
// ignore_for_file: avoid_print
@Tags(['fuzz'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:tavli_core/src/play/play_generator.dart'
    show generateCascadeUnpruned;
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';

const _defaultPositions = 6;

final int _positions =
    int.tryParse(Platform.environment['TAVLI_CASCADE_FUZZ_POSITIONS'] ?? '') ??
        _defaultPositions;

/// Trees with more finals than this compare everything but the finals:
/// `TAVLI_CASCADE_FUZZ_FINALS` (default 3000).
final int _finalsLimit =
    int.tryParse(Platform.environment['TAVLI_CASCADE_FUZZ_FINALS'] ?? '') ??
        3000;

/// pathTo is compared on trees with at most this many finals (on a big
/// tree a target can cost a large part of it).
const _pathLimit = 20000;

final _gul = Variant.gulBara.rules;

/// A random same-direction board, not necessarily reachable: the
/// opponent's checkers form random blocks (often primes), and the mover
/// has 1..15 checkers left, all home in about a third of the boards, so
/// failing cascades and bear-off lines are common.
Position _synthetic(Random r) {
  final two = <int, int>{}, one = <int, int>{};
  final points = 3 + r.nextInt(8);
  var left = 15;
  for (var k = 0; k < points && left > 0; k++) {
    final pip = 1 + r.nextInt(24);
    final c = k == points - 1 ? left : 1 + r.nextInt(min(left, 3));
    two[pip] = (two[pip] ?? 0) + c;
    left -= c;
  }
  // Mover pip x is the opponent's pip x > 12 ? x - 12 : x + 12.
  bool free(int x) => !two.containsKey(x > 12 ? x - 12 : x + 12);
  final home = r.nextInt(3) == 0;
  final n = 1 + r.nextInt(15);
  for (var k = 0; k < n; k++) {
    for (var tries = 0; tries < 50; tries++) {
      final x = home ? 1 + r.nextInt(6) : 1 + r.nextInt(24);
      if (free(x)) {
        one[x] = (one[x] ?? 0) + 1;
        break;
      }
    }
  }
  if (one.isEmpty) {
    // Fewer than 15 opposing points exist, so some pip is free.
    one[[for (var x = 1; x <= 24; x++) x].firstWhere(free)] = 1;
  }
  return posSame(one: one, two: two);
}

void main() {
  test(
    'pruned cascade == unpruned: diceUsed, remainder, finals, pathTo, walks',
    () {
      final rng = Random(20261020);
      final ps = [
        ...randomReachablePositions(Variant.gulBara, _positions, rng),
        for (var k = 0; k < _positions; k++) _synthetic(rng),
      ];
      var trees = 0, finals = 0, paths = 0, tooMany = 0, walks = 0;
      var prunedStates = 0, plainStates = 0, cut = 0, failing = 0;
      for (final p in ps) {
        for (final side in Side.values) {
          for (var d = 1; d <= 6; d++) {
            final q = cascadeQueue(d);
            final tails = [q, q.sublist(1 + rng.nextInt(q.length - 1))];
            for (final queue in tails) {
              final ctx = TurnContext(firstTurn: rng.nextBool());
              final where = '${side.name} $queue ${jsonEncode(p.toJson())}';
              final a = generateCascade(p, side, queue, _gul, ctx);
              final b = generateCascadeUnpruned(p, side, queue, _gul, ctx);
              trees++;
              if (a.searchedStates < b.searchedStates) cut++;
              if (a.diceUsed < queue.length) failing++;
              expect(a.diceUsed, b.diceUsed, reason: where);
              expect(a.remainder, b.remainder, reason: where);
              expect(a.hasPlay, b.hasPlay, reason: where);
              expect(a.root.nextSteps.toList(), b.root.nextSteps.toList(),
                  reason: where);
              // Random walks see the same steps in the same order.
              final seed = rng.nextInt(1 << 30);
              final wa = CascadeWalker(a).sampleCompletions(4, Random(seed));
              final wb = CascadeWalker(b).sampleCompletions(4, Random(seed));
              expect(wa, wb, reason: where);
              walks += wa.length;
              Set<Position>? fa, fb;
              try {
                fa = a.enumerateFinals(limit: _finalsLimit);
              } on StateError {
                fa = null;
              }
              try {
                fb = b.enumerateFinals(limit: _finalsLimit);
              } on StateError {
                fb = null;
              }
              expect(fa == null, fb == null, reason: where);
              if (fa == null || fb == null) {
                tooMany++;
                continue;
              }
              expect(fa, fb, reason: where);
              finals += fa.length;
              prunedStates += a.searchedStates;
              plainStates += b.searchedStates;
              // pathTo: the same path to a few finals; none to a non-final.
              final list = fa.toList();
              final pathOk = list.isNotEmpty && list.length <= _pathLimit;
              for (var k = 0; k < 2 && pathOk; k++) {
                final target = list[rng.nextInt(list.length)];
                final pa = a.pathTo(target), pb = b.pathTo(target);
                expect(pa, isNotNull, reason: where);
                expect(pa, pb, reason: where);
                paths++;
              }
              if (pathOk && !fa.contains(p)) {
                expect(a.pathTo(p), isNull, reason: where);
                expect(b.pathTo(p), isNull, reason: where);
              }
            }
          }
        }
      }
      print('cascade prune fuzz: positions=${ps.length} trees=$trees '
          '(failing $failing, pruned build searched fewer states: $cut) '
          'finals compared=$finals (trees over $_finalsLimit finals: '
          '$tooMany) pathTo=$paths walks=$walks '
          'states pruned=$prunedStates unpruned=$plainStates');
    },
    timeout: Timeout(Duration(seconds: 60 + 10 * _positions)),
  );
}

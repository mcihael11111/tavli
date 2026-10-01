import 'dart:convert';
import 'dart:math';

import 'package:tavli_core/src/play/reference_generator.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';

/// Sampled positions per variant (plan Task 9).
const _positions = 30;

/// Cascade comparisons skip trees with more finals than this: the oracle
/// expands every distinct state level by level, which is too slow for
/// early cascades (10^5+ finals).
const _cascadeLimit = 400;

/// The 21 rolls: `[a, b]` or `[d, d, d, d]`.
final _rolls = [
  for (var a = 1; a <= 6; a++)
    for (var b = a; b <= 6; b++) a == b ? [a, a, a, a] : [a, b],
];

/// A mismatch report: the position JSON, the roll and the symmetric
/// difference (up to 5 finals each way), or null when [fast] == [ref].
String? _diff(
  String what,
  Position p,
  Side s,
  List<int> dice,
  TurnContext ctx,
  Set<Position> fast,
  Set<Position> ref,
) {
  final onlyFast = fast.difference(ref), onlyRef = ref.difference(fast);
  if (onlyFast.isEmpty && onlyRef.isEmpty) return null;
  String list(Set<Position> f) => f.take(5).map((x) => '    $x').join('\n');
  return '$what: ${s.name} dice $dice firstTurn ${ctx.firstTurn}\n'
      '  position ${jsonEncode(p.toJson())}\n'
      '  $p\n'
      '  fast ${fast.length}, reference ${ref.length}\n'
      '  only fast (${onlyFast.length}):\n${list(onlyFast)}\n'
      '  only reference (${onlyRef.length}):\n${list(onlyRef)}';
}

/// Side one with 1..6 checkers on pips 1..9 (the rest borne off); two all
/// on its start (side one's 12).
Position _race(Random rng) {
  final one = <int, int>{};
  for (var n = 1 + rng.nextInt(6); n > 0; n--) {
    final pip = 1 + rng.nextInt(9);
    one[pip] = (one[pip] ?? 0) + 1;
  }
  return posSame(one: one, two: {24: 15});
}

void main() {
  for (final v in Variant.values) {
    test('G4 oracle differential: ${v.name}, $_positions positions x 21 rolls',
        () {
      final rules = v.rules;
      final positions =
          randomReachablePositions(v, _positions, Random(9000 + v.index));
      final failures = <String>[];
      for (var i = 0; i < positions.length; i++) {
        final p = positions[i];
        final side = i.isEven ? Side.one : Side.two;
        // Every fifth sample is a first turn, for the D18 exception.
        final ctx = TurnContext(firstTurn: i % 5 == 0);
        for (final dice in _rolls) {
          final fast = generatePlays(p, side, dice, rules, ctx).finals;
          final ref = referenceFinals(p, side, dice, rules, ctx);
          final d = _diff(v.name, p, side, dice, ctx, fast, ref);
          if (d != null) failures.add(d);
        }
      }
      printOnFailure(failures.take(5).join('\n\n'));
      expect(failures, isEmpty, reason: '${failures.length} mismatches');
    });
  }

  test('D18 oracle differential: every start position, first turn x 21 rolls',
      () {
    final failures = <String>[];
    for (final v in Variant.values) {
      final rules = v.rules;
      final p = Position.forRules(rules);
      final ctx = TurnContext(firstTurn: true);
      for (final side in Side.values) {
        for (final dice in _rolls) {
          final fast = generatePlays(p, side, dice, rules, ctx).finals;
          final ref = referenceFinals(p, side, dice, rules, ctx);
          final d = _diff('${v.name} start', p, side, dice, ctx, fast, ref);
          if (d != null) failures.add(d);
        }
      }
    }
    printOnFailure(failures.take(5).join('\n\n'));
    expect(failures, isEmpty, reason: '${failures.length} mismatches');
  });

  test('D15 D16 oracle differential: Gul Bara cascades with few finals', () {
    final rules = Variant.gulBara.rules;
    final rng = Random(77);
    final positions = [
      ...randomReachablePositions(Variant.gulBara, 40, rng),
      // Bear-off races, where a cascade can end the game mid-queue (A4).
      for (var i = 0; i < 20; i++) _race(rng),
    ];
    final failures = <String>[];
    var compared = 0, skipped = 0;
    for (var i = 0; i < positions.length; i++) {
      final p = positions[i];
      final side = i.isEven || i >= 40 ? Side.one : Side.two;
      final ctx = TurnContext();
      for (var d = 1; d <= 6; d++) {
        // The full queue, and a random suffix as a remainder would be.
        final full = cascadeQueue(d);
        for (final queue in [full, full.sublist(rng.nextInt(full.length))]) {
          final tree = generateCascade(p, side, queue, rules, ctx);
          final Set<Position> fast;
          try {
            fast = tree.enumerateFinals(limit: _cascadeLimit);
          } on StateError {
            skipped++;
            continue;
          }
          compared++;
          final ref =
              referenceFinals(p, side, queue, rules, ctx, cascade: true);
          final diff = _diff('gulBara cascade', p, side, queue, ctx, fast, ref);
          if (diff != null) failures.add(diff);
        }
      }
    }
    printOnFailure('cascade oracle: compared $compared, skipped $skipped '
        '(> $_cascadeLimit finals)');
    printOnFailure(failures.take(5).join('\n\n'));
    expect(failures, isEmpty, reason: '${failures.length} mismatches');
    expect(compared, greaterThanOrEqualTo(100));
  });

  test('oracle: dice orders and filters on a hand-checked case', () {
    // Portes opening 3-1 has 16 finals (play_generator_test hand count).
    final rules = Variant.portes.rules;
    final start = Position.forRules(rules);
    expect(referenceFinals(start, Side.one, const [3, 1], rules, TurnContext()),
        hasLength(16));
    // Fevga runner rule: the 3 alone (see the generator's G4 test).
    final fevga = Variant.fevga.rules;
    final p = posSame(one: {24: 14, 20: 1}, two: {24: 14, 3: 1});
    expect(referenceFinals(p, Side.one, const [5, 3], fevga, TurnContext()), {
      posSame(one: {24: 14, 17: 1}, two: {24: 14, 3: 1})
    });
  });
}

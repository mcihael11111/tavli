import 'dart:convert';
import 'dart:math';

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/random_play.dart';

/// Strings that are valid somewhere in the schema, to make plausible
/// mutations.
const _names = [
  'one', 'two', 'opening', 'awaitingRoll', 'cubeOffered', 'moving', //
  'gameOver', 'portes', 'plakoto', 'fevga', 'gulBara', 'tawla31',
  'single', 'gammon', 'draw', 'mother', 'resign', 'gameMove', 'nextGame',
  'step', 'rollDice', 'opposing', 'same',
];

/// Every container path in [json] (map keys and list indices).
List<List<Object>> _paths(Object? json, [List<Object> prefix = const []]) => [
      if (json is Map<String, Object?>)
        for (final e in json.entries) ...[
          [...prefix, e.key],
          ..._paths(e.value, [...prefix, e.key]),
        ]
      else if (json is List<Object?>)
        for (var i = 0; i < json.length; i++) ...[
          [...prefix, i],
          ..._paths(json[i], [...prefix, i]),
        ],
    ];

/// A plausible wrong value for [old].
Object? _junk(Object? old, Random r) {
  switch (r.nextInt(6)) {
    case 0:
      return null;
    case 1:
      return _names[r.nextInt(_names.length)];
    case 2:
      return old is int ? old + r.nextInt(5) - 2 : r.nextInt(30) - 3;
    case 3:
      return old is bool ? !old : r.nextBool();
    case 4:
      return old is List ? (List.of(old)..shuffle(r)) : <Object?>[1, 2];
    default:
      return r.nextBool() ? <String, Object?>{} : 1 << 40;
  }
}

/// [json] with 1..3 random mutations (replace, or drop a map key).
Object? _mutate(Object? json, Random r) {
  final copy = jsonDecode(jsonEncode(json));
  for (var k = 1 + r.nextInt(3); k > 0; k--) {
    final paths = _paths(copy);
    if (paths.isEmpty) break;
    final path = paths[r.nextInt(paths.length)];
    Object? parent = copy;
    for (final p in path.sublist(0, path.length - 1)) {
      parent = parent is Map ? parent[p] : (parent as List)[p as int];
    }
    final last = path.last;
    if (parent is Map<String, Object?>) {
      if (r.nextInt(5) == 0) {
        parent.remove(last);
      } else {
        parent[last as String] = _junk(parent[last], r);
      }
    } else if (parent is List<Object?>) {
      parent[last as int] = _junk(parent[last], r);
    }
  }
  return copy;
}

/// Every action kind, so an accepted state is poked in every phase.
List<GameAction> _probes(GameState s) => [
      const RollOpening(4, 2),
      const RollDice(5, 3),
      const RollDice(2, 2),
      if (s.phase == GamePhase.moving && s.node.nextSteps.isNotEmpty)
        StepAction(s.node.nextSteps.first),
      const StepAction(Step(13, 8, 5)),
      const UndoStep(),
      const CommitPlay(),
      const OfferDouble(),
      const Take(),
      const Drop(),
      const Resign(Side.one),
      const ClockTimeout(Side.two),
    ];

void main() {
  test(
      'mutated JSON only ever throws FormatException; accepted states '
      'never make the reducers throw', () {
    final r = Random(99);
    final samples = <MatchState>[];
    for (final v in Variant.values) {
      final target = v.rules.match.fixedTarget ?? 5;
      var m =
          MatchState.initial(MatchConfig.to(target, [v], cubeEnabled: true));
      for (var i = 0; i < 300 && !m.isOver; i++) {
        final g = randomLegalAction(m.game, r);
        final res = reduceMatch(m, g == null ? const NextGame() : GameMove(g));
        if (res is MatchUpdate) m = res.state;
        if (i % 25 == 0) samples.add(m);
      }
    }
    var accepted = 0, rejected = 0;
    for (final m in samples) {
      for (var k = 0; k < 15; k++) {
        final bad = _mutate(m.toJson(), r);
        final MatchState parsed;
        try {
          parsed = MatchState.fromJson(bad);
        } on FormatException {
          rejected++;
          continue;
        } catch (e) {
          fail('MatchState.fromJson threw ${e.runtimeType}: $e\n'
              '${jsonEncode(bad)}');
        }
        accepted++;
        for (final a in _probes(parsed.game)) {
          reduce(parsed.game, a);
          reduceMatch(parsed, GameMove(a));
        }
        reduceMatch(parsed, const NextGame());
        // An accepted state serializes back to itself.
        expect(MatchState.fromJson(parsed.toJson()), parsed);
      }
      for (final read in [GameLog.fromJson, MatchAction.fromJson]) {
        final bad = _mutate(
          read == GameLog.fromJson
              ? GameLog(m.config, const [GameMove(RollDice(3, 1))]).toJson()
              : const GameMove(StepAction(Step(8, 5, 3))).toJson(),
          r,
        );
        try {
          read(bad);
        } on FormatException {
          // expected
        }
      }
    }
    printOnFailure('accepted $accepted, rejected $rejected');
    expect(rejected, greaterThan(accepted));
    expect(accepted, greaterThan(0));
  });
}

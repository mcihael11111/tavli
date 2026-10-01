import 'dart:convert';
import 'dart:math';

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/random_play.dart';

// Structure-aware fuzz of GameState.fromJson: valid states' JSON mutated
// field by field into plausible but possibly unreachable states. Whatever
// fromJson accepts must be a state the reducer can run without throwing.

typedef Json = Map<String, Object?>;

Json _copy(Json j) => jsonDecode(jsonEncode(j)) as Json;

const _phases = [
  'opening',
  'awaitingRoll',
  'cubeOffered',
  'moving',
  'gameOver'
];

/// [j]'s board with one checker of a random side moved from the board to
/// its bar, or one lone checker pinned under a new pinner. Position.fromJson
/// judges whether the result is still a board.
Json _boardMutation(Json board, Random r) {
  final b = _copy(board);
  final side = r.nextBool() ? 'one' : 'two',
      other = side == 'one' ? 'two' : 'one';
  final mine = b[side]! as List<Object?>, theirs = b[other]! as List<Object?>;
  final occupied = [
    for (var p = 1; p <= 24; p++)
      if ((mine[p]! as int) > 0) p,
  ];
  if (occupied.isEmpty) return b;
  final p = occupied[r.nextInt(occupied.length)];
  if (r.nextBool()) {
    mine[p] = (mine[p]! as int) - 1;
    mine[25] = (mine[25]! as int) + 1;
    return b;
  }
  final dir = Direction.values.byName(b['direction']! as String);
  final q = Geometry.of(dir).toOpponent(p);
  final donors = [
    for (var i = 1; i <= 25; i++)
      if ((theirs[i]! as int) > 0 && i != q) i,
  ];
  if (donors.isEmpty) return b;
  final d = donors[r.nextInt(donors.length)];
  theirs[d] = (theirs[d]! as int) - 1;
  theirs[q] = (theirs[q]! as int) + 1;
  final key = side == 'one' ? 'pinnedOne' : 'pinnedTwo';
  b[key] = [...(b[key]! as List<Object?>), p];
  return b;
}

/// [g] with 1..4 structural mutations, some borrowed from [other].
Json _mutate(Json g, Json other, Random r) {
  final j = _copy(g);
  Json cube() => j['cube'] = Map.of(j['cube']! as Json);
  for (var k = 1 + r.nextInt(4); k > 0; k--) {
    switch (r.nextInt(17)) {
      case 0:
        j['phase'] = _phases[r.nextInt(_phases.length)];
      case 1:
        j['dice'] = other['dice'];
      case 2:
        final n = const [0, 1, 2, 3, 4, 5, 8, 12, 24][r.nextInt(9)];
        j['dice'] = [for (var i = 0; i < n; i++) 1 + r.nextInt(6)];
      case 3:
        j['steps'] = List.of(j['steps']! as List)..shuffle(r);
      case 4:
        final st = List.of(j['steps']! as List);
        if (st.isNotEmpty) st.removeAt(r.nextInt(st.length));
        j['steps'] = st;
      case 5:
        j['steps'] = other['steps'];
      case 6:
        j['cascadeMode'] = !(j['cascadeMode']! as bool);
      case 7:
        j['remainderTurn'] = !(j['remainderTurn']! as bool);
      case 8:
        cube()['value'] = 1 << r.nextInt(7);
      case 9:
        cube()['owner'] = [null, 'one', 'two'][r.nextInt(3)];
      case 10:
        cube()['offeredBy'] = [null, 'one', 'two'][r.nextInt(3)];
      case 11:
        j['turnsTaken'] = {'one': r.nextInt(3), 'two': r.nextInt(3)};
      case 12:
        j['rollIndex'] = r.nextInt(8);
      case 13:
        j['sideToMove'] = [null, 'one', 'two'][r.nextInt(3)];
      case 14:
        j['turnStart'] = other['turnStart'];
      case 15:
        j['turnStart'] = _boardMutation(j['turnStart']! as Json, r);
      default:
        j['crawfordGame'] = !(j['crawfordGame']! as bool);
    }
  }
  return j;
}

/// A step shaped like a step, from anywhere.
StepAction _randomStep(Random r) {
  final from = 1 + r.nextInt(25), die = 1 + r.nextInt(6);
  return StepAction(Step(from, max(0, from - die), die));
}

/// Every action kind, from no sender and from each side.
List<GameAction> _probes(GameState s, Random r) => [
      const RollOpening(4, 2),
      const RollDice(5, 3),
      const RollDice(2, 2),
      if (s.phase == GamePhase.moving)
        for (final st in s.node.nextSteps.take(3)) StepAction(st),
      _randomStep(r),
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
      'every state fromJson accepts runs: no action throws, and random '
      'legal play round-trips through JSON', () {
    final r = Random(7);
    final pool = <Variant, List<Json>>{};
    for (final v in Variant.values) {
      var s = GameState.initial(v, cubeEnabled: true);
      for (var i = 0; i < 400; i++) {
        final a = randomLegalAction(s, r);
        if (i % 6 == 0 || a == null) (pool[v] ??= []).add(s.toJson());
        if (a == null) break;
        final res = reduce(s, a);
        if (res is GameUpdate) s = res.state;
      }
    }
    var accepted = 0, rejected = 0;
    for (var it = 0; it < 1000; it++) {
      final v = Variant.values[r.nextInt(Variant.values.length)];
      final mine = pool[v]!;
      final base = mine[r.nextInt(mine.length)];
      final other = mine[r.nextInt(mine.length)];
      final bad = _mutate(base, other, r);
      final GameState s;
      try {
        s = GameState.fromJson(bad);
      } on FormatException {
        rejected++;
        continue;
      }
      accepted++;
      String why() => jsonEncode(bad);
      expect(GameState.fromJson(s.toJson()), s, reason: why());
      try {
        for (final a in _probes(s, r)) {
          for (final by in [null, ...Side.values]) {
            reduce(s, a, by: by);
          }
        }
      } catch (e) {
        fail('reduce threw ${e.runtimeType}: $e\n${why()}');
      }
      var cur = s;
      for (var i = 0; i < 60; i++) {
        final a = randomLegalAction(cur, r);
        if (a == null) break;
        final ReduceResult res;
        try {
          res = reduce(cur, a);
        } catch (e) {
          fail('reduce($a) threw ${e.runtimeType}: $e\n${why()}');
        }
        if (res is! GameUpdate) {
          expect(a, isA<OfferDouble>(), reason: '$res\n${why()}');
          continue;
        }
        cur = res.state;
        expect(GameState.fromJson(jsonDecode(jsonEncode(cur.toJson()))), cur,
            reason: 'after $a from ${why()}');
      }
    }
    printOnFailure('accepted $accepted, rejected $rejected');
    expect(accepted, greaterThan(150));
    expect(rejected, greaterThan(150));
  });
}

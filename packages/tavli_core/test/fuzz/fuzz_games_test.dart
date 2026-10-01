/// Fuzz suite (plan Task 16): random legal games of every variant to their
/// natural end, with invariants after every action.
///
/// Games per variant: `TAVLI_FUZZ_GAMES` (default [_defaultGames]). The
/// SP1 exit run is `TAVLI_FUZZ_GAMES=100000 dart test --tags fuzz`.
// Per-variant totals are printed for the SP1 report.
// ignore_for_file: avoid_print
@Tags(['fuzz'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:tavli_core/src/play/reference_generator.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/invariants.dart';
import '../support/results.dart';

/// Keeps the default `dart test` run fast; CI and the exit run raise it.
const _defaultGames = 40;

final int _games =
    int.tryParse(Platform.environment['TAVLI_FUZZ_GAMES'] ?? '') ??
        _defaultGames;

/// Actions per game before it counts as non-terminating.
const _maxActions = 3000;

/// Every [_replayEvery]th game is replayed from its log.
const _replayEvery = 50;

/// About one moving phase in [_oracleEvery] is checked against the oracle.
const _oracleEvery = 40;

/// Cascades with more finals than this skip the oracle (it expands every
/// state level by level; see oracle_differential_test).
const _cascadeOracleLimit = 400;

/// Every [_jsonEvery]th accepted action round-trips the state via JSON.
const _jsonEvery = 25;

/// Per-variant totals.
final class _Stats {
  int games = 0, actions = 0, turns = 0, stepPlays = 0, submitPlays = 0;
  int undos = 0, passes = 0, remainders = 0, offers = 0, maxCube = 1;
  int oracle = 0, oracleSkipped = 0, replays = 0, json = 0;
  final kinds = <ResultKind, int>{};

  @override
  String toString() {
    final k = [
      for (final e in kinds.entries) '${e.key.name}=${e.value}',
    ].join(' ');
    return 'games=$games actions=$actions turns=$turns '
        'plays(step=$stepPlays submit=$submitPlays) undos=$undos '
        'passes=$passes remainders=$remainders cubeTakes=$offers '
        'maxCube=$maxCube oracle=$oracle(skipped $oracleSkipped) '
        'replays=$replays jsonRoundTrips=$json | $k';
  }
}

/// A random path from the current node to a complete node (which a
/// game-ending step also makes, A4).
List<Step> _randomPath(GameState s, Random r) {
  final out = <Step>[];
  var node = s.node;
  while (!node.isComplete) {
    final next = node.nextSteps.toList();
    if (next.isEmpty) fail('dead end in the tree after $out: $s');
    final st = next[r.nextInt(next.length)];
    out.add(st);
    node = node.child(st)!;
  }
  return out;
}

/// The oracle's finals for the moving phase [s] (at its turn start).
void _checkOracle(GameState s, _Stats st) {
  final rules = s.variant.rules, side = s.sideToMove!;
  final ctx = TurnContext(firstTurn: s.turnsTaken[side] == 0);
  final Set<Position> fast;
  try {
    fast = s.tree.isLazy
        ? s.tree.enumerateFinals(limit: _cascadeOracleLimit)
        : s.tree.finals;
  } on StateError {
    st.oracleSkipped++;
    return;
  }
  final ref = referenceFinals(s.turnStart, side, s.dice, rules, ctx,
      cascade: s.cascadeMode);
  st.oracle++;
  if (fast.length != ref.length || !fast.containsAll(ref)) {
    fail('oracle mismatch: ${s.variant.name} ${side.name} dice ${s.dice} '
        'firstTurn ${ctx.firstTurn}\n'
        '  position ${jsonEncode(s.turnStart.toJson())}\n'
        '  fast ${fast.length}, reference ${ref.length}');
  }
}

/// Plays one game of [v] to its natural end; returns the final state.
GameState _playGame(Variant v, int gameNo, _Stats st) {
  final r = Random(v.index * 1000003 + gameNo);
  final rules = v.rules;
  final config =
      MatchConfig.single(v, cubeEnabled: rules.cube.available ? true : null);
  var s = MatchState.initial(config).game;
  final log = <MatchAction>[];
  // Step-by-step and SubmitPlay alternate turn by turn, from a random
  // start so both paths see first turns.
  var submit = r.nextBool();

  void apply(GameAction a) {
    final res = reduce(s, a);
    switch (res) {
      case RuleViolation():
        fail('${v.name} game $gameNo: $a rejected: $res\n  in $s');
      case GameUpdate(:final state, :final events):
        for (final e in events) {
          if (e is TurnPassed) st.passes++;
          if (e is RemainderPassed) st.remainders++;
          if (e is PlayCommitted) st.turns++;
        }
        s = state;
    }
    log.add(GameMove(a));
    st.actions++;
    checkState(s);
    if (st.actions % _jsonEvery == 0) {
      final back = GameState.fromJson(jsonDecode(jsonEncode(s.toJson())));
      if (back != s) fail('${v.name} JSON round-trip differs: $s');
      st.json++;
    }
  }

  int die() => 1 + r.nextInt(6);
  while (s.phase != GamePhase.gameOver) {
    if (log.length >= _maxActions) {
      fail('${v.name} game $gameNo: no end within $_maxActions actions');
    }
    switch (s.phase) {
      case GamePhase.opening:
        apply(RollOpening(die(), die()));
      case GamePhase.awaitingRoll:
        if (s.cube.enabled && r.nextInt(20) == 0) {
          // An offer may be refused (cube owned by the other side, 64).
          if (reduce(s, const OfferDouble()) is GameUpdate) {
            apply(const OfferDouble());
            continue;
          }
        }
        apply(RollDice(die(), die()));
      case GamePhase.cubeOffered:
        apply(const Take());
        st.offers++;
        st.maxCube = max(st.maxCube, s.cube.value);
      case GamePhase.moving:
        if (s.steps.isEmpty && r.nextInt(_oracleEvery) == 0) {
          _checkOracle(s, st);
        }
        final path = _randomPath(s, r);
        if (submit) {
          apply(SubmitPlay(path));
          st.submitPlays++;
        } else {
          for (final (i, step) in path.indexed) {
            apply(StepAction(step));
            // Now and then take a step back and redo it.
            if (s.phase == GamePhase.moving && r.nextInt(30) == 0) {
              apply(const UndoStep());
              apply(StepAction(step));
              st.undos++;
            }
            if (s.phase == GamePhase.gameOver) {
              if (i != path.length - 1) fail('ended before the path did');
              break;
            }
          }
          if (s.phase == GamePhase.moving) apply(const CommitPlay());
          st.stepPlays++;
        }
        submit = !submit;
      case GamePhase.gameOver:
        break;
    }
  }

  st.games++;
  checkNaturalResult(s);
  st.kinds.update(s.result!.kind, (n) => n + 1, ifAbsent: () => 1);
  final back = GameState.fromJson(jsonDecode(jsonEncode(s.toJson())));
  if (back != s) fail('${v.name} final JSON round-trip differs: $s');

  if (gameNo % _replayEvery == 0) {
    final json = jsonEncode(GameLog(config, log).toJson());
    final replayed = replay(GameLog.fromJson(jsonDecode(json))).game;
    expect(jsonEncode(replayed.toJson()), jsonEncode(s.toJson()),
        reason: '${v.name} game $gameNo replay');
    st.replays++;
  }
  return s;
}

void main() {
  final totals = _Stats();
  final clock = Stopwatch()..start();
  for (final v in Variant.values) {
    test('fuzz ${v.name}: $_games random legal games with invariants', () {
      final st = _Stats();
      final sw = Stopwatch()..start();
      for (var g = 0; g < _games; g++) {
        _playGame(v, g, st);
      }
      print('fuzz ${v.name.padRight(10)} ${sw.elapsed} $st');
      expect(st.games, _games);
      expect(st.turns, greaterThan(0));
      expect(st.replays, greaterThan(0));
      totals
        ..games += st.games
        ..actions += st.actions
        ..oracle += st.oracle
        ..replays += st.replays
        ..json += st.json;
    });
  }
  tearDownAll(() {
    print('fuzz total: ${totals.games} games, ${totals.actions} actions, '
        '${totals.oracle} oracle checks, ${totals.replays} replays, '
        '${totals.json} JSON round-trips in ${clock.elapsed}');
  });
}

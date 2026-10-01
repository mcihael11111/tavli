@Tags(['legacy-bench'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/ai/engine/ai_player.dart';
import 'package:tavli/features/game/data/models/board_state.dart';
import 'package:tavli/features/game/data/models/dice_roll.dart';
import 'package:tavli/features/game/domain/engine/game_engine.dart';
import 'package:tavli/features/game/domain/engine/move_generator.dart';
import 'package:tavli_core/tavli_core.dart' hide DiceRoll;
import 'package:tavli_testkit/tavli_testkit.dart';

import '../differential/portes_legacy.dart';

/// Baseline numbers for the LEGACY engine and AI, recorded before the rewrite
/// so every later sub-project can show its improvement against them, plus
/// the core-vs-legacy generation comparison (SP1 report §6).
/// Reports only — no budget assertions (the legacy code cannot meet them).
///
/// Run: flutter test --run-skipped --tags legacy-bench test/bench
/// (core vs legacy only: add --plain-name 'core generatePlays vs legacy').
void main() {
  test('legacy engine + AI baseline', () {
    const gen = MoveGenerator();
    const eng = GameEngine();
    // Seeded so the AI's tie-breaking/randomness is identical across runs.
    final ai = AiPlayer(rng: Random(7));
    // Dice seed 42 + AI seed 7 => identical positions every run.
    final rng = Random(42);

    // Positions come from a seeded (dice Random(42), AI Random(7)) easy-vs-easy
    // self-play: opening to early-middle plies, always with player 2 to move
    // (every second ply is kept). Identical across runs.
    final positions = <BoardState>[];
    var board = BoardState.initial();
    for (var ply = 0; ply < 60 && positions.length < 12; ply++) {
      final turn =
          ai.selectTurn(board, DiceRoll.random(rng), DifficultyLevel.easy);
      if (turn != null) board = eng.applyMoves(board, turn.moves);
      if (eng.isGameOver(board)) break;
      board = eng.endTurn(board);
      if (ply.isEven) positions.add(board);
    }

    final rolls = [
      for (var d1 = 1; d1 <= 6; d1++)
        for (var d2 = d1; d2 <= 6; d2++) DiceRoll(die1: d1, die2: d2),
    ];
    final doubles = rolls.where((r) => r.isDoubles).toList();

    // Index rolls fastest and positions slowest so the samples sweep the full
    // positions x rolls cross product (a shared stride would pin each roll to
    // a subset of positions). `all_rolls` therefore weights the 21 distinct
    // rolls equally (doubles count once, not 1/36).
    var i = 0;
    final results = <BenchStats>[
      // Bodies return their result so the bench sink keeps the work alive.
      measure(name: 'legacy.movegen.all_rolls', samples: 500, () {
        final p = positions[(i ~/ rolls.length) % positions.length];
        return gen.generateAllLegalTurns(p, rolls[i++ % rolls.length]);
      }),
      measure(name: 'legacy.movegen.doubles', samples: 300, () {
        final p = positions[(i ~/ doubles.length) % positions.length];
        return gen.generateAllLegalTurns(p, doubles[i++ % doubles.length]);
      }),
      measure(name: 'legacy.ai.easy.selectTurn', samples: 200, () {
        final p = positions[(i ~/ rolls.length) % positions.length];
        return ai.selectTurn(
            p, rolls[i++ % rolls.length], DifficultyLevel.easy);
      }),
      // Two samples only: each takes seconds to minutes (the core problem).
      measure(
          name: 'legacy.ai.medium.selectTurn',
          warmup: 0,
          minWarmup: Duration.zero,
          samples: 2, () {
        final p = positions[i++ % positions.length];
        return ai.selectTurn(
            p, const DiceRoll(die1: 3, die2: 1), DifficultyLevel.medium);
      }),
    ];

    final out = File('build/bench/legacy_baseline.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(const JsonEncoder.withIndent('  ')
          .convert([for (final r in results) r.toJson()]));
    for (final r in results) {
      debugPrint(r.toString());
    }
    debugPrint('Wrote ${out.path}');
    expect(results, hasLength(4));
  }, timeout: const Timeout(Duration(minutes: 9)));

  // SP1 report §6: core generatePlays vs the legacy MoveGenerator on the
  // SAME 12 baseline positions and the same roll sweep, mapped with the
  // differential's toCore (matrix §1). Both sides run under the same
  // `flutter test` settings (asserts on), so the comparison is fair; the
  // asserts-off core numbers are in benchmark/run_benchmarks.dart.
  test('core generatePlays vs legacy MoveGenerator (baseline positions)', () {
    const gen = MoveGenerator();
    final rules = Variant.portes.rules;
    final positions = baselinePositions();
    final core = [for (final b in positions) toCore(b)];
    final side = sideToMove(positions.first); // player 2 throughout
    final doubles = allRolls.where((r) => r.isDoubles).toList();

    // Index rolls fastest and positions slowest, as the baseline does.
    BenchStats sweep(String name, List<DiceRoll> rolls, int samples,
        Object? Function(int position, DiceRoll roll) body) {
      var i = 0;
      return measure(name: name, samples: samples, () {
        final n = (i ~/ rolls.length) % positions.length;
        return body(n, rolls[i++ % rolls.length]);
      });
    }

    final results = <BenchStats>[
      sweep('legacy.movegen.all_rolls', allRolls, 500,
          (n, r) => gen.generateAllLegalTurns(positions[n], r)),
      sweep(
          'core.generatePlays.all_rolls',
          allRolls,
          500,
          (n, r) =>
              generatePlays(core[n], side, coreDice(r), rules, TurnContext())),
      sweep('legacy.movegen.doubles', doubles, 300,
          (n, r) => gen.generateAllLegalTurns(positions[n], r)),
      sweep(
          'core.generatePlays.doubles',
          doubles,
          300,
          (n, r) =>
              generatePlays(core[n], side, coreDice(r), rules, TurnContext())),
    ];

    final out = File('build/bench/core_vs_legacy.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(const JsonEncoder.withIndent('  ')
          .convert([for (final r in results) r.toJson()]));
    for (final r in results) {
      debugPrint(r.toString());
    }
    for (final k in ['all_rolls', 'doubles']) {
      final legacy = results.firstWhere((r) => r.name == 'legacy.movegen.$k');
      final c = results.firstWhere((r) => r.name == 'core.generatePlays.$k');
      debugPrint('$k p95 speed-up: '
          '${(legacy.p95Ns / c.p95Ns).toStringAsFixed(1)}x');
    }
    debugPrint('Wrote ${out.path}');
    expect(positions, hasLength(12));
    expect(positions.every((b) => sideToMove(b) == Side.two), isTrue);
  });
}

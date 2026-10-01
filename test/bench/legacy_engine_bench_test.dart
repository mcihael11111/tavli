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
import 'package:tavli_testkit/tavli_testkit.dart';

/// Baseline numbers for the LEGACY engine and AI, recorded before the rewrite
/// so every later sub-project can show its improvement against them.
/// Reports only — no budget assertions (the legacy code cannot meet them).
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
}

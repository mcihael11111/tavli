import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/ai/engine/ai_player.dart';
import 'package:tavli/features/game/data/models/board_state.dart';
import 'package:tavli/features/game/data/models/dice_roll.dart';
import 'package:tavli/features/game/domain/engine/game_engine.dart';
import 'package:tavli/features/game/domain/engine/move_generator.dart';
import 'package:tavli_core/tavli_core.dart' hide DiceRoll;

/// Portes differential (SP1 plan Task 18): the legacy `MoveGenerator`'s
/// final boards must equal `tavli_core`'s legal finals, on positions from
/// a seeded legacy easy-vs-easy self-play x all 21 rolls.
///
/// Mapping (matrix §1, hitting layout): `points[i] > 0` is player 1 =
/// `Side.one` on pip `i + 1`; `points[i] < 0` is player 2 = `Side.two` on
/// pip `24 - i`; bars and borne-off counts map directly.
///
/// A mismatch is settled by the matrix (G1-G9). A legacy bug goes into
/// [knownLegacyBugs] with its rule ID; a core bug is fixed in core.

/// Legacy bugs found by this test, by rule ID. Each entry is a
/// `(position, roll)` key as printed by a mismatch, with the reason.
const knownLegacyBugs = <String, String>{};

/// Positions sampled from the self-play.
const _positions = 40;

/// Keep every [_every]th ply, so samples span openings, contact play,
/// bar entries and bear-offs.
const _every = 3;

Position toCore(BoardState b) {
  final one = <int, int>{}, two = <int, int>{};
  for (var i = 0; i < 24; i++) {
    final n = b.points[i];
    if (n > 0) one[i + 1] = n;
    if (n < 0) two[24 - i] = -n;
  }
  final p = Position.fromPips(
    one: one,
    two: two,
    barOne: b.bar1,
    barTwo: b.bar2,
    direction: Direction.opposing,
  );
  expect(p.borneOff(Side.one), b.borneOff1, reason: 'borne off 1: $b');
  expect(p.borneOff(Side.two), b.borneOff2, reason: 'borne off 2: $b');
  return p;
}

/// Seeded legacy easy-vs-easy self-play, as the legacy baseline: dice
/// `Random(42)`, AI `Random(7)`; a finished game starts a new one.
List<BoardState> _selfPlayPositions() {
  const eng = GameEngine();
  final ai = AiPlayer(rng: Random(7));
  final rng = Random(42);
  final out = <BoardState>[];
  var board = BoardState.initial();
  for (var ply = 0; out.length < _positions; ply++) {
    if (ply % _every == 0) out.add(board);
    final turn =
        ai.selectTurn(board, DiceRoll.random(rng), DifficultyLevel.easy);
    if (turn != null) board = eng.applyMoves(board, turn.moves);
    board = eng.isGameOver(board)
        ? BoardState.initial(activePlayer: board.activePlayer == 1 ? 2 : 1)
        : eng.endTurn(board);
  }
  return out;
}

void main() {
  test(
      'Portes: legacy MoveGenerator finals == tavli_core finals '
      '($_positions self-play positions x 21 rolls)', () {
    const gen = MoveGenerator();
    const eng = GameEngine();
    final rules = Variant.portes.rules;
    final mismatches = <String>[];
    var compared = 0, finals = 0, bar = 0, bearOff = 0;
    for (final board in _selfPlayPositions()) {
      final p = toCore(board);
      final side = board.activePlayer == 1 ? Side.one : Side.two;
      if (p.onBar(side) > 0) bar++;
      if (p.allHome(side)) bearOff++;
      for (var a = 1; a <= 6; a++) {
        for (var b = a; b <= 6; b++) {
          final roll = DiceRoll(die1: b, die2: a);
          final legacy = {
            for (final t in gen.generateAllLegalTurns(board, roll))
              toCore(eng.applyMoves(board, t.moves)),
          };
          final core = generatePlays(
                  p, side, a == b ? [a, a, a, a] : [b, a], rules, TurnContext())
              .finals;
          compared++;
          finals += core.length;
          final onlyLegacy = legacy.difference(core);
          final onlyCore = core.difference(legacy);
          if (onlyLegacy.isEmpty && onlyCore.isEmpty) continue;
          final key = '${jsonEncode(p.toJson())} ${side.name} $b-$a';
          if (knownLegacyBugs.containsKey(key)) continue;
          mismatches.add('$key\n  $p\n'
              '  legacy ${legacy.length}, core ${core.length}\n'
              '  only legacy: ${onlyLegacy.take(3).toList()}\n'
              '  only core: ${onlyCore.take(3).toList()}');
        }
      }
    }
    // ignore: avoid_print
    print('Portes differential: $compared position x roll pairs, '
        '$finals core finals, $bar with a checker on the bar, $bearOff '
        'bearing off; ${mismatches.length} mismatches, '
        '${knownLegacyBugs.length} known legacy bugs');
    printOnFailure(mismatches.take(5).join('\n\n'));
    expect(mismatches, isEmpty, reason: '${mismatches.length} mismatches');
    expect(compared, _positions * 21);
  });
}

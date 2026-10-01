/// Shared by the Portes legacy differential and the legacy benchmark:
/// mapping legacy boards to `tavli_core` positions, the seeded legacy
/// self-play, and the known-legacy-bug list (SP1 plan Task 18).
library;

import 'dart:convert';
import 'dart:math';

import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/ai/engine/ai_player.dart';
import 'package:tavli/features/game/data/models/board_state.dart';
import 'package:tavli/features/game/data/models/dice_roll.dart';
import 'package:tavli/features/game/domain/engine/game_engine.dart';
import 'package:tavli_core/tavli_core.dart' hide DiceRoll;

/// The core position for a legacy hitting-layout board (matrix §1):
/// `points[i] > 0` is player 1 = `Side.one` on pip `i + 1`;
/// `points[i] < 0` is player 2 = `Side.two` on pip `24 - i`; bars and
/// borne-off counts map directly. Throws [StateError] if the borne-off
/// counts disagree.
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
  if (p.borneOff(Side.one) != b.borneOff1 ||
      p.borneOff(Side.two) != b.borneOff2) {
    throw StateError('borne-off counts differ: $b vs $p');
  }
  return p;
}

/// The core side for the legacy active player.
Side sideToMove(BoardState b) => b.activePlayer == 1 ? Side.one : Side.two;

/// The core dice for a legacy roll: `[d, d, d, d]` for a double.
List<int> coreDice(DiceRoll r) =>
    r.isDoubles ? [r.die1, r.die1, r.die1, r.die1] : [r.die1, r.die2];

/// The 21 distinct rolls, higher die first.
final List<DiceRoll> allRolls = [
  for (var a = 1; a <= 6; a++)
    for (var b = a; b <= 6; b++) DiceRoll(die1: b, die2: a),
];

/// Seeded legacy easy-vs-easy self-play (dice `Random(42)`, AI
/// `Random(7)`, as the legacy baseline). [keep] decides from the ply
/// number whether the board before that ply is sampled; a finished game
/// starts a new one unless [stopAtGameEnd]. Returns up to [count] boards
/// within [maxPlies].
List<BoardState> legacySelfPlay({
  required int count,
  required bool Function(int ply) keep,
  int maxPlies = 1 << 30,
  bool stopAtGameEnd = false,
}) {
  const eng = GameEngine();
  final ai = AiPlayer(rng: Random(7));
  final rng = Random(42);
  final out = <BoardState>[];
  var board = BoardState.initial();
  for (var ply = 0; ply < maxPlies && out.length < count; ply++) {
    if (keep(ply)) out.add(board);
    final turn =
        ai.selectTurn(board, DiceRoll.random(rng), DifficultyLevel.easy);
    if (turn != null) board = eng.applyMoves(board, turn.moves);
    if (eng.isGameOver(board)) {
      if (stopAtGameEnd) break;
      board = BoardState.initial(activePlayer: board.activePlayer == 1 ? 2 : 1);
    } else {
      board = eng.endTurn(board);
    }
  }
  return out;
}

/// The legacy baseline's 12 positions (`test/bench/legacy_engine_bench_
/// test.dart`): the board after every even ply of the first 60, player 2
/// to move, stopping at the first game end.
List<BoardState> baselinePositions() => legacySelfPlay(
      count: 12,
      keep: (ply) => ply.isOdd, // the board after ply k is sampled at k + 1
      maxPlies: 60,
      stopAtGameEnd: true,
    );

/// A legacy bug the differential tolerates: why the legacy result is
/// wrong, and the cases (`Mismatch.key`) it explains.
final class KnownLegacyBug {
  const KnownLegacyBug(this.why, this.cases);

  final String why;
  final Set<String> cases;
}

/// Known legacy bugs, keyed by the matrix rule ID the legacy generator
/// breaks (e.g. `'G6'`). Empty: the differential found none.
const knownLegacyBugs = <String, KnownLegacyBug>{};

/// One position x roll where the engines disagree.
final class Mismatch {
  Mismatch(this.position, this.side, this.roll, this.onlyLegacy, this.onlyCore);

  final Position position;
  final Side side;
  final DiceRoll roll;
  final Set<Position> onlyLegacy, onlyCore;

  /// What a [KnownLegacyBug] lists to explain this case.
  String get key =>
      '${jsonEncode(position.toJson())} ${side.name} ${roll.die1}-${roll.die2}';

  @override
  String toString() => '$key\n  $position\n'
      '  only legacy (${onlyLegacy.length}): ${onlyLegacy.take(3).toList()}\n'
      '  only core (${onlyCore.length}): ${onlyCore.take(3).toList()}';
}

/// The mismatch between [legacy] and [core] finals, or null if equal.
Mismatch? compareFinals(Position p, Side side, DiceRoll roll,
    Set<Position> legacy, Set<Position> core) {
  final onlyLegacy = legacy.difference(core),
      onlyCore = core.difference(legacy);
  if (onlyLegacy.isEmpty && onlyCore.isEmpty) return null;
  return Mismatch(p, side, roll, onlyLegacy, onlyCore);
}

/// The rule ID of the [bugs] entry that lists [m], or null.
String? knownBugRule(Mismatch m,
    [Map<String, KnownLegacyBug> bugs = knownLegacyBugs]) {
  for (final e in bugs.entries) {
    if (e.value.cases.contains(m.key)) return e.key;
  }
  return null;
}

/// The [mismatches] no entry of [bugs] explains.
List<Mismatch> unexplained(List<Mismatch> mismatches,
        [Map<String, KnownLegacyBug> bugs = knownLegacyBugs]) =>
    [
      for (final m in mismatches)
        if (knownBugRule(m, bugs) == null) m,
    ];

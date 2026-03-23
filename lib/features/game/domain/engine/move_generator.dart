import '../../data/models/board_state.dart';
import '../../data/models/dice_roll.dart';
import '../../data/models/move.dart';
import '../../data/models/turn.dart';
import '../../../../core/constants/game_constants.dart';
import 'game_engine.dart';
import 'move_validator.dart';

/// Generates all legal turns (complete sets of moves) for a dice roll.
///
/// Implements the full backgammon mandatory-play rules:
/// - Must use both dice if possible.
/// - If only one die can be played, must play the larger.
/// - Doubles give 4 moves; play as many as possible.
class MoveGenerator {
  final GameEngine _engine;
  final MoveValidator _validator;

  const MoveGenerator({
    GameEngine engine = const GameEngine(),
    MoveValidator validator = const MoveValidator(),
  })  : _engine = engine,
        _validator = validator;

  /// Generate all legal turns for [state] with [roll].
  ///
  /// Returns a deduplicated list of [Turn] objects, each containing a
  /// complete legal sequence of moves. Empty list if no moves possible.
  List<Turn> generateAllLegalTurns(BoardState state, DiceRoll roll) {
    if (roll.isDoubles) {
      return _generateDoublesTurns(state, roll);
    }
    return _generateNormalTurns(state, roll);
  }

  /// Generate legal single-checker moves for [state] using die value [die].
  ///
  /// Useful for UI: when a checker is selected, show where it can go.
  List<Move> generateMovesForDie(BoardState state, int die) {
    return _findAllSingleMoves(state, die);
  }

  // ═══════════════════════════════════════════════════════════════
  //  Normal rolls (two different dice)
  // ═══════════════════════════════════════════════════════════════

  List<Turn> _generateNormalTurns(BoardState state, DiceRoll roll) {
    final allTurns = <Turn>[];

    // Try die1 first, then die2.
    _generateSequential(state, [roll.die1, roll.die2], [], allTurns, roll);
    // Try die2 first, then die1.
    _generateSequential(state, [roll.die2, roll.die1], [], allTurns, roll);

    // Deduplicate by final board state.
    final deduped = _deduplicateTurns(allTurns);

    // Apply mandatory play filtering.
    return _filterMandatoryPlay(deduped, roll);
  }

  /// Recursively generate move sequences trying dice in order.
  void _generateSequential(
    BoardState state,
    List<int> remainingDice,
    List<Move> movesSoFar,
    List<Turn> results,
    DiceRoll originalRoll,
  ) {
    if (remainingDice.isEmpty) {
      if (movesSoFar.isNotEmpty) {
        results.add(Turn(
          roll: originalRoll,
          moves: List.unmodifiable(movesSoFar),
        ));
      }
      return;
    }

    final die = remainingDice.first;
    final rest = remainingDice.sublist(1);
    final moves = _findAllSingleMoves(state, die);

    if (moves.isEmpty) {
      // Can't use this die. Record what we have and try remaining dice.
      if (movesSoFar.isNotEmpty) {
        results.add(Turn(
          roll: originalRoll,
          moves: List.unmodifiable(movesSoFar),
        ));
      }
      // Try remaining dice even if this one failed.
      _generateSequential(state, rest, movesSoFar, results, originalRoll);
      return;
    }

    for (final move in moves) {
      final newState = _engine.applyMove(state, move);
      final newMoves = [...movesSoFar, move];
      _generateSequential(newState, rest, newMoves, results, originalRoll);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  Doubles
  // ═══════════════════════════════════════════════════════════════

  List<Turn> _generateDoublesTurns(BoardState state, DiceRoll roll) {
    final allTurns = <Turn>[];
    _generateDoublesRecursive(state, roll.die1, 4, [], allTurns);

    final deduped = _deduplicateTurns(allTurns);

    // For doubles: must play as many as possible.
    if (deduped.isEmpty) return [];

    final maxMoves = deduped.map((t) => t.moves.length).reduce(
        (a, b) => a > b ? a : b);
    return deduped.where((t) => t.moves.length == maxMoves).toList();
  }

  void _generateDoublesRecursive(
    BoardState state,
    int die,
    int remaining,
    List<Move> movesSoFar,
    List<Turn> results,
  ) {
    if (remaining == 0) {
      if (movesSoFar.isNotEmpty) {
        results.add(Turn(
          roll: DiceRoll(die1: die, die2: die),
          moves: List.unmodifiable(movesSoFar),
        ));
      }
      return;
    }

    final moves = _findAllSingleMoves(state, die);

    if (moves.isEmpty) {
      // Can't use any more dice.
      if (movesSoFar.isNotEmpty) {
        results.add(Turn(
          roll: DiceRoll(die1: die, die2: die),
          moves: List.unmodifiable(movesSoFar),
        ));
      }
      return;
    }

    for (final move in moves) {
      final newState = _engine.applyMove(state, move);
      _generateDoublesRecursive(
        newState,
        die,
        remaining - 1,
        [...movesSoFar, move],
        results,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  Single-move generation (for one die value)
  // ═══════════════════════════════════════════════════════════════

  /// Find all legal single-checker moves for the active player using [die].
  List<Move> _findAllSingleMoves(BoardState state, int die) {
    final player = state.activePlayer;
    final moves = <Move>[];

    // If player has checkers on bar, must enter those first.
    if (state.barCount(player) > 0) {
      final move = _tryBarEntry(state, die, player);
      if (move != null) moves.add(move);
      return moves; // Can only enter from bar when on bar.
    }

    // Check bearing off eligibility.
    final canBear = state.allInHome(player);

    // Try moving each checker.
    for (int i = 0; i < 24; i++) {
      if (state.checkerCount(i, player) == 0) continue;

      // Normal move.
      final to = player == 1 ? i - die : i + die;

      if (to >= 0 && to <= 23) {
        if (state.isPointOpen(to, player)) {
          moves.add(Move(
            fromPoint: i,
            toPoint: to,
            dieUsed: die,
            isHit: state.isBlot(to, player),
          ));
        }
      } else if (canBear) {
        // Potential bear-off.
        final bearOffMove = Move(
          fromPoint: i,
          toPoint: GameConstants.bearOffIndex,
          dieUsed: die,
        );
        if (_validator.isMoveValid(state, bearOffMove)) {
          moves.add(bearOffMove);
        }
      }
    }

    return moves;
  }

  /// Try to enter a checker from the bar.
  Move? _tryBarEntry(BoardState state, int die, int player) {
    final target = player == 1 ? 24 - die : die - 1;
    if (state.isPointOpen(target, player)) {
      return Move(
        fromPoint: GameConstants.barIndex,
        toPoint: target,
        dieUsed: die,
        isHit: state.isBlot(target, player),
      );
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  //  Mandatory play filtering
  // ═══════════════════════════════════════════════════════════════

  /// Apply mandatory-play rules:
  /// 1. Must use both dice if possible.
  /// 2. If only one die can be played, must play the larger.
  List<Turn> _filterMandatoryPlay(List<Turn> turns, DiceRoll roll) {
    if (turns.isEmpty) return [];

    final maxMoves = turns.map((t) => t.moves.length).reduce(
        (a, b) => a > b ? a : b);

    // If any turn uses both dice, filter to only those.
    if (maxMoves >= 2) {
      return turns.where((t) => t.moves.length == maxMoves).toList();
    }

    // Only 1-move turns exist. Must play the larger die.
    if (!roll.isDoubles && roll.die1 != roll.die2) {
      final larger = roll.die1 > roll.die2 ? roll.die1 : roll.die2;
      final largerTurns =
          turns.where((t) => t.moves.any((m) => m.dieUsed == larger)).toList();

      // If the larger die can be played, must play it.
      if (largerTurns.isNotEmpty) return largerTurns;
    }

    // Otherwise play whatever is available.
    return turns;
  }

  // ═══════════════════════════════════════════════════════════════
  //  Deduplication
  // ═══════════════════════════════════════════════════════════════

  /// Deduplicate turns that result in the same final board state.
  List<Turn> _deduplicateTurns(List<Turn> turns) {
    final seen = <String>{};
    final unique = <Turn>[];

    for (final turn in turns) {
      // Build a normalized key: the sorted list of (from, to) pairs.
      final key = _turnKey(turn);
      if (seen.add(key)) {
        unique.add(turn);
      }
    }
    return unique;
  }

  /// Create a string key for deduplication.
  /// We use the final board state hash as the key — two turns with
  /// different move orders but same result are equivalent.
  String _turnKey(Turn turn) {
    // Sort moves to normalize order.
    final sorted = turn.moves.toList()
      ..sort((a, b) {
        final cmp = a.fromPoint.compareTo(b.fromPoint);
        if (cmp != 0) return cmp;
        return a.toPoint.compareTo(b.toPoint);
      });
    return sorted.map((m) => '${m.fromPoint}:${m.toPoint}:${m.dieUsed}').join('|');
  }
}

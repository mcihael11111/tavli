import '../../data/models/board_state.dart';
import '../../data/models/move.dart';

/// Validates whether a single move is legal on a given board state.
class MoveValidator {
  const MoveValidator();

  /// Check if [move] is legal for [state.activePlayer] on [state].
  ///
  /// This validates a single die move in isolation. It does NOT enforce
  /// the mandatory-play rule (both dice, larger die) — that is handled
  /// by the move generator which filters complete turns.
  bool isMoveValid(BoardState state, Move move) {
    final player = state.activePlayer;

    // ── Bar entry ────────────────────────────────────────────
    if (state.barCount(player) > 0) {
      // Must enter from bar before any other move.
      if (!move.isBarEntry) return false;
      return _isBarEntryValid(state, move, player);
    }

    // If on bar, only bar entry is allowed (handled above).
    if (move.isBarEntry) {
      return state.barCount(player) > 0 &&
          _isBarEntryValid(state, move, player);
    }

    // ── Bear off ─────────────────────────────────────────────
    if (move.isBearOff) {
      return _isBearOffValid(state, move, player);
    }

    // ── Normal move ──────────────────────────────────────────
    return _isNormalMoveValid(state, move, player);
  }

  bool _isBarEntryValid(BoardState state, Move move, int player) {
    // Player 1 enters into opponent's home (points 18-23),
    // mapping die value d → point index (24 - d) = 23, 22, ... 18.
    // Player 2 enters into opponent's home (points 0-5),
    // mapping die value d → point index (d - 1) = 0, 1, ... 5.
    final expectedTarget = player == 1
        ? 24 - move.dieUsed // die 1→23, die 6→18
        : move.dieUsed - 1; // die 1→0,  die 6→5

    if (move.toPoint != expectedTarget) return false;
    return state.isPointOpen(move.toPoint, player);
  }

  bool _isBearOffValid(BoardState state, Move move, int player) {
    if (!state.allInHome(player)) return false;

    // Verify the checker exists at fromPoint.
    if (state.checkerCount(move.fromPoint, player) == 0) return false;

    if (player == 1) {
      // Player 1 bears off from points 0-5.
      // Point index i bears off with die value (i + 1).
      final exactDie = move.fromPoint + 1;
      if (move.dieUsed == exactDie) return true;

      // Can bear off with a higher die if no checker on a higher point.
      if (move.dieUsed > exactDie) {
        // Check that there are no checkers on any point higher than fromPoint.
        for (int i = move.fromPoint + 1; i <= 5; i++) {
          if (state.points[i] > 0) return false;
        }
        return true;
      }

      // Die is smaller than the point — can't bear off, must move within home.
      return false;
    } else {
      // Player 2 bears off from points 18-23.
      // Point index i bears off with die value (24 - i).
      final exactDie = 24 - move.fromPoint;
      if (move.dieUsed == exactDie) return true;

      if (move.dieUsed > exactDie) {
        for (int i = move.fromPoint - 1; i >= 18; i--) {
          if (state.points[i] < 0) return false;
        }
        return true;
      }
      return false;
    }
  }

  bool _isNormalMoveValid(BoardState state, Move move, int player) {
    // Check source has player's checker.
    if (state.checkerCount(move.fromPoint, player) == 0) return false;

    // Calculate expected destination.
    final expectedTo = player == 1
        ? move.fromPoint - move.dieUsed
        : move.fromPoint + move.dieUsed;

    // If destination is off the board, it could be a bear-off (handled separately).
    if (expectedTo < 0 || expectedTo > 23) return false;

    if (move.toPoint != expectedTo) return false;
    return state.isPointOpen(move.toPoint, player);
  }
}

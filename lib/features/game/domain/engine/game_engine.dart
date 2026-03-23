import '../../data/models/board_state.dart';
import '../../data/models/move.dart';
import '../../data/models/game_result.dart';
import '../../../../core/constants/game_constants.dart';
import 'move_validator.dart';

/// Core game engine: applies moves, checks game-over, evaluates results.
class GameEngine {
  final MoveValidator _validator;

  const GameEngine({MoveValidator validator = const MoveValidator()})
      : _validator = validator;

  /// Validate a single move.
  bool isMoveValid(BoardState state, Move move) =>
      _validator.isMoveValid(state, move);

  /// Apply a single [move] to [state], returning the new board state.
  ///
  /// Assumes the move has already been validated.
  /// Does NOT switch the active player — that happens at turn end.
  BoardState applyMove(BoardState state, Move move) {
    final player = state.activePlayer;
    final pts = List<int>.of(state.points);
    int bar1 = state.bar1;
    int bar2 = state.bar2;
    int borneOff1 = state.borneOff1;
    int borneOff2 = state.borneOff2;

    // ── Remove checker from source ───────────────────────────
    if (move.isBarEntry) {
      if (player == 1) {
        bar1--;
      } else {
        bar2--;
      }
    } else {
      if (player == 1) {
        pts[move.fromPoint]--;
      } else {
        pts[move.fromPoint]++;
      }
    }

    // ── Place checker at destination ─────────────────────────
    if (move.isBearOff) {
      if (player == 1) {
        borneOff1++;
      } else {
        borneOff2++;
      }
    } else {
      // Check for hit (blot).
      final isHit = state.isBlot(move.toPoint, player);

      if (isHit) {
        // Send opponent's checker to bar.
        if (player == 1) {
          pts[move.toPoint] = 0; // remove opponent's checker
          bar2++;
        } else {
          pts[move.toPoint] = 0;
          bar1++;
        }
      }

      // Place our checker.
      if (player == 1) {
        pts[move.toPoint]++;
      } else {
        pts[move.toPoint]--;
      }
    }

    return state.copyWith(
      points: pts,
      bar1: bar1,
      bar2: bar2,
      borneOff1: borneOff1,
      borneOff2: borneOff2,
    );
  }

  /// Apply a sequence of moves (a full turn).
  BoardState applyMoves(BoardState state, List<Move> moves) {
    BoardState current = state;
    for (final move in moves) {
      current = applyMove(current, move);
    }
    return current;
  }

  /// Switch the active player (call at end of turn).
  BoardState endTurn(BoardState state) {
    return state.copyWith(
      activePlayer: state.activePlayer == 1 ? 2 : 1,
    );
  }

  /// Whether all checkers are in the home board for [player].
  bool canBearOff(BoardState state, int player) => state.allInHome(player);

  /// Whether the game is over (a player has borne off all 15).
  bool isGameOver(BoardState state) {
    return state.borneOff1 == GameConstants.checkersPerPlayer ||
        state.borneOff2 == GameConstants.checkersPerPlayer;
  }

  /// Get the game result. Returns null if game is not over.
  GameResult? getResult(BoardState state) {
    if (!isGameOver(state)) return null;

    final int winner;
    final int loser;

    if (state.borneOff1 == GameConstants.checkersPerPlayer) {
      winner = 1;
      loser = 2;
    } else {
      winner = 2;
      loser = 1;
    }

    final loserBorneOff = state.borneOffCount(loser);
    final loserBar = state.barCount(loser);

    // Check for backgammon: loser has 0 borne off AND has a checker
    // on the bar or in the winner's home board.
    if (loserBorneOff == 0) {
      bool hasCheckerInWinnerHome = false;

      if (winner == 1) {
        // Winner is player 1, home is 0-5. Loser (P2) has checkers there if negative.
        if (loserBar > 0) hasCheckerInWinnerHome = true;
        for (int i = 0; i <= 5; i++) {
          if (state.points[i] < 0) {
            hasCheckerInWinnerHome = true;
            break;
          }
        }
      } else {
        // Winner is player 2, home is 18-23. Loser (P1) has checkers there if positive.
        if (loserBar > 0) hasCheckerInWinnerHome = true;
        for (int i = 18; i <= 23; i++) {
          if (state.points[i] > 0) {
            hasCheckerInWinnerHome = true;
            break;
          }
        }
      }

      return GameResult(
        winner: winner,
        type: hasCheckerInWinnerHome
            ? GameResultType.backgammon
            : GameResultType.gammon,
        cubeValue: state.doublingCubeValue,
      );
    }

    return GameResult(
      winner: winner,
      type: GameResultType.single,
      cubeValue: state.doublingCubeValue,
    );
  }

  /// Accept a double: cube value doubles, ownership passes to acceptor.
  BoardState acceptDouble(BoardState state) {
    final offerer = state.activePlayer;
    final acceptor = offerer == 1 ? 2 : 1;
    return state.copyWith(
      doublingCubeValue: state.doublingCubeValue * 2,
      cubeOwner: acceptor,
    );
  }

  /// Whether [player] may offer a double.
  bool canOfferDouble(BoardState state, int player) {
    // Must be the active player at the start of their turn.
    if (state.activePlayer != player) return false;
    // Cube must be centered OR owned by this player.
    if (state.cubeOwner != null && state.cubeOwner != player) return false;
    return true;
  }
}

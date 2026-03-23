import '../../../data/models/board_state.dart';
import '../../../data/models/dice_roll.dart';
import '../../../data/models/game_result.dart';
import '../../../data/models/move.dart';
import '../../../data/models/turn.dart';
import '../../../../../core/constants/game_constants.dart';

/// Fevga (Φεύγα) game engine — running variant.
///
/// Key rules:
/// - All 15 checkers start on one point: P1 at index 0, P2 at index 12.
/// - Both players move in the same direction (counterclockwise / ascending index).
/// - P1: 0→1→...→23→bear off. P2: 12→13→...→23→0→...→11→bear off.
/// - No hitting at all.
/// - A single opponent checker blocks the point.
/// - Max 5 consecutive blocked points (can't create a 6-prime).
/// - Starting quadrant rule: can't block all 6 starting quadrant points
///   unless opponent has moved past.
/// - Bear off: P1 from 18-23, P2 from 6-11.
class FevgaEngine {
  const FevgaEngine();

  /// Create initial board state for Fevga.
  BoardState initialState({int activePlayer = 1}) {
    final pts = List<int>.filled(24, 0);
    pts[0] = 15; // Player 1 starts at index 0
    pts[12] = -15; // Player 2 starts at index 12
    return BoardState(points: pts, activePlayer: activePlayer);
  }

  /// Check if a point is open for the player.
  /// In Fevga, even a single opponent checker blocks.
  bool isPointOpen(BoardState state, int pointIndex, int player) {
    final val = state.points[pointIndex];
    if (player == 1) return val >= 0; // No opponent checkers at all.
    return val <= 0;
  }

  /// Check if placing at target would create an illegal 6+ consecutive block.
  bool wouldCreateIllegalPrime(BoardState state, int player, int targetPoint) {
    final pts = List<int>.of(state.points);
    if (player == 1) {
      pts[targetPoint]++;
    } else {
      pts[targetPoint]--;
    }

    int consecutive = 0;
    // Check the full circle (need to wrap around).
    for (int offset = 0; offset < 24; offset++) {
      final i = offset % 24;
      final hasBlock = player == 1 ? pts[i] >= 1 : pts[i] <= -1;
      if (hasBlock) {
        consecutive++;
        if (consecutive >= 6) return true;
      } else {
        consecutive = 0;
      }
    }
    return false;
  }

  /// Check the starting quadrant blocking rule.
  /// Player cannot block all 6 points of their starting quadrant
  /// unless opponent has already moved past it.
  bool wouldViolateStartingQuadrantRule(
      BoardState state, int player, int targetPoint) {
    final startQuadrantBegin = player == 1 ? 0 : 12;
    final startQuadrantEnd = startQuadrantBegin + 5;

    // Check if target is in starting quadrant.
    if (targetPoint < startQuadrantBegin || targetPoint > startQuadrantEnd) {
      return false;
    }

    // Count blocked points in starting quadrant (including the new one).
    int blockedCount = 0;
    for (int i = startQuadrantBegin; i <= startQuadrantEnd; i++) {
      bool isBlocked;
      if (i == targetPoint) {
        // Will be blocked after this move.
        isBlocked = true;
      } else {
        isBlocked = player == 1 ? state.points[i] >= 1 : state.points[i] <= -1;
      }
      if (isBlocked) blockedCount++;
    }

    if (blockedCount < 6) return false;

    // All 6 would be blocked — only allowed if opponent has already passed through.
    if (player == 1) {
      // P1's start quadrant is 0-5. Opponent is P2 (starts at 12, moves 12→23→0→11).
      // P2 has passed if no P2 checkers remain on points 12-23.
      for (int j = 12; j <= 23; j++) {
        if (state.points[j] < 0) return true; // P2 hasn't passed yet — illegal.
      }
      return false; // P2 has passed through — allowed.
    } else {
      // P2's start quadrant is 12-17. Opponent is P1 (starts at 0, moves 0→23).
      // P1 has passed if no P1 checkers remain on points 0-11.
      for (int j = 0; j <= 11; j++) {
        if (state.points[j] > 0) return true; // P1 hasn't passed yet — illegal.
      }
      return false; // P1 has passed through — allowed.
    }
  }

  /// Apply a single move.
  BoardState applyMove(BoardState state, Move move) {
    final player = state.activePlayer;
    final pts = List<int>.of(state.points);

    // Remove from source.
    if (move.fromPoint >= 0) {
      if (player == 1) {
        pts[move.fromPoint]--;
      } else {
        pts[move.fromPoint]++;
      }
    }

    // Bear off.
    if (move.toPoint == GameConstants.bearOffIndex) {
      return state.copyWith(
        points: pts,
        borneOff1: player == 1 ? state.borneOff1 + 1 : null,
        borneOff2: player == 2 ? state.borneOff2 + 1 : null,
      );
    }

    // Place at destination. No hitting in Fevga.
    if (player == 1) {
      pts[move.toPoint]++;
    } else {
      pts[move.toPoint]--;
    }

    return state.copyWith(points: pts);
  }

  /// Generate all legal moves for a single die.
  List<Move> generateMovesForDie(BoardState state, int die) {
    final player = state.activePlayer;
    final moves = <Move>[];

    for (int i = 0; i < 24; i++) {
      if (state.checkerCount(i, player) == 0) continue;

      // Both players move in ascending direction (counterclockwise).
      // P1: 0→23, P2: 12→23→0→11 (wraps around).
      final target = _targetPoint(i, die, player);

      // Bear off check.
      if (_canBearOffMove(state, i, die, player)) {
        moves.add(Move(
          fromPoint: i,
          toPoint: GameConstants.bearOffIndex,
          dieUsed: die,
        ));
        continue;
      }

      if (target < 0 || target > 23) continue;

      if (!isPointOpen(state, target, player)) continue;

      // Check 6-prime rule.
      if (wouldCreateIllegalPrime(state, player, target)) continue;

      // Check starting quadrant rule.
      if (wouldViolateStartingQuadrantRule(state, player, target)) continue;

      moves.add(Move(fromPoint: i, toPoint: target, dieUsed: die));
    }

    return moves;
  }

  /// Calculate target point for a move.
  int _targetPoint(int from, int die, int player) {
    if (player == 1) {
      // P1 moves 0→23.
      return from + die;
    } else {
      // P2 moves counterclockwise: 12→23, then wraps to 0→11.
      final target = from + die;
      if (target > 23) return target - 24; // Wrap around.
      return target;
    }
  }

  /// Check if all checkers are in home board.
  bool allInHome(BoardState state, int player) {
    if (player == 1) {
      // P1 home = 18-23.
      for (int i = 0; i < 18; i++) {
        if (state.points[i] > 0) return false;
      }
    } else {
      // P2 home = 6-11.
      for (int i = 0; i < 6; i++) {
        if (state.points[i] < 0) return false;
      }
      for (int i = 12; i < 24; i++) {
        if (state.points[i] < 0) return false;
      }
    }
    return true;
  }

  bool _canBearOffMove(BoardState state, int fromPoint, int die, int player) {
    if (!allInHome(state, player)) return false;

    if (player == 1) {
      // P1 bears off from 18-23. Target 24+ = bear off.
      final target = fromPoint + die;
      if (target == 24) return true;
      if (target > 24) {
        // Can bear off from highest if no higher checkers.
        for (int i = fromPoint + 1; i <= 23; i++) {
          if (state.points[i] > 0) return false;
        }
        return fromPoint >= 18;
      }
    } else {
      // P2 bears off from 6-11. Target wraps: 6+die should reach 12+ to bear off.
      // Actually P2 moves 6→7→...→11→off.
      final target = fromPoint + die;
      if (target == 12) return true;
      if (target > 12 && fromPoint >= 6 && fromPoint <= 11) {
        // Can bear off from highest if no higher checkers.
        for (int i = fromPoint + 1; i <= 11; i++) {
          if (state.points[i] < 0) return false;
        }
        return true;
      }
    }
    return false;
  }

  /// Generate all legal turns.
  List<Turn> generateAllLegalTurns(BoardState state, DiceRoll roll) {
    final results = <Turn>[];

    if (roll.isDoubles) {
      _generateDoublesRecursive(state, roll.die1, 4, [], results);
    } else {
      _generateSequential(state, roll.die1, roll.die2, [], results);
      _generateSequential(state, roll.die2, roll.die1, [], results);
    }

    return _filterAndDeduplicate(results, roll);
  }

  void _generateSequential(BoardState state, int die1, int die2,
      List<Move> movesSoFar, List<Turn> results) {
    final moves1 = generateMovesForDie(state, die1);

    if (moves1.isEmpty) {
      final moves2 = generateMovesForDie(state, die2);
      if (moves2.isEmpty) {
        if (movesSoFar.isNotEmpty) {
          results.add(Turn(
            roll: DiceRoll(die1: die1, die2: die2),
            moves: List.of(movesSoFar),
          ));
        }
        return;
      }
      for (final m2 in moves2) {
        results.add(Turn(
          roll: DiceRoll(die1: die1, die2: die2),
          moves: [...movesSoFar, m2],
        ));
      }
      return;
    }

    for (final m1 in moves1) {
      final after1 = applyMove(state, m1);
      final stateForDie2 = after1.copyWith(activePlayer: state.activePlayer);
      final moves2 = generateMovesForDie(stateForDie2, die2);

      if (moves2.isEmpty) {
        results.add(Turn(
          roll: DiceRoll(die1: die1, die2: die2),
          moves: [...movesSoFar, m1],
        ));
      } else {
        for (final m2 in moves2) {
          results.add(Turn(
            roll: DiceRoll(die1: die1, die2: die2),
            moves: [...movesSoFar, m1, m2],
          ));
        }
      }
    }
  }

  void _generateDoublesRecursive(BoardState state, int die, int remaining,
      List<Move> movesSoFar, List<Turn> results) {
    if (remaining == 0) {
      results.add(Turn(
        roll: DiceRoll(die1: die, die2: die),
        moves: List.of(movesSoFar),
      ));
      return;
    }

    final moves = generateMovesForDie(state, die);
    if (moves.isEmpty) {
      if (movesSoFar.isNotEmpty) {
        results.add(Turn(
          roll: DiceRoll(die1: die, die2: die),
          moves: List.of(movesSoFar),
        ));
      }
      return;
    }

    for (final m in moves) {
      final after = applyMove(state, m);
      final nextState = after.copyWith(activePlayer: state.activePlayer);
      _generateDoublesRecursive(
          nextState, die, remaining - 1, [...movesSoFar, m], results);
    }
  }

  List<Turn> _filterAndDeduplicate(List<Turn> turns, DiceRoll roll) {
    if (turns.isEmpty) return turns;

    final maxMoves =
        turns.map((t) => t.moves.length).reduce((a, b) => a > b ? a : b);
    var filtered = turns.where((t) => t.moves.length == maxMoves).toList();

    if (!roll.isDoubles && maxMoves == 1) {
      final larger = roll.die1 > roll.die2 ? roll.die1 : roll.die2;
      final usesLarger = filtered.where((t) => t.moves.first.dieUsed == larger);
      if (usesLarger.isNotEmpty) {
        filtered = usesLarger.toList();
      }
    }

    final seen = <String>{};
    return filtered.where((t) {
      final key = t.moves.map((m) => '${m.fromPoint}-${m.toPoint}').join(',');
      return seen.add(key);
    }).toList();
  }

  /// Switch active player.
  BoardState endTurn(BoardState state) {
    return state.copyWith(activePlayer: state.activePlayer == 1 ? 2 : 1);
  }

  /// Check if game is over.
  bool isGameOver(BoardState state) {
    return state.borneOff1 >= 15 || state.borneOff2 >= 15;
  }

  /// Get game result.
  GameResult? getResult(BoardState state) {
    if (!isGameOver(state)) return null;

    final winner = state.borneOff1 >= 15 ? 1 : 2;
    final loser = winner == 1 ? 2 : 1;
    final loserBorneOff = state.borneOffCount(loser);

    if (loserBorneOff == 0) {
      return GameResult(
        winner: winner,
        type: GameResultType.gammon,
        cubeValue: state.doublingCubeValue,
      );
    }

    return GameResult(
      winner: winner,
      type: GameResultType.single,
      cubeValue: state.doublingCubeValue,
    );
  }
}

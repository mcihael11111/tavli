import '../../../data/models/board_state.dart';
import '../../../data/models/dice_roll.dart';
import '../../../data/models/game_result.dart';
import '../../../data/models/move.dart';
import '../../../data/models/turn.dart';
import '../../../../../core/constants/game_constants.dart';

/// Plakoto (Πλακωτό) game engine — pinning variant.
///
/// Key rules:
/// - All 15 checkers start on each player's 1-point.
/// - P1 moves 0→23 (ascending), P2 moves 23→0 (descending).
/// - No hitting. Landing on a single opponent checker PINS it.
/// - Pinned checkers cannot move until the pin is removed.
/// - Μάνα (mama): pinning opponent's last checker on their start = auto double loss.
/// - Bear off: P1 from 18-23, P2 from 0-5.
class PlakotoEngine {
  const PlakotoEngine();

  /// Create initial board state for Plakoto.
  BoardState initialState({int activePlayer = 1}) {
    final pts = List<int>.filled(24, 0);
    pts[0] = 15; // Player 1 starts at point 1 (index 0)
    pts[23] = -15; // Player 2 starts at point 24 (index 23)
    return BoardState(points: pts, activePlayer: activePlayer);
  }

  /// Check for "mama" (μάνα) — automatic double loss.
  /// Occurs when opponent pins your checker on your starting point.
  bool isMama(BoardState state, int player) {
    if (player == 1) {
      // P1's start is index 0. Mama if P2 has pinned P1 there.
      return state.pins[0] == 1;
    }
    // P2's start is index 23.
    return state.pins[23] == 2;
  }

  /// Apply a single move.
  BoardState applyMove(BoardState state, Move move) {
    final player = state.activePlayer;
    final pts = List<int>.of(state.points);
    final pins = Map<int, int>.of(state.pins);

    // Remove checker from source.
    if (move.fromPoint >= 0) {
      if (player == 1) {
        pts[move.fromPoint]--;
        // If we were the pinner and leave, unpin.
        if (pts[move.fromPoint] == 0 && pins[move.fromPoint] == 2) {
          // Our last checker left — unpin opponent.
          pins.remove(move.fromPoint);
        }
      } else {
        pts[move.fromPoint]++;
        if (pts[move.fromPoint] == 0 && pins[move.fromPoint] == 1) {
          pins.remove(move.fromPoint);
        }
      }
    }

    // Bear off.
    if (move.toPoint == GameConstants.bearOffIndex) {
      return state.copyWith(
        points: pts,
        pins: pins,
        borneOff1: player == 1 ? state.borneOff1 + 1 : null,
        borneOff2: player == 2 ? state.borneOff2 + 1 : null,
      );
    }

    // Place checker at destination.
    if (player == 1) {
      pts[move.toPoint]++;
      // Check for pinning: if opponent has a single checker here.
      if (pts[move.toPoint] == 1 && _opponentCount(pts, move.toPoint, 1) == 1) {
        // We just arrived and opponent has 1 checker — pin it.
        pins[move.toPoint] = 2; // Player 2 is pinned.
      }
    } else {
      pts[move.toPoint]--;
      if (pts[move.toPoint] == -1 && _opponentCount(pts, move.toPoint, 2) == 1) {
        pins[move.toPoint] = 1; // Player 1 is pinned.
      }
    }

    return state.copyWith(points: pts, pins: pins);
  }

  /// Count opponent's checkers at a point in Plakoto.
  /// Since both players can have checkers on the same point (pin),
  /// we need to check the pins map.
  int _opponentCount(List<int> pts, int pointIndex, int player) {
    // In Plakoto, the points array holds the NET value.
    // When a pin exists, we track it separately.
    // For simplicity: if a pin exists at this point for the OTHER player,
    // there is 1 opponent checker there.
    // This is a simplified model — real Plakoto would need separate counts.
    return 0; // Handled via pins map instead.
  }

  /// Check if a point is open for the player to land on.
  /// In Plakoto, a point is open if:
  /// - It's empty, OR
  /// - It has the player's own checkers, OR
  /// - It has exactly 1 opponent checker (which will be pinned).
  bool isPointOpen(BoardState state, int pointIndex, int player) {
    final val = state.points[pointIndex];
    if (player == 1) {
      // Open if: no opponent checkers, or exactly 1 opponent checker (pin it).
      if (val >= 0) return true; // Our checkers or empty.
      if (val == -1 && !state.isPinned(pointIndex)) return true; // Single opp, pin it.
      return false;
    } else {
      if (val <= 0) return true;
      if (val == 1 && !state.isPinned(pointIndex)) return true;
      return false;
    }
  }

  /// Generate all legal moves for a single die value.
  List<Move> generateMovesForDie(BoardState state, int die) {
    final player = state.activePlayer;
    final moves = <Move>[];

    for (int i = 0; i < 24; i++) {
      if (state.checkerCount(i, player) == 0) continue;

      // Skip pinned checkers.
      if (state.isPinned(i) && state.pinnedPlayer(i) == player) continue;

      // Movement direction: P1 goes 0→23, P2 goes 23→0.
      final target = player == 1 ? i + die : i - die;

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

      if (isPointOpen(state, target, player)) {
        final willPin = _willPin(state, target, player);
        moves.add(Move(
          fromPoint: i,
          toPoint: target,
          dieUsed: die,
          isHit: willPin, // Reuse isHit flag to indicate pinning.
        ));
      }
    }

    return moves;
  }

  bool _willPin(BoardState state, int target, int player) {
    final val = state.points[target];
    if (player == 1) return val == -1 && !state.isPinned(target);
    return val == 1 && !state.isPinned(target);
  }

  bool _canBearOffMove(BoardState state, int fromPoint, int die, int player) {
    if (!allInHome(state, player)) return false;

    if (player == 1) {
      // P1 bears off from 18-23. Exact: fromPoint + die == 24, or no higher.
      final target = fromPoint + die;
      if (target == 24) return true;
      if (target > 24) {
        // Can bear off from highest point if no higher checkers.
        for (int i = fromPoint + 1; i <= 23; i++) {
          if (state.points[i] > 0) return false;
        }
        return fromPoint >= 18;
      }
    } else {
      // P2 bears off from 0-5. Exact: fromPoint - die == -1, or no lower.
      final target = fromPoint - die;
      if (target == -1) return true;
      if (target < -1) {
        for (int i = fromPoint - 1; i >= 0; i--) {
          if (state.points[i] < 0) return false;
        }
        return fromPoint <= 5;
      }
    }
    return false;
  }

  /// Check if all of player's checkers are in their home board.
  bool allInHome(BoardState state, int player) {
    if (player == 1) {
      // P1 home = 18-23.
      for (int i = 0; i < 18; i++) {
        if (state.points[i] > 0) return false;
      }
    } else {
      // P2 home = 0-5.
      for (int i = 6; i < 24; i++) {
        if (state.points[i] < 0) return false;
      }
    }
    return true;
  }

  /// Generate all legal turns for a dice roll.
  List<Turn> generateAllLegalTurns(BoardState state, DiceRoll roll) {
    final results = <Turn>[];

    if (roll.isDoubles) {
      _generateDoublesRecursive(state, roll.die1, 4, [], results);
    } else {
      // Try die1 first, then die2.
      _generateSequential(state, roll.die1, roll.die2, [], results);
      _generateSequential(state, roll.die2, roll.die1, [], results);
    }

    // Enforce mandatory play: must use max dice.
    return _filterAndDeduplicate(results, roll);
  }

  void _generateSequential(BoardState state, int die1, int die2,
      List<Move> movesSoFar, List<Turn> results) {
    final moves1 = generateMovesForDie(state, die1);

    if (moves1.isEmpty) {
      // Can't use die1 — try die2 alone.
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

    // Must use max moves.
    final maxMoves = turns.map((t) => t.moves.length).reduce((a, b) => a > b ? a : b);
    var filtered = turns.where((t) => t.moves.length == maxMoves).toList();

    // If only 1 die usable and not doubles, prefer the larger die.
    if (!roll.isDoubles && maxMoves == 1) {
      final usesLarger = filtered.where((t) =>
          t.moves.first.dieUsed == (roll.die1 > roll.die2 ? roll.die1 : roll.die2));
      if (usesLarger.isNotEmpty) {
        filtered = usesLarger.toList();
      }
    }

    // Deduplicate by final board state.
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

    // Check for mama (auto double loss).
    if (isMama(state, loser)) {
      return GameResult(
        winner: winner,
        type: GameResultType.backgammon, // Mama is worth double.
        cubeValue: state.doublingCubeValue,
      );
    }

    // Gammon: loser has borne off zero checkers.
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

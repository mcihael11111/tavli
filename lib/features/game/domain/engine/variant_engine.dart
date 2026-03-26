import '../../data/models/board_state.dart';
import '../../data/models/dice_roll.dart';
import '../../data/models/game_result.dart';
import '../../data/models/move.dart';
import '../../data/models/turn.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/constants/variants/variant_rules.dart';
import 'variants/game_variant.dart';
import 'variants/plakoto_engine.dart';
import 'variants/fevga_engine.dart';
import 'game_engine.dart';
import 'move_generator.dart';

/// Unified engine that dispatches to the correct logic based on [GameVariant].
///
/// This is the single entry point for all game operations across all traditions.
/// It delegates to the existing specialized engines (GameEngine for hitting,
/// PlakotoEngine for pinning, FevgaEngine for running) and applies
/// variant-specific rule tweaks on top.
class VariantEngine {
  final GameVariant variant;
  final VariantRules rules;

  // Delegate engines.
  final GameEngine _hittingEngine;
  final PlakotoEngine _pinningEngine;
  final FevgaEngine _runningEngine;
  final MoveGenerator _hittingMoveGen;

  VariantEngine(this.variant)
      : rules = variant.rules,
        _hittingEngine = const GameEngine(),
        _pinningEngine = const PlakotoEngine(),
        _runningEngine = const FevgaEngine(),
        _hittingMoveGen = const MoveGenerator();

  /// Create the initial board state for this variant.
  BoardState initialState({int activePlayer = 1}) {
    return BoardState.forVariant(variant, activePlayer: activePlayer);
  }

  /// Apply a single move to the board state.
  BoardState applyMove(BoardState state, Move move) {
    switch (rules.captureMode) {
      case CaptureMode.hitting:
        return _hittingEngine.applyMove(state, move);
      case CaptureMode.pinning:
        return _pinningEngine.applyMove(state, move);
      case CaptureMode.none:
        return _runningEngine.applyMove(state, move);
    }
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
    return state.copyWith(activePlayer: state.activePlayer == 1 ? 2 : 1);
  }

  /// Generate all legal turns for a dice roll.
  List<Turn> generateAllLegalTurns(BoardState state, DiceRoll roll) {
    switch (rules.captureMode) {
      case CaptureMode.hitting:
        return _hittingMoveGen.generateAllLegalTurns(state, roll);
      case CaptureMode.pinning:
        return _pinningEngine.generateAllLegalTurns(state, roll);
      case CaptureMode.none:
        // For running games, apply head rule filtering for Long Nard.
        final turns = _runningEngine.generateAllLegalTurns(state, roll);
        if (rules.hasHeadRule) {
          return _filterHeadRule(turns, state, roll);
        }
        return turns;
    }
  }

  /// Generate legal moves for a single die value.
  List<Move> generateMovesForDie(BoardState state, int die) {
    switch (rules.captureMode) {
      case CaptureMode.hitting:
        return _hittingMoveGen.generateMovesForDie(state, die);
      case CaptureMode.pinning:
        return _pinningEngine.generateMovesForDie(state, die);
      case CaptureMode.none:
        return _runningEngine.generateMovesForDie(state, die);
    }
  }

  /// Whether the game is over.
  bool isGameOver(BoardState state) {
    return state.borneOff1 >= GameConstants.checkersPerPlayer ||
        state.borneOff2 >= GameConstants.checkersPerPlayer;
  }

  /// Get the game result.
  GameResult? getResult(BoardState state) {
    if (!isGameOver(state)) return null;

    // For pinning games, check mama/mother piece rule.
    if (rules.hasMotherPiece) {
      return _pinningEngine.getResult(state);
    }

    // For hitting games with backgammon scoring.
    if (rules.captureMode == CaptureMode.hitting && rules.scoringBackgammon) {
      return _hittingEngine.getResult(state);
    }

    // Default: single/gammon only (no backgammon).
    final winner = state.borneOff1 >= GameConstants.checkersPerPlayer ? 1 : 2;
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

  /// Whether the doubling cube is available for this variant.
  bool get hasDoublingCube => rules.hasDoublingCube;

  /// Whether [player] may offer a double.
  bool canOfferDouble(BoardState state, int player) {
    if (!hasDoublingCube) return false;
    return _hittingEngine.canOfferDouble(state, player);
  }

  /// Accept a double.
  BoardState acceptDouble(BoardState state) {
    return _hittingEngine.acceptDouble(state);
  }

  /// Check if all checkers are in home for the given player.
  bool allInHome(BoardState state, int player) {
    switch (rules.captureMode) {
      case CaptureMode.hitting:
        return state.allInHome(player);
      case CaptureMode.pinning:
        return _pinningEngine.allInHome(state, player);
      case CaptureMode.none:
        return _runningEngine.allInHome(state, player);
    }
  }

  // ── Head Rule (Long Nard) ───────────────────────────────────────

  /// Filter turns to enforce the head rule: only one checker may leave
  /// the starting point ("head") per turn.
  ///
  /// Exception: on the very first turn, if doubles are 3-3, 4-4, or 6-6,
  /// two checkers may leave the head.
  List<Turn> _filterHeadRule(
      List<Turn> turns, BoardState state, DiceRoll roll) {
    final player = state.activePlayer;
    final headPoint = player == 1 ? rules.p1StartPoint : rules.p2StartPoint;

    // Check if this is the first move (all 15 still on head).
    final checkersOnHead = state.checkerCount(headPoint, player);
    final isFirstTurn = checkersOnHead == GameConstants.checkersPerPlayer;

    // On first turn with specific doubles, allow 2 off head.
    final maxOffHead = (isFirstTurn &&
            roll.isDoubles &&
            rules.headRuleDoubleExceptions.contains(roll.die1))
        ? 2
        : 1;

    return turns.where((turn) {
      int offHead = 0;
      for (final move in turn.moves) {
        if (move.fromPoint == headPoint) offHead++;
      }
      return offHead <= maxOffHead;
    }).toList();
  }
}

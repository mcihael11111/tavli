import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/board_state.dart';
import '../../data/models/dice_roll.dart';
import '../../data/models/move.dart';
import '../../data/models/turn.dart';
import '../../data/models/game_result.dart';
import '../../data/models/game_state.dart';
import '../../domain/engine/game_engine.dart';
import '../../domain/engine/move_generator.dart';
import '../../domain/engine/variants/game_variant.dart';
import '../../../../core/constants/tradition.dart';
import '../../domain/engine/variants/plakoto_engine.dart';
import '../../domain/engine/variants/fevga_engine.dart';
import '../../../ai/difficulty/difficulty_level.dart';

/// Complete game state: board, phase, dice, legal moves, history, etc.
class GameState {
  final BoardState board;
  final GamePhase phase;
  final DiceRoll? currentRoll;
  final List<Move> currentTurnMoves;
  final List<Turn> legalTurns;
  final int? selectedPoint;
  final List<Move> availableMovesForSelected;
  final List<int> remainingDice;
  final GameResult? result;
  final DifficultyLevel difficulty;
  final List<BoardState> undoStack;

  /// Whether a doubling offer is pending (from either player).
  final bool doubleOffered;

  /// Who offered the double (1 = player, 2 = AI).
  final int? doubleOfferedBy;

  /// Opening roll: each player's die for first-roll determination.
  final int? openingRollPlayer;
  final int? openingRollOpponent;

  const GameState({
    required this.board,
    this.phase = GamePhase.playerTurnStart,
    this.currentRoll,
    this.currentTurnMoves = const [],
    this.legalTurns = const [],
    this.selectedPoint,
    this.availableMovesForSelected = const [],
    this.remainingDice = const [],
    this.result,
    this.difficulty = DifficultyLevel.easy,
    this.undoStack = const [],
    this.doubleOffered = false,
    this.doubleOfferedBy,
    this.openingRollPlayer,
    this.openingRollOpponent,
  });

  GameState copyWith({
    BoardState? board,
    GamePhase? phase,
    DiceRoll? currentRoll,
    List<Move>? currentTurnMoves,
    List<Turn>? legalTurns,
    int? selectedPoint,
    List<Move>? availableMovesForSelected,
    List<int>? remainingDice,
    GameResult? result,
    DifficultyLevel? difficulty,
    List<BoardState>? undoStack,
    bool? doubleOffered,
    int? doubleOfferedBy,
    bool clearSelectedPoint = false,
    bool clearRoll = false,
    bool clearResult = false,
    bool clearDouble = false,
    bool clearOpeningRoll = false,
    int? openingRollPlayer,
    int? openingRollOpponent,
  }) {
    return GameState(
      board: board ?? this.board,
      phase: phase ?? this.phase,
      currentRoll: clearRoll ? null : (currentRoll ?? this.currentRoll),
      currentTurnMoves: currentTurnMoves ?? this.currentTurnMoves,
      legalTurns: legalTurns ?? this.legalTurns,
      selectedPoint: clearSelectedPoint ? null : (selectedPoint ?? this.selectedPoint),
      availableMovesForSelected: clearSelectedPoint ? const [] : (availableMovesForSelected ?? this.availableMovesForSelected),
      remainingDice: remainingDice ?? this.remainingDice,
      result: clearResult ? null : (result ?? this.result),
      difficulty: difficulty ?? this.difficulty,
      undoStack: undoStack ?? this.undoStack,
      doubleOffered: clearDouble ? false : (doubleOffered ?? this.doubleOffered),
      doubleOfferedBy: clearDouble ? null : (doubleOfferedBy ?? this.doubleOfferedBy),
      openingRollPlayer: clearOpeningRoll ? null : (openingRollPlayer ?? this.openingRollPlayer),
      openingRollOpponent: clearOpeningRoll ? null : (openingRollOpponent ?? this.openingRollOpponent),
    );
  }

  /// Whether it's the human player's turn (player 1).
  bool get isPlayerTurn => board.activePlayer == 1;

  /// Whether AI should act.
  bool get isAiTurn => board.activePlayer == 2;

  /// Whether the player can offer a double right now.
  bool get canPlayerDouble =>
      isPlayerTurn &&
      phase == GamePhase.playerTurnStart &&
      difficulty.usesDoublingCube &&
      !doubleOffered &&
      (board.cubeOwner == null || board.cubeOwner == 1);
}

/// Main game notifier: orchestrates game flow.
class GameNotifier extends StateNotifier<GameState> {
  final GameEngine _engine;
  final MoveGenerator _generator;
  final Random _rng;
  GameVariant _variant;
  final PlakotoEngine _plakotoEngine;
  final FevgaEngine _fevgaEngine;

  GameNotifier({
    GameEngine? engine,
    MoveGenerator? generator,
    Random? rng,
    DifficultyLevel difficulty = DifficultyLevel.easy,
    GameVariant variant = GameVariant.portes,
  })  : _engine = engine ?? const GameEngine(),
        _generator = generator ?? const MoveGenerator(),
        _rng = rng ?? Random(),
        _variant = variant,
        _plakotoEngine = const PlakotoEngine(),
        _fevgaEngine = const FevgaEngine(),
        super(GameState(
          board: BoardState.initial(),
          difficulty: difficulty,
        ));

  /// The initial board for the current variant.
  BoardState _initialBoard({int activePlayer = 1}) {
    return BoardState.forVariant(_variant, activePlayer: activePlayer);
  }

  /// Generate legal turns for the current variant.
  List<Turn> _generateTurns(BoardState board, DiceRoll roll) {
    return switch (_variant.mechanicFamily) {
      MechanicFamily.hitting => _generator.generateAllLegalTurns(board, roll),
      MechanicFamily.pinning => _plakotoEngine.generateAllLegalTurns(board, roll),
      MechanicFamily.running => _fevgaEngine.generateAllLegalTurns(board, roll),
    };
  }

  /// Generate single-die moves for the current variant.
  List<Move> _generateMovesForDie(BoardState board, int die) {
    return switch (_variant.mechanicFamily) {
      MechanicFamily.hitting => _generator.generateMovesForDie(board, die),
      MechanicFamily.pinning => _plakotoEngine.generateMovesForDie(board, die),
      MechanicFamily.running => _fevgaEngine.generateMovesForDie(board, die),
    };
  }

  /// Apply a move for the current variant.
  BoardState _applyMoveVariant(BoardState board, Move move) {
    return switch (_variant.mechanicFamily) {
      MechanicFamily.hitting => _engine.applyMove(board, move),
      MechanicFamily.pinning => _plakotoEngine.applyMove(board, move),
      MechanicFamily.running => _fevgaEngine.applyMove(board, move),
    };
  }

  /// End turn for the current variant.
  BoardState _endTurnVariant(BoardState board) {
    return switch (_variant.mechanicFamily) {
      MechanicFamily.hitting => _engine.endTurn(board),
      MechanicFamily.pinning => _plakotoEngine.endTurn(board),
      MechanicFamily.running => _fevgaEngine.endTurn(board),
    };
  }

  /// Check game over for the current variant.
  bool _isGameOverVariant(BoardState board) {
    return switch (_variant.mechanicFamily) {
      MechanicFamily.hitting => _engine.isGameOver(board),
      MechanicFamily.pinning => _plakotoEngine.isGameOver(board),
      MechanicFamily.running => _fevgaEngine.isGameOver(board),
    };
  }

  /// Get result for the current variant.
  GameResult? _getResultVariant(BoardState board) {
    return switch (_variant.mechanicFamily) {
      MechanicFamily.hitting => _engine.getResult(board),
      MechanicFamily.pinning => _plakotoEngine.getResult(board),
      MechanicFamily.running => _fevgaEngine.getResult(board),
    };
  }

  /// Start a new game with opening roll ceremony.
  void newGame({DifficultyLevel? difficulty, GameVariant? variant}) {
    if (variant != null) _variant = variant;
    state = GameState(
      board: _initialBoard(),
      phase: GamePhase.waitingForFirstRoll,
      difficulty: difficulty ?? state.difficulty,
    );
  }

  /// Perform the opening roll to determine who goes first.
  /// Both players roll one die; higher number goes first using both dice.
  void performOpeningRoll() {
    if (state.phase != GamePhase.waitingForFirstRoll) return;

    int playerDie, opponentDie;
    do {
      playerDie = _rng.nextInt(6) + 1;
      opponentDie = _rng.nextInt(6) + 1;
    } while (playerDie == opponentDie); // re-roll ties

    final playerGoesFirst = playerDie > opponentDie;
    final firstPlayer = playerGoesFirst ? 1 : 2;
    final roll = DiceRoll(
      die1: playerDie > opponentDie ? playerDie : opponentDie,
      die2: playerDie > opponentDie ? opponentDie : playerDie,
    );

    final board = _initialBoard(activePlayer: firstPlayer);
    final turns = _generateTurns(board, roll);

    state = state.copyWith(
      board: board,
      phase: GamePhase.movingCheckers,
      currentRoll: roll,
      legalTurns: turns,
      remainingDice: roll.movesAvailable,
      openingRollPlayer: playerDie,
      openingRollOpponent: opponentDie,
    );
  }

  /// Resign the current game. The resigning player loses.
  void resign(int resigningPlayer) {
    final winner = resigningPlayer == 1 ? 2 : 1;
    state = state.copyWith(
      phase: GamePhase.gameOver,
      result: GameResult(
        winner: winner,
        type: GameResultType.single,
        cubeValue: state.board.doublingCubeValue,
      ),
    );
  }

  /// Roll the dice for the active player.
  void rollDice() {
    if (state.phase != GamePhase.playerTurnStart &&
        state.phase != GamePhase.rollingDice) {
      return;
    }

    final roll = DiceRoll.random(_rng);
    final turns = _generateTurns(state.board, roll);

    if (turns.isEmpty) {
      // No legal moves — skip turn.
      final nextBoard = _endTurnVariant(state.board);
      state = state.copyWith(
        board: nextBoard,
        currentRoll: roll,
        phase: GamePhase.turnComplete,
        legalTurns: const [],
        remainingDice: const [],
        currentTurnMoves: const [],
        clearSelectedPoint: true,
      );
      return;
    }

    state = state.copyWith(
      currentRoll: roll,
      phase: GamePhase.movingCheckers,
      legalTurns: turns,
      remainingDice: roll.movesAvailable,
      currentTurnMoves: const [],
      undoStack: const [],
      clearSelectedPoint: true,
    );
  }

  /// Select a checker at [pointIndex] (or bar: -1).
  void selectChecker(int pointIndex) {
    if (state.phase != GamePhase.movingCheckers) return;
    if (state.remainingDice.isEmpty) return;

    final player = state.board.activePlayer;

    // Check if player has a checker here.
    if (pointIndex == -1) {
      if (state.board.barCount(player) == 0) return;
    } else {
      if (state.board.checkerCount(pointIndex, player) == 0) return;
    }

    // Find legal moves from this point using remaining dice.
    final moves = <Move>[];
    final usedDice = <int>{};

    for (final die in state.remainingDice) {
      if (usedDice.contains(die)) continue;
      usedDice.add(die);

      final singleMoves = _generateMovesForDie(state.board, die);
      for (final m in singleMoves) {
        if (m.fromPoint == pointIndex) {
          moves.add(m);
        }
      }
    }

    if (moves.isEmpty) {
      state = state.copyWith(clearSelectedPoint: true);
      return;
    }

    state = state.copyWith(
      selectedPoint: pointIndex,
      availableMovesForSelected: moves,
    );
  }

  /// Execute a move to [toPoint].
  void makeMove(int toPoint) {
    if (state.selectedPoint == null) return;
    if (state.availableMovesForSelected.isEmpty) return;

    // Find the move matching this destination.
    final move = state.availableMovesForSelected.firstWhere(
      (m) => m.toPoint == toPoint,
      orElse: () => const Move(fromPoint: -99, toPoint: -99, dieUsed: 0),
    );
    if (move.fromPoint == -99) return;

    _applyMove(move);
  }

  void _applyMove(Move move) {
    final newBoard = _applyMoveVariant(state.board, move);
    final newMoves = [...state.currentTurnMoves, move];
    final newRemaining = List<int>.from(state.remainingDice);
    newRemaining.remove(move.dieUsed);

    // Save undo state.
    final newUndoStack = [...state.undoStack, state.board];

    // Check if game is over.
    if (_isGameOverVariant(newBoard)) {
      state = state.copyWith(
        board: newBoard,
        phase: GamePhase.gameOver,
        result: _getResultVariant(newBoard),
        currentTurnMoves: newMoves,
        remainingDice: newRemaining,
        undoStack: newUndoStack,
        clearSelectedPoint: true,
      );
      return;
    }

    // Check if turn is complete (no more dice or no more legal moves).
    if (newRemaining.isEmpty) {
      _finishTurn(newBoard, newMoves, newUndoStack);
      return;
    }

    // Check if any moves remain with remaining dice.
    bool hasLegalMoves = false;
    for (final die in newRemaining.toSet()) {
      if (_generateMovesForDie(newBoard, die).isNotEmpty) {
        hasLegalMoves = true;
        break;
      }
    }

    if (!hasLegalMoves) {
      _finishTurn(newBoard, newMoves, newUndoStack);
      return;
    }

    state = state.copyWith(
      board: newBoard,
      currentTurnMoves: newMoves,
      remainingDice: newRemaining,
      undoStack: newUndoStack,
      clearSelectedPoint: true,
    );
  }

  void _finishTurn(BoardState board, List<Move> moves, List<BoardState> undoStack) {
    final nextBoard = _endTurnVariant(board);
    state = state.copyWith(
      board: nextBoard,
      phase: GamePhase.turnComplete,
      currentTurnMoves: moves,
      remainingDice: const [],
      undoStack: undoStack,
      clearSelectedPoint: true,
    );
  }

  /// Undo the last move within the current turn.
  void undoMove() {
    if (state.undoStack.isEmpty) return;
    if (state.currentTurnMoves.isEmpty) return;

    final previousBoard = state.undoStack.last;
    final undoneMove = state.currentTurnMoves.last;
    final newMoves = state.currentTurnMoves.sublist(0, state.currentTurnMoves.length - 1);
    final newUndo = state.undoStack.sublist(0, state.undoStack.length - 1);
    final newRemaining = [...state.remainingDice, undoneMove.dieUsed];

    state = state.copyWith(
      board: previousBoard,
      currentTurnMoves: newMoves,
      remainingDice: newRemaining,
      undoStack: newUndo,
      clearSelectedPoint: true,
    );
  }

  /// Player offers a double before rolling.
  void offerDouble() {
    if (!state.canPlayerDouble) return;
    state = state.copyWith(
      phase: GamePhase.doubleOffered,
      doubleOffered: true,
      doubleOfferedBy: 1,
    );
  }

  /// AI offers a double to the player.
  void aiOfferDouble() {
    if (!state.difficulty.usesDoublingCube) return;
    if (!_engine.canOfferDouble(state.board, 2)) return;
    state = state.copyWith(
      phase: GamePhase.doubleOffered,
      doubleOffered: true,
      doubleOfferedBy: 2,
    );
  }

  /// Accept a pending double.
  void acceptDouble() {
    if (!state.doubleOffered) return;
    final newBoard = _engine.acceptDouble(state.board);
    state = state.copyWith(
      board: newBoard,
      phase: GamePhase.playerTurnStart,
      clearDouble: true,
    );
  }

  /// Decline a pending double — the declining player loses at current cube value.
  void declineDouble() {
    if (!state.doubleOffered) return;
    // The player who declined loses.
    final decliner = state.doubleOfferedBy == 1 ? 2 : 1;
    final winner = decliner == 1 ? 2 : 1;
    state = state.copyWith(
      phase: GamePhase.gameOver,
      result: GameResult(
        winner: winner,
        type: GameResultType.single,
        cubeValue: state.board.doublingCubeValue,
      ),
      clearDouble: true,
    );
  }

  /// Check if all checkers are in the home board for the current variant.
  bool _allInHomeVariant(BoardState board, int player) {
    return switch (_variant.mechanicFamily) {
      MechanicFamily.hitting => board.allInHome(player),
      MechanicFamily.pinning => _plakotoEngine.allInHome(board, player),
      MechanicFamily.running => _fevgaEngine.allInHome(board, player),
    };
  }

  /// Returns true when the remaining bear-off is trivial (only one legal turn).
  bool isTrivialBearOff() {
    if (state.phase != GamePhase.movingCheckers) return false;
    if (state.remainingDice.isEmpty) return false;
    if (state.legalTurns.length != 1) return false;
    return _allInHomeVariant(state.board, state.board.activePlayer);
  }

  /// Auto-play all forced moves from the single legal turn.
  /// Returns the list of moves applied.
  List<Move> autoPlayForcedMoves() {
    if (!isTrivialBearOff()) return const [];
    final turn = state.legalTurns.first;
    final moves = <Move>[];
    for (final move in turn.moves) {
      selectChecker(move.fromPoint);
      makeMove(move.toPoint);
      moves.add(move);
    }
    return moves;
  }

  /// Peek at what the board would look like after applying a move
  /// (without actually changing state). Used for teaching mode evaluation.
  BoardState? peekApplyMove(Move move) {
    try {
      return _applyMoveVariant(state.board, move);
    } catch (_) {
      return null;
    }
  }

  /// Advance to next turn (called after AI moves or turn-complete animation).
  void nextTurn() {
    if (state.phase == GamePhase.gameOver) return;
    state = state.copyWith(
      phase: GamePhase.playerTurnStart,
      clearRoll: true,
      currentTurnMoves: const [],
      legalTurns: const [],
      remainingDice: const [],
      undoStack: const [],
      clearSelectedPoint: true,
      clearDouble: true,
    );
  }
}

/// Provider for the game state.
final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});

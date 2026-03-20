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

  GameNotifier({
    GameEngine? engine,
    MoveGenerator? generator,
    Random? rng,
    DifficultyLevel difficulty = DifficultyLevel.easy,
  })  : _engine = engine ?? const GameEngine(),
        _generator = generator ?? const MoveGenerator(),
        _rng = rng ?? Random(),
        super(GameState(
          board: BoardState.initial(),
          difficulty: difficulty,
        ));

  /// Start a new game with opening roll ceremony.
  void newGame({DifficultyLevel? difficulty}) {
    state = GameState(
      board: BoardState.initial(),
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

    final board = BoardState.initial(activePlayer: firstPlayer);
    final turns = _generator.generateAllLegalTurns(board, roll);

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
        state.phase != GamePhase.rollingDice) return;

    final roll = DiceRoll.random(_rng);
    final turns = _generator.generateAllLegalTurns(state.board, roll);

    if (turns.isEmpty) {
      // No legal moves — skip turn.
      final nextBoard = _engine.endTurn(state.board);
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

      final singleMoves = _generator.generateMovesForDie(state.board, die);
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
    final newBoard = _engine.applyMove(state.board, move);
    final newMoves = [...state.currentTurnMoves, move];
    final newRemaining = List<int>.from(state.remainingDice);
    newRemaining.remove(move.dieUsed);

    // Save undo state.
    final newUndoStack = [...state.undoStack, state.board];

    // Check if game is over.
    if (_engine.isGameOver(newBoard)) {
      state = state.copyWith(
        board: newBoard,
        phase: GamePhase.gameOver,
        result: _engine.getResult(newBoard),
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
      if (_generator.generateMovesForDie(newBoard, die).isNotEmpty) {
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
    final nextBoard = _engine.endTurn(board);
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

  /// Peek at what the board would look like after applying a move
  /// (without actually changing state). Used for teaching mode evaluation.
  BoardState? peekApplyMove(Move move) {
    try {
      return _engine.applyMove(state.board, move);
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

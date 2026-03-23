import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/data/models/board_state.dart';
import '../../game/data/models/dice_roll.dart';
import '../../game/data/models/game_result.dart';
import '../../game/data/models/game_state.dart';
import '../../game/data/models/move.dart';
import '../../game/domain/engine/game_engine.dart';
import '../../game/domain/engine/move_generator.dart';
import '../data/firestore_multiplayer_service.dart';
import '../data/game_room.dart' as room;
import '../data/multiplayer_service_provider.dart';
import '../domain/rating_system.dart';
import 'online_game_state.dart';

/// Notifier for online multiplayer game state.
///
/// Subscribes to Firestore snapshots for the game room and allows local
/// interaction when it's the local player's turn. Moves are submitted
/// atomically at end of turn.
class OnlineGameNotifier extends StateNotifier<OnlineGameState> {
  final FirestoreMultiplayerService _service;
  final GameEngine _engine;
  final MoveGenerator _generator;
  final String _localPlayerUid;

  StreamSubscription<room.GameRoom>? _roomSubscription;
  Timer? _heartbeatTimer;

  /// Track if we've already processed the current board state from Firestore.
  Map<String, dynamic>? _lastProcessedBoardJson;

  OnlineGameNotifier({
    required OnlineGameParams params,
    required FirestoreMultiplayerService service,
    GameEngine? engine,
    MoveGenerator? generator,
  })  : _service = service,
        _engine = engine ?? const GameEngine(),
        _generator = generator ?? const MoveGenerator(),
        _localPlayerUid = params.localPlayerUid,
        super(OnlineGameState(
          gameRoomId: params.gameRoomId,
          localPlayerNumber: params.localPlayerNumber,
          board: BoardState.initial(),
        )) {
    _startWatching(params.gameRoomId);
    _startHeartbeat(params.gameRoomId);
  }

  void _startWatching(String gameId) {
    _roomSubscription = _service.watchRoom(gameId).listen(
      _onRoomUpdate,
      onError: (error) {
        state = state.copyWith(
          connectionStatus: ConnectionStatus.reconnecting,
        );
      },
    );
  }

  void _startHeartbeat(String gameId) {
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _service.updateHeartbeat(gameId, state.localPlayerKey),
    );
    // Send first heartbeat immediately.
    _service.updateHeartbeat(gameId, state.localPlayerKey);
  }

  /// Called when a Firestore snapshot arrives.
  void _onRoomUpdate(room.GameRoom gameRoom) {
    // Update connection status.
    state = state.copyWith(connectionStatus: ConnectionStatus.connected);

    // Set opponent info.
    final opponent = state.localPlayerNumber == 1
        ? gameRoom.player2
        : gameRoom.player1;
    if (opponent != null) {
      state = state.copyWith(
        opponentName: opponent.name,
        opponentRating: opponent.rating,
      );
    }

    // Check for disconnect.
    _checkOpponentHeartbeat(gameRoom);

    // Handle pending double offer from opponent.
    if (gameRoom.pendingDoubleFrom != null &&
        gameRoom.pendingDoubleFrom != state.localPlayerKey) {
      state = state.copyWith(
        phase: GamePhase.doubleOffered,
        pendingDoubleFrom: gameRoom.pendingDoubleFrom,
        doublingCube: gameRoom.doublingCube,
      );
      return;
    }

    // Handle game over.
    if (gameRoom.status == room.GameRoomStatus.finished ||
        gameRoom.status == room.GameRoomStatus.abandoned) {
      _handleGameOver(gameRoom);
      return;
    }

    // Game still waiting for opponent to join.
    if (gameRoom.status == room.GameRoomStatus.waiting) {
      state = state.copyWith(phase: GamePhase.waitingForFirstRoll);
      return;
    }

    // Game in progress — sync board state from Firestore.
    final boardJson = gameRoom.boardState;
    final boardJsonStr = boardJson.toString();
    final lastStr = _lastProcessedBoardJson?.toString();

    if (boardJsonStr != lastStr) {
      _lastProcessedBoardJson = Map.from(boardJson);

      final board = _boardFromJson(boardJson);

      // Determine whose turn it is.
      final isMyTurn = gameRoom.currentTurn == state.localPlayerKey;

      if (isMyTurn) {
        // It's our turn — set up for local interaction.
        state = state.copyWith(
          board: board,
          phase: GamePhase.playerTurnStart,
          clearRoll: true,
          currentTurnMoves: const [],
          remainingDice: const [],
          undoStack: const [],
          clearSelectedPoint: true,
          doublingCube: gameRoom.doublingCube,
          clearPendingDouble: true,
          opponentMoves: gameRoom.lastTurnMoves,
        );
      } else {
        // Opponent's turn — read-only, show their last moves for animation.
        state = state.copyWith(
          board: board,
          phase: GamePhase.playerTurnStart,
          clearRoll: true,
          currentTurnMoves: const [],
          remainingDice: const [],
          clearSelectedPoint: true,
          doublingCube: gameRoom.doublingCube,
          clearPendingDouble: true,
          opponentMoves: gameRoom.lastTurnMoves,
        );
      }
    }
  }

  void _checkOpponentHeartbeat(room.GameRoom gameRoom) {
    final opponentKey = state.opponentPlayerKey;
    final heartbeat = gameRoom.heartbeats[opponentKey];
    if (heartbeat == null) return;

    final staleness = DateTime.now().difference(heartbeat);
    if (staleness > const Duration(seconds: 60)) {
      state = state.copyWith(
        connectionStatus: ConnectionStatus.opponentDisconnected,
      );
    }
  }

  void _handleGameOver(room.GameRoom gameRoom) {
    final winnerKey = gameRoom.winner;
    if (winnerKey == null) return;

    final winnerNumber = winnerKey == 'player1' ? 1 : 2;
    final didWin = winnerNumber == state.localPlayerNumber;

    // Compute rating delta optimistically.
    const ratingSystem = RatingSystem();
    final myRating = state.localPlayerNumber == 1
        ? gameRoom.player1.rating
        : (gameRoom.player2?.rating ?? 1000);
    final oppRating = state.localPlayerNumber == 1
        ? (gameRoom.player2?.rating ?? 1000)
        : gameRoom.player1.rating;

    final update = ratingSystem.calculateNewRatings(
      winnerRating: didWin ? myRating : oppRating,
      loserRating: didWin ? oppRating : myRating,
      winnerGamesPlayed: 0, // approximate
      loserGamesPlayed: 0,
      resultType: GameResultType.single,
    );

    final ratingDelta = didWin ? update.winnerDelta : update.loserDelta;

    state = state.copyWith(
      phase: GamePhase.gameOver,
      result: GameResult(
        winner: winnerNumber,
        type: GameResultType.single,
        cubeValue: gameRoom.doublingCube.value,
      ),
      ratingDelta: ratingDelta,
    );
  }

  // ── Local player actions ────────────────────────────────────

  /// Roll dice (local player's turn).
  Future<void> rollDice() async {
    if (!state.isMyTurn) return;
    if (state.phase != GamePhase.playerTurnStart) return;

    // Generate dice and write to Firestore.
    final dice = await _service.rollDice(state.gameRoomId, _localPlayerUid);
    if (dice == null) return;

    final roll = DiceRoll(die1: dice.die1, die2: dice.die2);
    final turns = _generator.generateAllLegalTurns(state.board, roll);

    if (turns.isEmpty) {
      // No legal moves — submit empty turn to pass.
      final nextBoard = _engine.endTurn(state.board);
      await _service.submitTurn(
        gameId: state.gameRoomId,
        playerUid: _localPlayerUid,
        newBoardState: _boardToJson(nextBoard),
        moves: const [],
        diceRoll: dice,
      );
      return;
    }

    state = state.copyWith(
      currentRoll: roll,
      phase: GamePhase.movingCheckers,
      remainingDice: roll.movesAvailable,
      currentTurnMoves: const [],
      undoStack: const [],
      clearSelectedPoint: true,
    );
  }

  /// Select a checker at [pointIndex] (or bar: -1).
  void selectChecker(int pointIndex) {
    if (!state.isMyTurn) return;
    if (state.phase != GamePhase.movingCheckers) return;
    if (state.remainingDice.isEmpty) return;

    final player = state.localPlayerNumber;

    if (pointIndex == -1) {
      if (state.board.barCount(player) == 0) return;
    } else {
      if (state.board.checkerCount(pointIndex, player) == 0) return;
    }

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

    final move = state.availableMovesForSelected
        .where((m) => m.toPoint == toPoint)
        .firstOrNull;
    if (move == null) return;

    _applyMove(move);
  }

  void _applyMove(Move move) {
    final newBoard = _engine.applyMove(state.board, move);
    final newMoves = [...state.currentTurnMoves, move];
    final newRemaining = List<int>.from(state.remainingDice);
    newRemaining.remove(move.dieUsed);
    final newUndoStack = [...state.undoStack, state.board];

    // Check if game is over.
    if (_engine.isGameOver(newBoard)) {
      state = state.copyWith(
        board: newBoard,
        currentTurnMoves: newMoves,
        remainingDice: newRemaining,
        undoStack: newUndoStack,
        clearSelectedPoint: true,
      );
      // Submit the winning turn.
      _submitTurn(newBoard, newMoves);
      return;
    }

    // Check if turn is complete.
    if (newRemaining.isEmpty) {
      state = state.copyWith(
        board: newBoard,
        currentTurnMoves: newMoves,
        remainingDice: newRemaining,
        undoStack: newUndoStack,
        clearSelectedPoint: true,
      );
      _submitTurn(newBoard, newMoves);
      return;
    }

    // Check if any moves remain.
    bool hasLegalMoves = false;
    for (final die in newRemaining.toSet()) {
      if (_generator.generateMovesForDie(newBoard, die).isNotEmpty) {
        hasLegalMoves = true;
        break;
      }
    }

    if (!hasLegalMoves) {
      state = state.copyWith(
        board: newBoard,
        currentTurnMoves: newMoves,
        remainingDice: newRemaining,
        undoStack: newUndoStack,
        clearSelectedPoint: true,
      );
      _submitTurn(newBoard, newMoves);
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

  /// Submit the completed turn to Firestore.
  Future<void> _submitTurn(
    BoardState board,
    List<Move> moves,
  ) async {
    final nextBoard = _engine.endTurn(board);

    // Check for game over and end game if needed.
    if (_engine.isGameOver(board)) {
      final result = _engine.getResult(board);
      final winner = result?.winner ?? state.localPlayerNumber;
      final winnerKey =
          winner == state.localPlayerNumber ? state.localPlayerKey : state.opponentPlayerKey;

      await _service.submitTurn(
        gameId: state.gameRoomId,
        playerUid: _localPlayerUid,
        newBoardState: _boardToJson(board),
        moves: moves.map(_moveToJson).toList(),
        diceRoll: room.DiceState(
          die1: state.currentRoll!.die1,
          die2: state.currentRoll!.die2,
        ),
      );
      await _service.endGame(state.gameRoomId, winnerKey);
      return;
    }

    await _service.submitTurn(
      gameId: state.gameRoomId,
      playerUid: _localPlayerUid,
      newBoardState: _boardToJson(nextBoard),
      moves: moves.map(_moveToJson).toList(),
      diceRoll: room.DiceState(
        die1: state.currentRoll!.die1,
        die2: state.currentRoll!.die2,
      ),
    );
  }

  /// Undo the last move within the current turn.
  void undoMove() {
    if (state.undoStack.isEmpty) return;
    if (state.currentTurnMoves.isEmpty) return;

    final previousBoard = state.undoStack.last;
    final undoneMove = state.currentTurnMoves.last;
    final newMoves = state.currentTurnMoves
        .sublist(0, state.currentTurnMoves.length - 1);
    final newUndo =
        state.undoStack.sublist(0, state.undoStack.length - 1);
    final newRemaining = [...state.remainingDice, undoneMove.dieUsed];

    state = state.copyWith(
      board: previousBoard,
      currentTurnMoves: newMoves,
      remainingDice: newRemaining,
      undoStack: newUndo,
      clearSelectedPoint: true,
    );
  }

  /// Offer a double before rolling.
  Future<void> offerDouble() async {
    if (!state.canOfferDouble) return;
    await _service.offerDouble(state.gameRoomId, state.localPlayerKey);
    state = state.copyWith(
      phase: GamePhase.doubleOffered,
      pendingDoubleFrom: state.localPlayerKey,
    );
  }

  /// Accept a pending double from the opponent.
  Future<void> acceptDouble() async {
    if (state.pendingDoubleFrom == null) return;

    final newValue = state.doublingCube.value * 2;
    final newOwner = state.localPlayerKey; // Accepting player gets ownership.
    final newCube = room.DoublingCubeState(value: newValue, owner: newOwner);

    await _service.respondToDouble(
      gameId: state.gameRoomId,
      accepted: true,
      newCubeState: newCube,
    );

    state = state.copyWith(
      phase: GamePhase.playerTurnStart,
      doublingCube: newCube,
      clearPendingDouble: true,
    );
  }

  /// Decline a pending double — lose the game.
  Future<void> declineDouble() async {
    if (state.pendingDoubleFrom == null) return;

    await _service.respondToDouble(
      gameId: state.gameRoomId,
      accepted: false,
      newCubeState: state.doublingCube,
    );
  }

  /// Resign the game.
  Future<void> resign() async {
    await _service.endGame(state.gameRoomId, state.opponentPlayerKey);
  }

  /// Send a quick chat message.
  Future<void> sendChat(int messageIndex, String playerName) async {
    await _service.sendChat(
      gameId: state.gameRoomId,
      senderUid: _localPlayerUid,
      senderName: playerName,
      messageIndex: messageIndex,
    );
  }

  /// Claim victory by opponent abandonment.
  Future<void> claimAbandonment() async {
    if (state.connectionStatus != ConnectionStatus.opponentDisconnected) {
      return;
    }
    await _service.abandonGame(state.gameRoomId, state.opponentPlayerKey);
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  // ── Board serialization helpers ─────────────────────────────

  BoardState _boardFromJson(Map<String, dynamic> json) {
    final points = (json['points'] as List).cast<int>();
    return BoardState(
      points: List<int>.from(points),
      bar1: json['bar1'] as int? ?? 0,
      bar2: json['bar2'] as int? ?? 0,
      borneOff1: json['borneOff1'] as int? ?? 0,
      borneOff2: json['borneOff2'] as int? ?? 0,
    );
  }

  Map<String, dynamic> _boardToJson(BoardState board) => {
        'points': board.points,
        'bar1': board.bar1,
        'bar2': board.bar2,
        'borneOff1': board.borneOff1,
        'borneOff2': board.borneOff2,
      };

  Map<String, dynamic> _moveToJson(Move move) => {
        'fromPoint': move.fromPoint,
        'toPoint': move.toPoint,
        'dieUsed': move.dieUsed,
        'isHit': move.isHit,
      };
}

/// Riverpod provider for online game state.
final onlineGameProvider = StateNotifierProvider.autoDispose
    .family<OnlineGameNotifier, OnlineGameState, OnlineGameParams>(
  (ref, params) {
    final service = ref.watch(multiplayerServiceProvider);
    return OnlineGameNotifier(params: params, service: service);
  },
);

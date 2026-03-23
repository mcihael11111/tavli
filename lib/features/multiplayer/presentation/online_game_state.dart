import '../../game/data/models/board_state.dart';
import '../../game/data/models/dice_roll.dart';
import '../../game/data/models/game_result.dart';
import '../../game/data/models/game_state.dart';
import '../../game/data/models/move.dart';
import '../data/game_room.dart' as room;

/// Connection status for online play.
enum ConnectionStatus {
  connected,
  reconnecting,
  opponentDisconnected,
  disconnected,
}

/// Parameters for creating an online game session.
class OnlineGameParams {
  final String gameRoomId;
  final int localPlayerNumber; // 1 or 2
  final String localPlayerUid;

  const OnlineGameParams({
    required this.gameRoomId,
    required this.localPlayerNumber,
    required this.localPlayerUid,
  });

  @override
  bool operator ==(Object other) =>
      other is OnlineGameParams && other.gameRoomId == gameRoomId;

  @override
  int get hashCode => gameRoomId.hashCode;
}

/// State for an online multiplayer game.
class OnlineGameState {
  // -- Room info --
  final String gameRoomId;
  final int localPlayerNumber; // 1 or 2
  final String opponentName;
  final int opponentRating;
  final ConnectionStatus connectionStatus;

  // -- Game state (mirrors GameState structure) --
  final BoardState board;
  final GamePhase phase;
  final DiceRoll? currentRoll;
  final List<Move> currentTurnMoves;
  final List<Move> availableMovesForSelected;
  final List<int> remainingDice;
  final int? selectedPoint;
  final List<BoardState> undoStack;
  final GameResult? result;

  // -- Doubling cube --
  final room.DoublingCubeState doublingCube;
  final String? pendingDoubleFrom;

  // -- Opponent animation --
  final List<Map<String, dynamic>> opponentMoves;

  // -- Rating --
  final int? ratingDelta;

  const OnlineGameState({
    required this.gameRoomId,
    required this.localPlayerNumber,
    this.opponentName = 'Opponent',
    this.opponentRating = 1000,
    this.connectionStatus = ConnectionStatus.connected,
    required this.board,
    this.phase = GamePhase.waitingForFirstRoll,
    this.currentRoll,
    this.currentTurnMoves = const [],
    this.availableMovesForSelected = const [],
    this.remainingDice = const [],
    this.selectedPoint,
    this.undoStack = const [],
    this.result,
    this.doublingCube = const room.DoublingCubeState(),
    this.pendingDoubleFrom,
    this.opponentMoves = const [],
    this.ratingDelta,
  });

  /// Whether it's the local player's turn.
  bool get isMyTurn => board.activePlayer == localPlayerNumber;

  /// Whether it's the opponent's turn.
  bool get isOpponentTurn => !isMyTurn;

  /// The local player's key string ('player1' or 'player2').
  String get localPlayerKey => 'player$localPlayerNumber';

  /// The opponent's key string.
  String get opponentPlayerKey =>
      localPlayerNumber == 1 ? 'player2' : 'player1';

  /// Whether the local player can offer a double.
  bool get canOfferDouble =>
      isMyTurn &&
      phase == GamePhase.playerTurnStart &&
      pendingDoubleFrom == null &&
      (doublingCube.owner == null ||
          doublingCube.owner == localPlayerKey);

  OnlineGameState copyWith({
    String? opponentName,
    int? opponentRating,
    ConnectionStatus? connectionStatus,
    BoardState? board,
    GamePhase? phase,
    DiceRoll? currentRoll,
    bool clearRoll = false,
    List<Move>? currentTurnMoves,
    List<Move>? availableMovesForSelected,
    List<int>? remainingDice,
    int? selectedPoint,
    bool clearSelectedPoint = false,
    List<BoardState>? undoStack,
    GameResult? result,
    bool clearResult = false,
    room.DoublingCubeState? doublingCube,
    String? pendingDoubleFrom,
    bool clearPendingDouble = false,
    List<Map<String, dynamic>>? opponentMoves,
    int? ratingDelta,
  }) {
    return OnlineGameState(
      gameRoomId: gameRoomId,
      localPlayerNumber: localPlayerNumber,
      opponentName: opponentName ?? this.opponentName,
      opponentRating: opponentRating ?? this.opponentRating,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      board: board ?? this.board,
      phase: phase ?? this.phase,
      currentRoll: clearRoll ? null : (currentRoll ?? this.currentRoll),
      currentTurnMoves: currentTurnMoves ?? this.currentTurnMoves,
      availableMovesForSelected: clearSelectedPoint
          ? const []
          : (availableMovesForSelected ?? this.availableMovesForSelected),
      remainingDice: remainingDice ?? this.remainingDice,
      selectedPoint:
          clearSelectedPoint ? null : (selectedPoint ?? this.selectedPoint),
      undoStack: undoStack ?? this.undoStack,
      result: clearResult ? null : (result ?? this.result),
      doublingCube: doublingCube ?? this.doublingCube,
      pendingDoubleFrom: clearPendingDouble
          ? null
          : (pendingDoubleFrom ?? this.pendingDoubleFrom),
      opponentMoves: opponentMoves ?? this.opponentMoves,
      ratingDelta: ratingDelta ?? this.ratingDelta,
    );
  }
}

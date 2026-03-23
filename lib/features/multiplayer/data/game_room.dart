/// Firestore game room model for real-time multiplayer.
class GameRoom {
  final String gameId;
  final PlayerInfo player1;
  final PlayerInfo? player2;
  final Map<String, dynamic> boardState;
  final String currentTurn; // 'player1' or 'player2'
  final List<Map<String, dynamic>> moveHistory;
  final DiceState? diceRoll;
  final DoublingCubeState doublingCube;
  final GameRoomStatus status;
  final DateTime createdAt;
  final DateTime lastMoveAt;
  final int turnTimeLimit; // seconds
  final DateTime? turnStartedAt;

  /// Moves from the most recent turn (for animating opponent moves).
  final List<Map<String, dynamic>> lastTurnMoves;

  /// Winner: 'player1', 'player2', or null if game in progress.
  final String? winner;

  /// Heartbeat timestamps for disconnect detection.
  final Map<String, DateTime> heartbeats;

  /// Pending doubling offer: who offered ('player1' or 'player2'), or null.
  final String? pendingDoubleFrom;

  /// Game variant (portes, plakoto, fevga).
  final String variant;

  const GameRoom({
    required this.gameId,
    required this.player1,
    this.player2,
    required this.boardState,
    required this.currentTurn,
    this.moveHistory = const [],
    this.diceRoll,
    this.doublingCube = const DoublingCubeState(),
    this.status = GameRoomStatus.waiting,
    required this.createdAt,
    required this.lastMoveAt,
    this.turnTimeLimit = 30,
    this.turnStartedAt,
    this.lastTurnMoves = const [],
    this.winner,
    this.heartbeats = const {},
    this.pendingDoubleFrom,
    this.variant = 'portes',
  });

  GameRoom copyWith({
    PlayerInfo? player1,
    PlayerInfo? player2,
    Map<String, dynamic>? boardState,
    String? currentTurn,
    List<Map<String, dynamic>>? moveHistory,
    DiceState? diceRoll,
    bool clearDiceRoll = false,
    DoublingCubeState? doublingCube,
    GameRoomStatus? status,
    DateTime? lastMoveAt,
    DateTime? turnStartedAt,
    bool clearTurnStartedAt = false,
    List<Map<String, dynamic>>? lastTurnMoves,
    String? winner,
    Map<String, DateTime>? heartbeats,
    String? pendingDoubleFrom,
    bool clearPendingDouble = false,
  }) {
    return GameRoom(
      gameId: gameId,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      boardState: boardState ?? this.boardState,
      currentTurn: currentTurn ?? this.currentTurn,
      moveHistory: moveHistory ?? this.moveHistory,
      diceRoll: clearDiceRoll ? null : (diceRoll ?? this.diceRoll),
      doublingCube: doublingCube ?? this.doublingCube,
      status: status ?? this.status,
      createdAt: createdAt,
      lastMoveAt: lastMoveAt ?? this.lastMoveAt,
      turnTimeLimit: turnTimeLimit,
      turnStartedAt: clearTurnStartedAt
          ? null
          : (turnStartedAt ?? this.turnStartedAt),
      lastTurnMoves: lastTurnMoves ?? this.lastTurnMoves,
      winner: winner ?? this.winner,
      heartbeats: heartbeats ?? this.heartbeats,
      pendingDoubleFrom: clearPendingDouble
          ? null
          : (pendingDoubleFrom ?? this.pendingDoubleFrom),
      variant: variant,
    );
  }

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'players': {
          'player1': player1.toJson(),
          if (player2 != null) 'player2': player2!.toJson(),
        },
        'boardState': boardState,
        'currentTurn': currentTurn,
        'moveHistory': moveHistory,
        'diceRoll': diceRoll?.toJson(),
        'doublingCube': doublingCube.toJson(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'lastMoveAt': lastMoveAt.toIso8601String(),
        'turnTimeLimit': turnTimeLimit,
        'turnStartedAt': turnStartedAt?.toIso8601String(),
        'lastTurnMoves': lastTurnMoves,
        'winner': winner,
        'heartbeats': heartbeats.map(
          (k, v) => MapEntry(k, v.toIso8601String()),
        ),
        'pendingDoubleFrom': pendingDoubleFrom,
        'variant': variant,
      };

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    final players = json['players'] as Map<String, dynamic>;
    return GameRoom(
      gameId: json['gameId'] as String,
      player1:
          PlayerInfo.fromJson(players['player1'] as Map<String, dynamic>),
      player2: players['player2'] != null
          ? PlayerInfo.fromJson(players['player2'] as Map<String, dynamic>)
          : null,
      boardState: json['boardState'] as Map<String, dynamic>,
      currentTurn: json['currentTurn'] as String,
      moveHistory: (json['moveHistory'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [],
      diceRoll: json['diceRoll'] != null
          ? DiceState.fromJson(json['diceRoll'] as Map<String, dynamic>)
          : null,
      doublingCube: json['doublingCube'] != null
          ? DoublingCubeState.fromJson(
              json['doublingCube'] as Map<String, dynamic>)
          : const DoublingCubeState(),
      status: GameRoomStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMoveAt: DateTime.parse(json['lastMoveAt'] as String),
      turnTimeLimit: json['turnTimeLimit'] as int? ?? 30,
      turnStartedAt: json['turnStartedAt'] != null
          ? DateTime.parse(json['turnStartedAt'] as String)
          : null,
      lastTurnMoves: (json['lastTurnMoves'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [],
      winner: json['winner'] as String?,
      heartbeats: (json['heartbeats'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, DateTime.parse(v as String)),
          ) ??
          {},
      pendingDoubleFrom: json['pendingDoubleFrom'] as String?,
      variant: json['variant'] as String? ?? 'portes',
    );
  }
}

enum GameRoomStatus {
  waiting,
  inProgress,
  finished,
  abandoned,
}

class PlayerInfo {
  final String uid;
  final String name;
  final String color; // 'white' or 'black'
  final int rating;

  const PlayerInfo({
    required this.uid,
    required this.name,
    required this.color,
    this.rating = 1000,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'color': color,
        'rating': rating,
      };

  factory PlayerInfo.fromJson(Map<String, dynamic> json) => PlayerInfo(
        uid: json['uid'] as String,
        name: json['name'] as String,
        color: json['color'] as String,
        rating: json['rating'] as int? ?? 1000,
      );
}

class DiceState {
  final int die1;
  final int die2;

  const DiceState({required this.die1, required this.die2});

  Map<String, dynamic> toJson() => {'die1': die1, 'die2': die2};

  factory DiceState.fromJson(Map<String, dynamic> json) => DiceState(
        die1: json['die1'] as int,
        die2: json['die2'] as int,
      );
}

class DoublingCubeState {
  final int value;
  final String? owner; // 'player1', 'player2', or null

  const DoublingCubeState({this.value = 1, this.owner});

  Map<String, dynamic> toJson() => {'value': value, 'owner': owner};

  factory DoublingCubeState.fromJson(Map<String, dynamic> json) =>
      DoublingCubeState(
        value: json['value'] as int? ?? 1,
        owner: json['owner'] as String?,
      );
}

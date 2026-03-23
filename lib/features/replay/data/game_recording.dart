import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../../ai/difficulty/difficulty_level.dart';
import '../../game/data/models/board_state.dart';
import '../../game/data/models/game_result.dart';
import '../../game/data/models/move.dart';

/// A single recorded turn in a game.
class RecordedTurn {
  /// Which player made this turn (1 or 2).
  final int player;

  /// Dice rolled this turn.
  final int die1;
  final int die2;

  /// Moves made this turn (in order).
  final List<Move> moves;

  /// Board state after this turn was completed.
  final BoardState boardAfter;

  const RecordedTurn({
    required this.player,
    required this.die1,
    required this.die2,
    required this.moves,
    required this.boardAfter,
  });

  Map<String, dynamic> toJson() => {
        'p': player,
        'd1': die1,
        'd2': die2,
        'moves': moves
            .map((m) => {
                  'from': m.fromPoint,
                  'to': m.toPoint,
                  'die': m.dieUsed,
                  'hit': m.isHit,
                })
            .toList(),
        'board': {
          'pts': boardAfter.points,
          'b1': boardAfter.bar1,
          'b2': boardAfter.bar2,
          'o1': boardAfter.borneOff1,
          'o2': boardAfter.borneOff2,
        },
      };

  factory RecordedTurn.fromJson(Map<String, dynamic> json) {
    final boardJson = json['board'] as Map<String, dynamic>;
    return RecordedTurn(
      player: json['p'] as int,
      die1: json['d1'] as int,
      die2: json['d2'] as int,
      moves: (json['moves'] as List)
          .map((m) => Move(
                fromPoint: m['from'] as int,
                toPoint: m['to'] as int,
                dieUsed: m['die'] as int,
                isHit: m['hit'] as bool? ?? false,
              ))
          .toList(),
      boardAfter: BoardState(
        points: (boardJson['pts'] as List).cast<int>(),
        bar1: boardJson['b1'] as int? ?? 0,
        bar2: boardJson['b2'] as int? ?? 0,
        borneOff1: boardJson['o1'] as int? ?? 0,
        borneOff2: boardJson['o2'] as int? ?? 0,
      ),
    );
  }
}

/// A complete recorded game, stored for replay.
class GameRecording {
  final String id;
  final DateTime timestamp;
  final String player1Name;
  final String player2Name;
  final DifficultyLevel? difficulty;
  final String mode; // 'bot', 'online', 'pass-play'
  final String variant; // 'portes', 'plakoto', 'fevga'
  final BoardState initialBoard;
  final List<RecordedTurn> turns;
  final GameResult? result;

  const GameRecording({
    required this.id,
    required this.timestamp,
    required this.player1Name,
    required this.player2Name,
    this.difficulty,
    this.mode = 'bot',
    this.variant = 'portes',
    required this.initialBoard,
    required this.turns,
    this.result,
  });

  int get turnCount => turns.length;
  bool get isComplete => result != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ts': timestamp.toIso8601String(),
        'p1': player1Name,
        'p2': player2Name,
        'diff': difficulty?.name,
        'mode': mode,
        'var': variant,
        'init': {
          'pts': initialBoard.points,
          'b1': initialBoard.bar1,
          'b2': initialBoard.bar2,
          'o1': initialBoard.borneOff1,
          'o2': initialBoard.borneOff2,
        },
        'turns': turns.map((t) => t.toJson()).toList(),
        'result': result != null
            ? {
                'winner': result!.winner,
                'type': result!.type.name,
                'cube': result!.cubeValue,
              }
            : null,
      };

  factory GameRecording.fromJson(Map<String, dynamic> json) {
    final initJson = json['init'] as Map<String, dynamic>;
    final resultJson = json['result'] as Map<String, dynamic>?;
    return GameRecording(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['ts'] as String),
      player1Name: json['p1'] as String,
      player2Name: json['p2'] as String,
      difficulty: json['diff'] != null
          ? DifficultyLevel.values.byName(json['diff'] as String)
          : null,
      mode: json['mode'] as String? ?? 'bot',
      variant: json['var'] as String? ?? 'portes',
      initialBoard: BoardState(
        points: (initJson['pts'] as List).cast<int>(),
        bar1: initJson['b1'] as int? ?? 0,
        bar2: initJson['b2'] as int? ?? 0,
        borneOff1: initJson['o1'] as int? ?? 0,
        borneOff2: initJson['o2'] as int? ?? 0,
      ),
      turns: (json['turns'] as List)
          .map((t) => RecordedTurn.fromJson(t as Map<String, dynamic>))
          .toList(),
      result: resultJson != null
          ? GameResult(
              winner: resultJson['winner'] as int,
              type: GameResultType.values.byName(resultJson['type'] as String),
              cubeValue: resultJson['cube'] as int? ?? 1,
            )
          : null,
    );
  }
}

/// Persists game recordings for replay.
class GameRecordingService {
  static const _key = 'tavli_recordings';
  static const _maxRecordings = 20;

  static Future<List<GameRecording>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => GameRecording.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<GameRecording?> load(String id) async {
    final all = await loadAll();
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(GameRecording recording) async {
    final recordings = await loadAll();
    recordings.insert(0, recording);
    if (recordings.length > _maxRecordings) recordings.removeLast();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
      _key,
      jsonEncode(recordings.map((r) => r.toJson()).toList()),
    );
  }

  static Future<void> delete(String id) async {
    final recordings = await loadAll();
    recordings.removeWhere((r) => r.id == id);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
      _key,
      jsonEncode(recordings.map((r) => r.toJson()).toList()),
    );
  }
}

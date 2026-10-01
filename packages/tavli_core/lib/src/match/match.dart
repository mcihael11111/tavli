/// The match layer: games in sequence, scores, Crawford (design spec §6;
/// plan Task 14).
library;

import '../board/side.dart';
import '../game/game_action.dart';
import '../game/game_event.dart';
import '../game/game_result.dart';
import '../game/game_state.dart';
import '../game/rule_violation.dart';
import '../serial/json_read.dart';
import '../util/list_eq.dart';
import '../variant/variant_rules.dart';
import 'match_action.dart';
import 'match_config.dart';
import 'match_event.dart';

part 'match_json.dart';
part 'match_reducer.dart';

/// A match, immutable. Advance it only with `reduceMatch`.
final class MatchState {
  final MatchConfig config;

  /// Points per side. Unmodifiable.
  final Map<Side, int> scores;

  /// Index of the current game (0-based) in the whole match.
  final int gameIndex;
  final GameState game;

  /// Results of the finished games, in order. Unmodifiable.
  final List<GameResult> history;

  /// Whether a side has reached `target - 1`, which decides the Crawford
  /// game once: it is being or has been played, or it was skipped because
  /// the next game's variant has no Crawford rule.
  final bool crawfordUsed;

  /// The match winner, once decided: the side that reached the target,
  /// the winner of a single game (null for a draw), or the opponent of
  /// [forfeitedBy].
  final Side? winner;

  /// The side that forfeited the match ([ForfeitMatch]), if any.
  final Side? forfeitedBy;

  MatchState({
    required this.config,
    required Map<Side, int> scores,
    required this.gameIndex,
    required this.game,
    required List<GameResult> history,
    required this.crawfordUsed,
    required this.winner,
    this.forfeitedBy,
  })  : scores = Map.unmodifiable(scores),
        history = List.unmodifiable(history);

  /// The first game of [config], opening with a roll.
  factory MatchState.initial(MatchConfig config) => MatchState(
        config: config,
        scores: const {Side.one: 0, Side.two: 0},
        gameIndex: 0,
        game: GameState.initial(
          config.cycle.first,
          cubeEnabled: config.cubeEnabled,
        ),
        history: const [],
        crawfordUsed: false,
        winner: null,
      );

  /// Schema v1 JSON (plan Task 15); the game is embedded as
  /// `GameState.toJson`.
  Map<String, Object?> toJson() => _matchToJson(this);

  /// Parses [toJson] output. Throws only [FormatException], also for a
  /// match `reduceMatch` could not have produced in ways that would break
  /// it (the game out of the cycle, a finished game missing from the
  /// history, a winner that does not follow from the scores).
  ///
  /// Trusted storage only: the scores, history and Crawford flag are not
  /// checked against each other, so a crafted state can carry any score.
  /// The server keeps the authoritative state; untrusted peers send
  /// actions (`MatchAction.fromJson`), never states.
  static MatchState fromJson(Object? json) => _matchFromJson(json);

  /// Whether the match is decided: a side reached the target, the single
  /// game is over, or a side forfeited.
  bool get isOver =>
      config.target == null ? game.phase == GamePhase.gameOver : winner != null;

  @override
  bool operator ==(Object other) =>
      other is MatchState &&
      other.config == config &&
      other.scores[Side.one] == scores[Side.one] &&
      other.scores[Side.two] == scores[Side.two] &&
      other.gameIndex == gameIndex &&
      other.game == game &&
      listEq(other.history, history) &&
      other.crawfordUsed == crawfordUsed &&
      other.winner == winner &&
      other.forfeitedBy == forfeitedBy;

  @override
  int get hashCode => Object.hash(
      config,
      scores[Side.one],
      scores[Side.two],
      gameIndex,
      game,
      Object.hashAll(history),
      crawfordUsed,
      winner,
      forfeitedBy);

  @override
  String toString() => 'MatchState(game $gameIndex, '
      '${scores[Side.one]}-${scores[Side.two]}, winner ${winner?.name})';
}

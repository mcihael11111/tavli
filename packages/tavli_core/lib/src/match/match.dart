/// The match layer: games in sequence, scores, Crawford (design spec §6;
/// plan Task 14).
library;

import '../board/side.dart';
import '../game/game_action.dart';
import '../game/game_event.dart';
import '../game/game_result.dart';
import '../game/game_state.dart';
import '../game/rule_violation.dart';
import '../variant/variant.dart';
import '../variant/variant_rules.dart';

/// What is played: the variant cycle, the target and the cube.
final class MatchConfig {
  /// The variants in order, repeating: `[v]` for one variant,
  /// [tavliMarathon] for Tavli. Unmodifiable, never empty.
  final List<Variant> cycle;

  /// Points to win; null for a single game.
  final int? target;

  /// Whether games use the cube (only where the variant has one).
  final bool cubeEnabled;

  /// The Greek Tavli marathon: Portes, Plakoto, Fevga in turn.
  static const tavliMarathon = [Variant.portes, Variant.plakoto, Variant.fevga];

  MatchConfig._(List<Variant> cycle, this.target, this.cubeEnabled)
      : cycle = List.unmodifiable(cycle);

  /// One game of [v]. A variant with a fixed target (Tawla 31, D21) is
  /// always a match to that target.
  factory MatchConfig.single(Variant v, {bool? cubeEnabled}) =>
      MatchConfig._build(null, [v], cubeEnabled);

  /// A match to [target] over [cycle]. A cycle with a fixed-target variant
  /// (Tawla 31) plays to that target instead. Throws [ArgumentError] for
  /// an empty cycle or a target below 1.
  factory MatchConfig.to(int target, List<Variant> cycle, {bool? cubeEnabled}) {
    if (target < 1) throw ArgumentError.value(target, 'target', 'below 1');
    return MatchConfig._build(target, cycle, cubeEnabled);
  }

  factory MatchConfig._build(int? target, List<Variant> cycle, bool? cube) {
    if (cycle.isEmpty) throw ArgumentError.value(cycle, 'cycle', 'empty');
    for (final v in cycle) {
      target = v.rules.match.fixedTarget ?? target;
    }
    return MatchConfig._(
      cycle,
      target,
      cube ?? cycle.any((v) => v.rules.cube.enabledByDefault),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MatchConfig &&
      other.target == target &&
      other.cubeEnabled == cubeEnabled &&
      _listEq(other.cycle, cycle);

  @override
  int get hashCode => Object.hash(Object.hashAll(cycle), target, cubeEnabled);

  @override
  String toString() =>
      'MatchConfig(${cycle.map((v) => v.name).join(', ')}, to $target, '
      'cube $cubeEnabled)';
}

/// An input to `reduceMatch`.
sealed class MatchAction {
  const MatchAction();
}

/// An action for the current game.
final class GameMove extends MatchAction {
  final GameAction action;
  const GameMove(this.action);

  @override
  bool operator ==(Object other) => other is GameMove && other.action == action;

  @override
  int get hashCode => Object.hash('move', action);

  @override
  String toString() => 'GameMove($action)';
}

/// Starts the next game of the cycle once the current one is over.
final class NextGame extends MatchAction {
  const NextGame();

  @override
  bool operator ==(Object other) => other is NextGame;

  @override
  int get hashCode => 'nextGame'.hashCode;

  @override
  String toString() => 'NextGame()';
}

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

  /// Whether the Crawford game has been played or is being played.
  final bool crawfordUsed;

  /// The match winner, once decided.
  final Side? winner;

  MatchState({
    required this.config,
    required Map<Side, int> scores,
    required this.gameIndex,
    required this.game,
    required List<GameResult> history,
    required this.crawfordUsed,
    required this.winner,
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

  /// Whether the match is decided: a side reached the target, or the
  /// single game is over.
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
      _listEq(other.history, history) &&
      other.crawfordUsed == crawfordUsed &&
      other.winner == winner;

  @override
  int get hashCode => Object.hash(config, scores[Side.one], scores[Side.two],
      gameIndex, game, Object.hashAll(history), crawfordUsed, winner);

  @override
  String toString() => 'MatchState(game $gameIndex, '
      '${scores[Side.one]}-${scores[Side.two]}, winner ${winner?.name})';
}

/// Applies [a] to [m] (plan Task 14). [by] is passed to `reduce` for a
/// [GameMove] (see `actorOf`). Never throws on bad input.
MatchReduceResult reduceMatch(MatchState m, MatchAction a, {Side? by}) {
  switch (a) {
    case GameMove(:final action):
      switch (reduce(m.game, action, by: by)) {
        case RuleViolation() && final v:
          return v;
        case GameUpdate(:final state, :final events):
          return MatchUpdate(_afterGame(m, state, events), events);
      }
    case NextGame():
      if (m.isOver) {
        return const RuleViolation(
          ViolationCode.gameOver,
          'the match is over',
        );
      }
      if (m.game.phase != GamePhase.gameOver) {
        return const RuleViolation(
          ViolationCode.wrongPhase,
          'the current game is not over',
        );
      }
      return MatchUpdate(_nextGame(m), const []);
  }
}

/// [m] with its game replaced by [game]; on [GameEnded], scores the
/// result (a draw scores for both) and checks the target.
MatchState _afterGame(MatchState m, GameState game, List<GameEvent> events) {
  final ended = events.whereType<GameEnded>().firstOrNull;
  if (ended == null) return _with(m, game: game);
  final r = ended.result;
  final scores = {
    for (final s in Side.values)
      s: m.scores[s]! + (r.winner == null || r.winner == s ? r.points : 0),
  };
  return _with(
    m,
    game: game,
    scores: scores,
    history: [...m.history, r],
    winner: _matchWinner(m.config.target, scores),
  );
}

/// The side that reached [target], if any. When both did (a draw scoring
/// for both), the higher score wins; equal scores keep the match going.
Side? _matchWinner(int? target, Map<Side, int> scores) {
  if (target == null) return null;
  final one = scores[Side.one]!, two = scores[Side.two]!;
  if (one < target && two < target) return null;
  if (one == two) return null;
  return one > two ? Side.one : Side.two;
}

/// The next game of the cycle: the previous winner starts where its rules
/// say so (D2) and the last game had a winner; otherwise an opening roll.
/// The first game after a side reaches `target - 1` is the Crawford game
/// when that variant's cube uses the Crawford rule.
MatchState _nextGame(MatchState m) {
  final index = m.gameIndex + 1;
  final variant = m.config.cycle[index % m.config.cycle.length];
  final rules = variant.rules;
  final last = m.history.last;
  final starter =
      rules.nextGame == NextGameStarter.previousWinner ? last.winner : null;
  final target = m.config.target;
  final crawford = target != null &&
      !m.crawfordUsed &&
      rules.cube.crawford &&
      m.scores.values.any((s) => s == target - 1);
  return _with(
    m,
    gameIndex: index,
    game: GameState.initial(
      variant,
      starter: starter,
      crawfordGame: crawford,
      cubeEnabled: m.config.cubeEnabled,
    ),
    crawfordUsed: m.crawfordUsed || crawford,
  );
}

MatchState _with(
  MatchState m, {
  required GameState game,
  int? gameIndex,
  Map<Side, int>? scores,
  List<GameResult>? history,
  bool? crawfordUsed,
  Side? winner,
}) =>
    MatchState(
      config: m.config,
      scores: scores ?? m.scores,
      gameIndex: gameIndex ?? m.gameIndex,
      game: game,
      history: history ?? m.history,
      crawfordUsed: crawfordUsed ?? m.crawfordUsed,
      winner: winner ?? m.winner,
    );

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

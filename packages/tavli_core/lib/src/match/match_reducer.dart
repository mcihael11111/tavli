part of 'match.dart';

// The match reducer (plan Task 14).

/// The side that must send [a] in [m], or null when either side (or the
/// system) may: `actorOf` for a [GameMove], the forfeiting side for a
/// [ForfeitMatch], null for [NextGame].
Side? matchActorOf(MatchState m, MatchAction a) => switch (a) {
      GameMove(:final action) => actorOf(m.game, action),
      NextGame() => null,
      ForfeitMatch(:final side) => side,
    };

/// Applies [a] to [m] (plan Task 14). With [by] (the authenticated
/// sender), an action whose [matchActorOf] is another side is a
/// `notYourAction` violation. Never throws on bad input.
MatchReduceResult reduceMatch(MatchState m, MatchAction a, {Side? by}) {
  switch (a) {
    case GameMove(:final action):
      switch (reduce(m.game, action, by: by)) {
        case RuleViolation() && final v:
          return v;
        case GameUpdate(:final state, :final events):
          final next = _afterGame(m, state, events);
          return MatchUpdate(next, [
            for (final e in events) InGame(e),
            if (next.isOver && !m.isOver) _ended(next),
          ]);
      }
    case NextGame():
      if (m.isOver) return _matchOver;
      if (m.game.phase != GamePhase.gameOver) {
        return const RuleViolation(
          ViolationCode.wrongPhase,
          'the current game is not over',
        );
      }
      final next = _nextGame(m);
      final g = next.game;
      return MatchUpdate(next, [
        GameStarted(next.gameIndex, g.variant, g.sideToMove, g.crawfordGame),
      ]);
    case ForfeitMatch(:final side):
      if (m.isOver) return _matchOver;
      if (by != null && by != side) {
        return RuleViolation(
          ViolationCode.notYourAction,
          '$a is for ${side.name}, not ${by.name}',
        );
      }
      return _forfeitMatch(m, side);
  }
}

const _matchOver = RuleViolation(ViolationCode.gameOver, 'the match is over');

MatchEnded _ended(MatchState m) => MatchEnded(m.winner, m.scores);

/// [loser] forfeits: the current game, unless over, is resigned (A9),
/// then the opponent wins the match.
MatchUpdate _forfeitMatch(MatchState m, Side loser) {
  final events = <MatchEvent>[];
  var played = m;
  if (m.game.phase != GamePhase.gameOver) {
    final u = reduce(m.game, Resign(loser)) as GameUpdate;
    played = _afterGame(m, u.state, u.events);
    events.addAll([for (final e in u.events) InGame(e)]);
  }
  final next = MatchState(
    config: played.config,
    scores: played.scores,
    gameIndex: played.gameIndex,
    game: played.game,
    history: played.history,
    crawfordUsed: played.crawfordUsed,
    winner: loser.opponent,
    forfeitedBy: loser,
  );
  return MatchUpdate(next, [...events, _ended(next)]);
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
    winner: m.config.target == null
        ? r.winner
        : _matchWinner(m.config.target, scores),
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
/// The first game after a side first reaches `target - 1` is the Crawford
/// game when that variant's cube uses the Crawford rule; either way the
/// chance is used up.
MatchState _nextGame(MatchState m) {
  final index = m.gameIndex + 1;
  final variant = m.config.cycle[index % m.config.cycle.length];
  final rules = variant.rules;
  final last = m.history.last;
  final starter =
      rules.nextGame == NextGameStarter.previousWinner ? last.winner : null;
  final target = m.config.target;
  // The first time a side stands at target - 1 decides the Crawford game:
  // this game, if its variant uses the rule; otherwise never.
  final firstReach = target != null &&
      !m.crawfordUsed &&
      m.scores.values.any((s) => s == target - 1);
  final crawford = firstReach && rules.cube.crawford;
  return _with(
    m,
    gameIndex: index,
    game: GameState.initial(
      variant,
      starter: starter,
      crawfordGame: crawford,
      cubeEnabled: m.config.cubeEnabled,
    ),
    crawfordUsed: m.crawfordUsed || firstReach,
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
      forfeitedBy: m.forfeitedBy,
    );

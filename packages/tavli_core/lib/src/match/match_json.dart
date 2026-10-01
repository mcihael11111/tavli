part of 'match.dart';

Map<String, Object?> _matchToJson(MatchState m) => {
      'schemaVersion': tavliCoreSchemaVersion,
      'config': m.config.toJson(),
      'scores': {for (final s in Side.values) s.name: m.scores[s]},
      'gameIndex': m.gameIndex,
      'game': m.game.toJson(),
      'history': [for (final r in m.history) r.toJson()],
      'crawfordUsed': m.crawfordUsed,
      'winner': m.winner?.toJson(),
    };

MatchState _matchFromJson(Object? json) {
  final r = JsonReader(json, 'MatchState')..checkSchema();
  final config = MatchConfig.fromJson(r.raw('config'));
  final scores = JsonReader(r.raw('scores'), 'MatchState.scores');
  final gameIndex = r.integer('gameIndex');
  final game = GameState.fromJson(r.raw('game'));
  final m = MatchState(
    config: config,
    scores: {for (final s in Side.values) s: scores.integer(s.name)},
    gameIndex: gameIndex,
    game: game,
    history: [for (final h in r.list('history')) GameResult.fromJson(h)],
    crawfordUsed: r.boolean('crawfordUsed'),
    winner: r.nullableSide('winner'),
  );
  if (game.variant != config.cycle[gameIndex % config.cycle.length]) {
    r.fail('game', "the cycle's variant for game $gameIndex");
  }
  if (game.cube.enabled && !config.cubeEnabled) {
    r.fail('game', 'without a cube, as configured');
  }
  if (game.phase == GamePhase.gameOver &&
      (m.history.isEmpty || m.history.last != game.result)) {
    r.fail('history', "ending with the finished game's result");
  }
  if (m.winner != _matchWinner(config.target, m.scores)) {
    r.fail('winner', 'the side the scores make the winner');
  }
  return m;
}

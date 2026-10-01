part of 'game_state.dart';

// GameState JSON (plan Task 15). The board after the steps, the turn
// context, the pending remainder and the play tree are not stored: they
// are rebuilt from turnStart, dice, cascadeMode and steps, which also
// checks that the steps are a legal prefix of a play.

Map<String, Object?> _gameStateToJson(GameState s) => {
      'schemaVersion': tavliCoreSchemaVersion,
      'variant': s.variant.name,
      'phase': s.phase.name,
      'sideToMove': s.sideToMove?.toJson(),
      'turnStart': s.turnStart.toJson(),
      'dice': s.dice,
      'cascadeMode': s.cascadeMode,
      'steps': [for (final st in s.steps) st.toJson()],
      'rollIndex': s.rollIndex,
      'turnsTaken': {
        for (final side in Side.values) side.name: s.turnsTaken[side],
      },
      'cube': s.cube.toJson(),
      'remainderTurn': s.remainderTurn,
      'result': s.result?.toJson(),
      'crawfordGame': s.crawfordGame,
    };

GameState _gameStateFromJson(Object? json) {
  final r = JsonReader(json, 'GameState')..checkSchema();
  final variant = r.byName('variant', Variant.values);
  final rules = variant.rules;
  final phase = r.byName('phase', GamePhase.values);
  final side = r.nullableSide('sideToMove');
  final turnStart = Position.fromJson(_object(r, 'turnStart'));
  if (turnStart.direction != rules.direction) {
    r.fail('turnStart', 'a ${rules.direction.name}-direction position');
  }
  final dice = r.ints('dice', min: 1, max: 6);
  final cascadeMode = r.boolean('cascadeMode');
  final steps = [
    for (final st in r.list('steps'))
      Step.fromJson(st is Map<String, Object?>
          ? st
          : throw FormatException('GameState: bad step', st)),
  ];
  final turns = JsonReader(r.raw('turnsTaken'), 'GameState.turnsTaken');
  final turnsTaken = {for (final s in Side.values) s: turns.integer(s.name)};
  final cube = CubeState.fromJson(r.raw('cube'));
  final remainderTurn = r.boolean('remainderTurn');
  final rawResult = r.raw('result');
  final result = rawResult == null ? null : GameResult.fromJson(rawResult);

  // The shape of each phase, so that `reduce` can rely on it.
  final over = phase == GamePhase.gameOver;
  final playing = phase == GamePhase.moving || over && dice.isNotEmpty;
  void need(bool ok, String key, String expected) {
    if (!ok) r.fail(key, expected);
  }

  need(side != null || phase == GamePhase.opening || over && dice.isEmpty,
      'sideToMove', 'set outside the opening');
  need(side == null || phase != GamePhase.opening, 'sideToMove',
      'null in the opening');
  need((result != null) == over, 'result', 'set exactly when the game is over');
  need(
      !cube.enabled || rules.cube.available, 'cube', 'off for ${variant.name}');
  need(
    phase == GamePhase.cubeOffered
        ? cube.offeredBy == side
        : cube.offeredBy == null,
    'cube',
    'offered exactly in cubeOffered, by the side to move',
  );
  need(playing || dice.isEmpty && !cascadeMode && !remainderTurn, 'dice',
      'empty outside a moving phase');
  need(phase != GamePhase.moving || dice.isNotEmpty, 'dice', 'set in moving');
  need(steps.isEmpty || dice.isNotEmpty, 'steps', 'empty without dice');
  need(!cascadeMode || rules.doubles == DoublesMode.cascade, 'cascadeMode',
      'false for ${variant.name}');
  need(!remainderTurn || cascadeMode, 'remainderTurn', 'only in a cascade');
  if (dice.isNotEmpty) {
    final four = dice.length == 4 && dice.every((d) => d == dice[0]);
    final two = dice.length == 2 && dice[0] != dice[1];
    need(cascadeMode ? dice.length <= 24 : two || four, 'dice',
        '[a, b], [d, d, d, d] or a cascade queue');
  }

  var s = GameState._(
    variant: variant,
    sideToMove: side,
    phase: phase,
    position: turnStart,
    turnStart: turnStart,
    dice: dice,
    cascadeMode: cascadeMode,
    steps: const [],
    context: _startContext(side, turnsTaken, dice),
    rollIndex: r.integer('rollIndex'),
    turnsTaken: turnsTaken,
    cube: cube,
    pendingRemainder: const [],
    remainderTurn: remainderTurn,
    result: result,
    crawfordGame: r.boolean('crawfordGame'),
  );
  if (dice.isEmpty) {
    need(over || !_finished(turnStart, rules), 'turnStart', 'not finished');
    return s;
  }

  // Replay the steps through the play tree.
  final tree = s.tree;
  need(tree.hasPlay, 'dice', 'playable when moving');
  final stepRules = StepRules(rules), validators = StepValidators(rules);
  final m = turnStart.toMutable();
  var ctx = s.context;
  var node = tree.root;
  GameResult? ended;
  for (final st in steps) {
    need(ended == null, 'steps', 'stopping at the game-ending step');
    final next = node.child(st);
    if (next == null) r.fail('steps', 'a legal prefix of a play');
    node = next;
    ctx = validators.next(ctx, stepRules.apply(m, side!, st));
    ended = checkGameEnd(m, rules, justMoved: side, cubeValue: cube.value);
  }
  final position = m.freeze();
  need(ended == null || ended == result, 'result', 'the end the steps made');
  need(over || !_finished(position, rules), 'steps', 'not ending the game');
  s = s._copy(position: position, steps: steps, context: ctx, keepTree: true);
  return s._copy(pendingRemainder: _pendingRemainder(s), keepTree: true);
}

/// Whether [p] is already a finished game (for either side).
bool _finished(Position p, VariantRules rules) =>
    Side.values.any((s) => endsGame(p, rules, s));

Map<String, Object?> _object(JsonReader r, String key) {
  final v = r.raw(key);
  if (v is! Map<String, Object?>) r.fail(key, 'an object');
  return v;
}

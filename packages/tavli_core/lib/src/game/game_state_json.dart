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
  final misfit = _misfit(turnStart, rules);
  if (misfit != null) r.fail('turnStart', 'a ${variant.name} board $misfit');
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
  final crawfordGame = r.boolean('crawfordGame');

  // The shape of each phase, so that `reduce` can rely on it.
  final over = phase == GamePhase.gameOver;
  final playing = phase == GamePhase.moving || over && dice.isNotEmpty;
  r.check(side != null || phase == GamePhase.opening || over && dice.isEmpty,
      'sideToMove', 'set outside the opening');
  r.check(side == null || phase != GamePhase.opening, 'sideToMove',
      'null in the opening');
  r.check(
      (result != null) == over, 'result', 'set exactly when the game is over');
  r.check(
      !cube.enabled || rules.cube.available, 'cube', 'off for ${variant.name}');
  r.check(
    phase == GamePhase.cubeOffered
        ? cube.offeredBy == side
        : cube.offeredBy == null,
    'cube',
    'offered exactly in cubeOffered, by the side to move',
  );
  // A pending offer is one `_offer` could have made.
  r.check(
    phase != GamePhase.cubeOffered ||
        cube.value < 64 &&
            !crawfordGame &&
            (cube.owner == null || cube.owner == side),
    'cube',
    'below 64, outside the Crawford game and not owned by the opponent '
        'when offered',
  );
  r.check(playing || dice.isEmpty && !cascadeMode && !remainderTurn, 'dice',
      'empty outside a moving phase');
  r.check(
      phase != GamePhase.moving || dice.isNotEmpty, 'dice', 'set in moving');
  r.check(steps.isEmpty || dice.isNotEmpty, 'steps', 'empty without dice');
  r.check(!cascadeMode || rules.doubles == DoublesMode.cascade, 'cascadeMode',
      'false for ${variant.name}');
  r.check(!remainderTurn || cascadeMode, 'remainderTurn', 'only in a cascade');
  if (dice.isNotEmpty) {
    final four = dice.length == 4 && dice.every((d) => d == dice[0]);
    final two = dice.length == 2 && dice[0] != dice[1];
    r.check(cascadeMode ? _isCascade(dice, remainderTurn) : two || four, 'dice',
        '[a, b], [d, d, d, d], a cascade queue or a remainder of one');
  }

  final s = GameState._(
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
    crawfordGame: crawfordGame,
  );
  if (dice.isEmpty) {
    r.check(over || !_finished(turnStart, rules), 'turnStart', 'not finished');
    return s;
  }

  // Replay the steps through the play tree. Nothing in it should throw
  // for a state that passed the checks above; if anything still does,
  // the state is malformed all the same.
  try {
    return _replaySteps(r, s, steps);
  } on ArgumentError catch (e) {
    throw FormatException('GameState: unplayable state: $e', json);
  }
}

/// [s] (at its turn start) with [steps] replayed through its play tree.
GameState _replaySteps(JsonReader r, GameState s, List<Step> steps) {
  final rules = s.variant.rules, side = s.sideToMove, over = s.result != null;
  final tree = s.tree;
  r.check(tree.hasPlay, 'dice', 'playable when moving');
  final stepRules = StepRules(rules), validators = StepValidators(rules);
  final m = s.turnStart.toMutable();
  var ctx = s.context;
  var node = tree.root;
  GameResult? ended;
  for (final st in steps) {
    r.check(ended == null, 'steps', 'stopping at the game-ending step');
    final next = node.child(st);
    if (next == null) r.fail('steps', 'a legal prefix of a play');
    node = next;
    ctx = validators.next(ctx, stepRules.apply(m, side!, st));
    ended = checkGameEnd(m, rules, justMoved: side, cubeValue: s.cube.value);
  }
  final position = m.freeze();
  r.check(
      ended == null || ended == s.result, 'result', 'the end the steps made');
  r.check(over || !_finished(position, rules), 'steps', 'not ending the game');
  final played =
      s._copy(position: position, steps: steps, context: ctx, keepTree: true);
  return played._copy(
    pendingRemainder: _pendingRemainder(played),
    keepTree: true,
  );
}

/// What [p] lacks to occur in a game of [rules], or null: the variant's
/// direction, no pinned checkers unless it pins, no checkers on the bar
/// unless it hits.
String? _misfit(Position p, VariantRules rules) {
  if (p.direction != rules.direction) {
    return 'in the ${rules.direction.name} direction';
  }
  if (rules.contact != Contact.pin) {
    for (var pip = 1; pip <= 24; pip++) {
      if (p.isPinned(Side.one, pip) || p.isPinned(Side.two, pip)) {
        return 'without pinned checkers';
      }
    }
  }
  if (rules.contact != Contact.hit && Side.values.any((s) => p.onBar(s) > 0)) {
    return 'without checkers on the bar';
  }
  return null;
}

/// Whether [dice] can be a cascade's queue: a whole [cascadeQueue], or,
/// in a [remainderTurn], any non-empty tail of one (D15, D16-B).
bool _isCascade(List<int> dice, bool remainderTurn) {
  final all = cascadeQueue(1); // every cascade queue is a tail of this
  final n = dice.length;
  return n >= 1 &&
      n <= all.length &&
      (remainderTurn || n % 4 == 0) &&
      listEq(dice, all.sublist(all.length - n));
}

/// Whether [p] is already a finished game (for either side).
bool _finished(Position p, VariantRules rules) =>
    Side.values.any((s) => endsGame(p, rules, s));

Map<String, Object?> _object(JsonReader r, String key) {
  final v = r.raw(key);
  if (v is! Map<String, Object?>) r.fail(key, 'an object');
  return v;
}

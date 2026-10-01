/// The immutable game state and the reducer (design spec §5.1, §5.3).
library;

import '../board/position.dart';
import '../board/side.dart';
import '../play/play_generator.dart';
import '../play/step.dart';
import '../rules/game_end.dart';
import '../rules/step_rules.dart';
import '../rules/step_validators.dart';
import '../rules/turn_context.dart';
import '../variant/variant.dart';
import '../variant/variant_rules.dart';
import 'cube.dart';
import 'game_action.dart';
import 'game_event.dart';
import 'game_result.dart';
import 'rule_violation.dart';

part 'reducer.dart';

/// Where a game is in its turn cycle.
enum GamePhase { opening, awaitingRoll, cubeOffered, moving, gameOver }

/// One game, immutable. Advance it only with `reduce`.
///
/// Value equality covers every field; the cached [tree] is not part of it.
final class GameState {
  final Variant variant;

  /// Null only before the opening roll is decided (and after a resign or
  /// timeout during the opening).
  final Side? sideToMove;
  final GamePhase phase;

  /// The current position, after [steps].
  final Position position;

  /// The position at the start of the current moving phase.
  final Position turnStart;

  /// The dice of the current moving phase: `[a, b]`, `[d, d, d, d]`, or a
  /// cascade queue when [cascadeMode]. Empty outside a moving phase.
  final List<int> dice;

  /// Whether [dice] is a Gul Bara cascade queue (D15).
  final bool cascadeMode;

  /// The steps taken this moving phase.
  final List<Step> steps;

  /// The turn context after [steps].
  final TurnContext context;

  /// The number of rolls accepted this game, the D1-A opening included.
  final int rollIndex;

  /// Turns completed per side (committed or passed).
  final Map<Side, int> turnsTaken;
  final CubeState cube;

  /// Gul Bara D16-B: dice the opponent is to play (Task 12).
  final List<int> pendingRemainder;

  /// Whether the side to move is playing an opponent's remainder (Task 12).
  final bool remainderTurn;
  final GameResult? result;
  final bool crawfordGame;

  PlayTree? _tree;

  GameState._({
    required this.variant,
    required this.sideToMove,
    required this.phase,
    required this.position,
    required this.turnStart,
    required List<int> dice,
    required this.cascadeMode,
    required List<Step> steps,
    required this.context,
    required this.rollIndex,
    required Map<Side, int> turnsTaken,
    required this.cube,
    required List<int> pendingRemainder,
    required this.remainderTurn,
    required this.result,
    required this.crawfordGame,
    PlayTree? tree,
  })  : dice = List.unmodifiable(dice),
        steps = List.unmodifiable(steps),
        turnsTaken = Map.unmodifiable(turnsTaken),
        pendingRemainder = List.unmodifiable(pendingRemainder),
        _tree = tree;

  /// A new game of [v] at its start position.
  ///
  /// With [starter] the opening roll is skipped and [starter] rolls first
  /// (D2 previous winner); otherwise the game starts in `opening`.
  /// [cubeEnabled] defaults to the variant's `cube.enabledByDefault`; the
  /// cube is never enabled for a variant without one.
  static GameState initial(
    Variant v, {
    Side? starter,
    bool crawfordGame = false,
    bool? cubeEnabled,
  }) {
    final rules = v.rules;
    final p = Position.forRules(rules);
    const turns = {Side.one: 0, Side.two: 0};
    return GameState._(
      variant: v,
      sideToMove: starter,
      phase: starter == null ? GamePhase.opening : GamePhase.awaitingRoll,
      position: p,
      turnStart: p,
      dice: const [],
      cascadeMode: false,
      steps: const [],
      context: _startContext(starter, turns, const []),
      rollIndex: 0,
      turnsTaken: turns,
      cube: CubeState(
        enabled: rules.cube.available &&
            (cubeEnabled ?? rules.cube.enabledByDefault),
      ),
      pendingRemainder: const [],
      remainderTurn: false,
      result: null,
      crawfordGame: crawfordGame,
    );
  }

  /// A copy of a non-moving state with [position] as the board, for
  /// setting up scenarios (tests, puzzles, a resumed game).
  GameState withPosition(Position position) {
    if (phase == GamePhase.moving) {
      throw StateError('withPosition during a moving phase');
    }
    return _copy(position: position, turnStart: position);
  }

  /// Every legal play of the current moving phase, generated on first use
  /// from [turnStart], [dice], [cascadeMode] and the turn-start context,
  /// then cached. Throws [StateError] when there are no dice to play.
  PlayTree get tree => _tree ??= _buildTree();

  /// The node of [tree] reached by [steps].
  PlayNode get node => tree.walk(steps)!;

  PlayTree _buildTree() {
    final side = sideToMove;
    if (side == null || dice.isEmpty) {
      throw StateError('no dice to play in $phase');
    }
    final rules = variant.rules;
    final ctx = _startContext(side, turnsTaken, const []);
    return cascadeMode
        ? generateCascade(turnStart, side, dice, rules, ctx)
        : generatePlays(turnStart, side, dice, rules, ctx);
  }

  /// A copy with the given fields replaced. [keepTree] carries the cached
  /// tree over (only valid while turnStart, dice and the side stay).
  GameState _copy({
    Side? sideToMove,
    GamePhase? phase,
    Position? position,
    Position? turnStart,
    List<int>? dice,
    bool? cascadeMode,
    List<Step>? steps,
    TurnContext? context,
    int? rollIndex,
    Map<Side, int>? turnsTaken,
    CubeState? cube,
    GameResult? result,
    bool keepTree = false,
  }) =>
      GameState._(
        variant: variant,
        sideToMove: sideToMove ?? this.sideToMove,
        phase: phase ?? this.phase,
        position: position ?? this.position,
        turnStart: turnStart ?? this.turnStart,
        dice: dice ?? this.dice,
        cascadeMode: cascadeMode ?? this.cascadeMode,
        steps: steps ?? this.steps,
        context: context ?? this.context,
        rollIndex: rollIndex ?? this.rollIndex,
        turnsTaken: turnsTaken ?? this.turnsTaken,
        cube: cube ?? this.cube,
        pendingRemainder: pendingRemainder,
        remainderTurn: remainderTurn,
        result: result ?? this.result,
        crawfordGame: crawfordGame,
        tree: keepTree ? _tree : null,
      );

  @override
  bool operator ==(Object other) =>
      other is GameState &&
      other.variant == variant &&
      other.sideToMove == sideToMove &&
      other.phase == phase &&
      other.position == position &&
      other.turnStart == turnStart &&
      _listEq(other.dice, dice) &&
      other.cascadeMode == cascadeMode &&
      _listEq(other.steps, steps) &&
      other.context == context &&
      other.rollIndex == rollIndex &&
      other.turnsTaken[Side.one] == turnsTaken[Side.one] &&
      other.turnsTaken[Side.two] == turnsTaken[Side.two] &&
      other.cube == cube &&
      _listEq(other.pendingRemainder, pendingRemainder) &&
      other.remainderTurn == remainderTurn &&
      other.result == result &&
      other.crawfordGame == crawfordGame;

  @override
  int get hashCode => Object.hash(
        variant,
        sideToMove,
        phase,
        position,
        Object.hashAll(dice),
        Object.hashAll(steps),
        context,
        rollIndex,
        turnsTaken[Side.one],
        turnsTaken[Side.two],
        cube,
        result,
      );

  @override
  String toString() => 'GameState(${variant.name}, ${phase.name}, '
      'to move: ${sideToMove?.name}, dice: $dice, steps: $steps, '
      'roll $rollIndex, $position)';

  static bool _listEq<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// The context at the start of [side]'s moving phase with [dice]: its
/// first turn (D18) while it has completed no turn.
TurnContext _startContext(Side? side, Map<Side, int> turns, List<int> dice) =>
    TurnContext(
      firstTurn: side != null && turns[side] == 0,
      diceOfTurn: dice,
    );

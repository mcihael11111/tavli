/// Headless tournament games between two players (plan Task 10, design
/// spec SP2 §1.4, §9). Pure: the CLI (`tool/tournament.dart`) runs the
/// pairs on parallel isolates; tests run them in-process.
library;

import 'dart:math';

import 'package:tavli_core/tavli_core.dart';

import '../bot.dart';
import '../level/bot_level.dart';
import '../search/search.dart';

/// A tournament player: chooses the play of the side to move.
abstract interface class TournamentPlayer {
  /// The steps for [s]'s side to move, in a `moving` phase with no step
  /// taken yet: a complete legal play of `s.tree`. [seed] seeds the
  /// player's randomness for this decision.
  List<Step> choose(GameState s, int seed);

  /// The stats of the last [choose], if the player reports them.
  DecisionStats? get last;
}

/// What a [TournamentPlayer] reports about one decision (for the stats).
final class DecisionStats {
  const DecisionStats(this.depth, this.timedOut, this.elapsedUs);
  final int depth;
  final bool timedOut;
  final int elapsedUs;
}

/// The bot as a tournament player: [choosePlay] under [profile] with a
/// [budget] (the profile's device budget unless set; a cascade gets
/// twice it), of which the search gets [Bot.searchBudget], as in
/// `Bot.decide`.
final class BotPlayer implements TournamentPlayer {
  BotPlayer(this.profile, {this.budget});

  /// The bot at [level]'s profile.
  BotPlayer.level(BotLevel level, {Duration? budget})
      : this(LevelProfile.of(level), budget: budget);

  final LevelProfile profile;
  final Duration? budget;

  @override
  DecisionStats? last;

  @override
  List<Step> choose(GameState s, int seed) {
    final b = budget ?? profile.budget;
    final r = choosePlay(
      position: s.position,
      side: s.sideToMove!,
      dice: s.dice,
      cascade: s.cascadeMode,
      context: s.context,
      rules: s.variant.rules,
      profile: profile,
      rng: Random(seed),
      budget: Bot.searchBudget(s.cascadeMode ? b * 2 : b),
    );
    last = DecisionStats(
        r.stats.depthReached, r.stats.timedOut, r.stats.elapsedUs);
    return r.play.steps;
  }
}

/// Per-player totals over a game.
final class PlayerTally {
  /// Decisions with more than one legal play (the others are forced).
  int decisions = 0;
  int timedOut = 0;

  /// Decisions by the depth the search reached (0, 1, 2).
  final List<int> depths = [0, 0, 0];
  int elapsedUs = 0, maxUs = 0;

  void add(PlayerTally o) {
    decisions += o.decisions;
    timedOut += o.timedOut;
    for (var i = 0; i < depths.length; i++) {
      depths[i] += o.depths[i];
    }
    elapsedUs += o.elapsedUs;
    maxUs = max(maxUs, o.maxUs);
  }

  void _record(DecisionStats d) {
    decisions++;
    if (d.timedOut) timedOut++;
    depths[d.depth.clamp(0, 2)]++;
    elapsedUs += d.elapsedUs;
    maxUs = max(maxUs, d.elapsedUs);
  }
}

/// One game of a mirrored pair, from player A's point of view.
final class GameOutcome {
  GameOutcome({
    required this.pair,
    required this.aIsOne,
    required this.result,
    required this.turns,
    required this.tallyA,
    required this.tallyB,
  });

  /// The pair's index; its two games share the dice seed.
  final int pair;

  /// Whether A played `Side.one` (seat one) in this game.
  final bool aIsOne;

  /// Null when the game hit the turn cap (counted as a draw).
  final GameResult? result;
  final int turns;
  final PlayerTally tallyA, tallyB;

  Side get _sideA => aIsOne ? Side.one : Side.two;

  /// 1 for an A win, 0 for a loss, ½ for a draw or an unfinished game.
  double get scoreA {
    final w = result?.winner;
    return w == null ? 0.5 : (w == _sideA ? 1 : 0);
  }

  /// A's net points: the result's points, negated for a loss.
  int get pointsA {
    final r = result, w = r?.winner;
    if (r == null || w == null) return 0;
    return w == _sideA ? r.points : -r.points;
  }
}

/// A 31-bit mix of [a] and [b], stable across runs and platforms.
int mixSeed(int a, int b) {
  var h = (a * 0x2545F491 + b * 0x9E3779B1 + 0x6A09E667) & 0x7FFFFFFF;
  h ^= h >> 15;
  h = (h * 0x2C1B3C6D) & 0x7FFFFFFF;
  h ^= h >> 12;
  return h;
}

/// Plays mirrored pair [pair] of a tournament with base [seed]: two
/// games of [variant] with the same dice sequence, A in seat one in the
/// first and in seat two in the second (B the other seat). The dice are
/// drawn per seat in turn order from `Random(mixSeed(seed, pair))`: the
/// opening roll (re-rolled on a tie), then each roll in turn. So each
/// bot gets in one game the rolls the other got in the other, as long as
/// the games stay in step. Cube off, single games.
List<GameOutcome> playPair({
  required Variant variant,
  required TournamentPlayer Function() a,
  required TournamentPlayer Function() b,
  required int seed,
  required int pair,
  int maxTurns = 2000,
}) {
  final diceSeed = mixSeed(seed, pair);
  return [
    for (final aIsOne in [true, false])
      playGame(
        variant: variant,
        one: aIsOne ? a() : b(),
        two: aIsOne ? b() : a(),
        diceSeed: diceSeed,
        maxTurns: maxTurns,
        outcome: (result, turns, one, two) => GameOutcome(
          pair: pair,
          aIsOne: aIsOne,
          result: result,
          turns: turns,
          tallyA: aIsOne ? one : two,
          tallyB: aIsOne ? two : one,
        ),
      ),
  ];
}

/// Plays one game of [variant], [one] in seat one and [two] in seat
/// two, with dice from `Random(diceSeed)`, and passes the result (null
/// at [maxTurns]), the turns played and the seats' tallies to
/// [outcome]. Throws [StateError] if a player submits an illegal play.
T playGame<T>({
  required Variant variant,
  required TournamentPlayer one,
  required TournamentPlayer two,
  required int diceSeed,
  required T Function(
          GameResult? result, int turns, PlayerTally one, PlayerTally two)
      outcome,
  int maxTurns = 2000,
}) {
  final dice = Random(diceSeed);
  int die() => 1 + dice.nextInt(6);
  final tally = {Side.one: PlayerTally(), Side.two: PlayerTally()};
  var s = GameState.initial(variant, cubeEnabled: false);
  var turns = 0;
  while (s.phase != GamePhase.gameOver && turns < maxTurns) {
    final GameAction action;
    switch (s.phase) {
      case GamePhase.opening:
        action = RollOpening(die(), die());
      case GamePhase.awaitingRoll:
        action = RollDice(die(), die());
      case GamePhase.moving:
        final side = s.sideToMove!;
        final player = side == Side.one ? one : two;
        final steps =
            player.choose(s, mixSeed(diceSeed, turns * 2 + side.index));
        final d = player.last;
        if (d != null && _hasChoice(s)) tally[side]!._record(d);
        action = SubmitPlay(steps);
        turns++;
      case GamePhase.cubeOffered || GamePhase.gameOver:
        throw StateError('unexpected phase ${s.phase} (cube is off)');
    }
    switch (reduce(s, action)) {
      case GameUpdate(:final state):
        s = state;
      case RuleViolation(:final code, :final message):
        throw StateError('$action rejected in ${s.variant.name}: '
            '${code.name}: $message');
    }
  }
  return outcome(s.result, turns, tally[Side.one]!, tally[Side.two]!);
}

/// Whether the moving phase of [s] offers a real choice (more than one
/// play). A cascade always counts.
bool _hasChoice(GameState s) {
  if (s.cascadeMode) return true;
  return s.tree.plays().length > 1;
}

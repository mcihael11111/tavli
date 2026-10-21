/// Pure step queries over a moving [GameState]: legal sources and
/// destinations, die disambiguation (design §4.3), quick moves and forced
/// plays. All pips are player-relative for the side to move.
library;

import 'package:tavli_bot/tavli_bot.dart' show StepQuality;
import 'package:tavli_core/tavli_core.dart';

import 'ui_selection.dart';

abstract final class StepPicker {
  /// The dice still to play: the moving phase's dice minus those the steps
  /// used (a cascade queue from the next entry on). Empty outside moving.
  static List<int> remainingDice(GameState g) {
    if (g.phase != GamePhase.moving) return const [];
    if (g.cascadeMode) return g.dice.sublist(g.steps.length);
    final left = [...g.dice];
    for (final s in g.steps) {
      left.remove(s.die);
    }
    return left;
  }

  /// The die [StepPicker.quickStep] tries first at the start of a play:
  /// the next cascade entry, else the larger die.
  static int? defaultActiveDie(GameState g) {
    final left = remainingDice(g);
    if (left.isEmpty) return null;
    if (g.cascadeMode) return left.first;
    return left.reduce((a, b) => a > b ? a : b);
  }

  /// Every pip a step can start from now.
  static Set<int> sources(GameState g) => g.phase == GamePhase.moving
      ? {for (final s in g.node.nextSteps) s.from}
      : const {};

  /// One highlight per legal destination of [from], in `nextSteps` order,
  /// each with the die [disambiguate] picks; [quality] from a teaching
  /// analysis of the current steps.
  static List<Highlight> highlights(GameState g, int from,
      {Map<Step, StepQuality>? quality}) {
    if (g.phase != GamePhase.moving) return const [];
    final node = g.node;
    final byTo = <int, List<Step>>{};
    for (final s in node.nextSteps) {
      if (s.from == from) (byTo[s.to] ??= []).add(s);
    }
    return [
      for (final steps in byTo.values)
        _highlight(g, disambiguate(node, steps)!, quality),
    ];
  }

  static Highlight _highlight(
          GameState g, Step s, Map<Step, StepQuality>? quality) =>
      Highlight(s, hit: isHit(g, s.to), quality: quality?[s]);

  /// The step to play when several [candidates] (same source and
  /// destination: bear-offs with different dice) continue [node]:
  /// 1. the die whose child node has the most continuations;
  /// 2. on a tie, the exact die (from - die == to);
  /// 3. otherwise the smaller die.
  /// Null when [candidates] is empty.
  static Step? disambiguate(PlayNode node, List<Step> candidates) {
    if (candidates.length <= 1) return candidates.firstOrNull;
    int continuations(Step s) => node.child(s)?.nextSteps.length ?? -1;
    final sorted = [...candidates]..sort((a, b) {
        final c = continuations(b).compareTo(continuations(a));
        if (c != 0) return c;
        final ea = a.from - a.die == a.to, eb = b.from - b.die == b.to;
        if (ea != eb) return ea ? -1 : 1;
        return a.die.compareTo(b.die);
      });
    return sorted.first;
  }

  /// The step [from] plays by [activeDie] if legal, else by the other dice
  /// still to play (in order); null if no die moves a checker from [from].
  static Step? quickStep(GameState g, int from, int? activeDie) {
    if (g.phase != GamePhase.moving || from < 1 || from > 25) return null;
    final node = g.node;
    final left = remainingDice(g);
    final order = <int>[
      if (activeDie != null && left.contains(activeDie)) activeDie,
      for (final d in left)
        if (d != activeDie) d,
    ];
    for (final d in order.toSet()) {
      final s = Step(from, from - d < 0 ? 0 : from - d, d);
      if (node.child(s) != null) return s;
    }
    return null;
  }

  /// Whether a step to [to] lands on a lone opposing checker.
  static bool isHit(GameState g, int to) {
    if (to < 1 || to > 24) return false;
    final me = g.sideToMove!, them = me.opponent, p = g.position;
    if (p.controller(me, to) != them) return false;
    return p.count(them, p.geometry.toOpponent(to)) == 1;
  }

  /// The steps of the only legal play when the play is forced and no step
  /// is taken yet, else null.
  static List<Step>? forcedSteps(GameState g) {
    if (g.phase != GamePhase.moving || g.steps.isNotEmpty) return null;
    final tree = g.tree;
    if (!tree.hasPlay || !tree.isForced) return null;
    if (!tree.isLazy) return tree.plays().single.steps;
    return tree.pathTo(tree.enumerateFinals(limit: 1).single);
  }
}

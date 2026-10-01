/// Play generation: every legal play of a roll as a [PlayTree] (design
/// spec §4.4).
library;

import 'dart:collection';

import '../board/position.dart';
import '../board/side.dart';
import '../rules/play_filters.dart';
import '../rules/step_rules.dart';
import '../rules/step_validators.dart';
import '../rules/turn_context.dart';
import '../variant/variant_rules.dart';
import 'step.dart';

part 'play_cascade.dart';
part 'play_search.dart';
part 'play_tree.dart';

/// Every legal play for [s] in [p] with [dice]: `[a, b]` (a != b) for a
/// normal roll, `[d, d, d, d]` for a double. Throws [ArgumentError] for
/// any other shape or a die outside 1..6.
///
/// [ctx] is the turn context before the first step; the dice are written
/// into it here (D18 needs them).
PlayTree generatePlays(
  Position p,
  Side s,
  List<int> dice,
  VariantRules rules,
  TurnContext ctx,
) {
  final d = List<int>.unmodifiable(dice);
  final ok = d.every((v) => v >= 1 && v <= 6) &&
      (d.length == 2 && d[0] != d[1] ||
          d.length == 4 && d.every((v) => v == d[0]));
  if (!ok) throw ArgumentError.value(dice, 'dice', 'not [a, b] or [d x4]');
  return _generate(p, s, d, rules, ctx.withDice(d));
}

/// Ordered cascade queue for double [d] (D15):
/// `[d, d, d, d, d+1 x4, ..., 6 x4]`. Throws [ArgumentError] outside 1..6.
List<int> cascadeQueue(int d) {
  if (d < 1 || d > 6) throw RangeError.range(d, 1, 6, 'd');
  return List.unmodifiable([
    for (var v = d; v <= 6; v++) ...[v, v, v, v],
  ]);
}

/// Every legal cascade play (Gul Bara, D15-D16) for [s] in [p]: [queue] is
/// played strictly in order, as far as possible (G4 over the queue).
///
/// The tree is lazy (design spec §4.4): `diceUsed` and `remainder` are
/// computed up front, nodes compute their next steps on first access, and
/// `finals` is not materialized (it throws; see [PlayTree.finals]).
///
/// The tree's `remainder` holds the queue entries no legal play reaches,
/// including unplayed copies of the number that failed; it is the same
/// for every legal play. [queue] must hold 1..24 dice in 1..6, e.g. a
/// [cascadeQueue] or a remainder. Throws [ArgumentError] for a bad queue,
/// or for [rules] with play filters (a lazy tree cannot apply them).
PlayTree generateCascade(
  Position p,
  Side s,
  List<int> queue,
  VariantRules rules,
  TurnContext ctx,
) {
  final q = List<int>.unmodifiable(queue);
  if (q.isEmpty || q.length > 24 || q.any((v) => v < 1 || v > 6)) {
    throw ArgumentError.value(queue, 'queue', 'not 1..24 dice in 1..6');
  }
  if (!PlayFilters(rules).isNoOp) {
    throw ArgumentError.value(rules, 'rules', 'cascades take no filters');
  }
  final cascade = _Cascade(rules, s, q);
  final root = cascade.start(p, ctx.withDice(q));
  final used = cascade.diceUsed;
  return PlayTree._(root, null, used, List.unmodifiable(q.sublist(used)));
}

PlayTree _generate(
  Position p,
  Side s,
  List<int> dice,
  VariantRules rules,
  TurnContext ctx,
) {
  final search = _Search(rules, s, dice);
  final root = search.run(p, ctx);
  final max = search.maxLength;
  if (max == 0) return PlayTree._(root, const {}, 0, const []);

  // G4: only plays using the most dice; with one die of a non-double, the
  // higher die if it has any (validator-approved) play.
  var plays = [
    for (final l in search.leaves)
      if (l.length == max) l,
  ];
  if (max == 1 && dice.length == 2) {
    final high = dice[0] > dice[1] ? 0 : 1;
    if (plays.any((l) => l.used == 1 << high)) {
      plays = [
        for (final l in plays)
          if (l.used == 1 << high) l,
      ];
    }
  }

  plays = PlayFilters(rules).apply(plays, s);

  final finals = <Position>{};
  for (final l in plays) {
    l.node._final = l.finalPosition;
    finals.add(l.finalPosition);
  }
  _prune(root, HashMap.identity());
  return PlayTree._(root, finals, max, const []);
}

/// Drops every edge to a subtree without a complete node; returns whether
/// [n] stays. [seen] memoizes shared nodes of the DAG.
bool _prune(PlayNode n, Map<PlayNode, bool> seen) {
  final known = seen[n];
  if (known != null) return known;
  var alive = n.isComplete;
  if (!alive) {
    n._children.removeWhere((_, c) => !_prune(c, seen));
    alive = n._children.isNotEmpty;
  }
  return seen[n] = alive;
}

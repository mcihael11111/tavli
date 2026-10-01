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
  return _generate(p, s, d, rules, ctx.withDice(d), ordered: false);
}

PlayTree _generate(
  Position p,
  Side s,
  List<int> dice,
  VariantRules rules,
  TurnContext ctx, {
  required bool ordered,
}) {
  final search = _Search(rules, s, dice, ordered: ordered);
  final root = search.run(p, ctx);
  final max = search.maxLength;
  final remainder =
      ordered ? List<int>.unmodifiable(dice.sublist(max)) : const <int>[];
  if (max == 0) return PlayTree._(root, const {}, 0, remainder);

  // G4: only plays using the most dice; with one die of a non-double, the
  // higher die if it has any (validator-approved) play.
  var plays = [
    for (final l in search.leaves)
      if (l.length == max) l,
  ];
  if (max == 1 && !ordered && dice.length == 2) {
    final high = dice[0] > dice[1] ? dice[0] : dice[1];
    if (plays.any((l) => l.firstDie == high)) {
      plays = [
        for (final l in plays)
          if (l.firstDie == high) l,
      ];
    }
  }

  plays = PlayFilters(rules).apply(plays, s);

  final finals = <Position>{};
  for (final l in plays) {
    l.node._final = l.finalPosition;
    finals.add(l.finalPosition);
  }
  _prune(root);
  return PlayTree._(root, finals, max, remainder);
}

/// Drops every subtree without a complete node; returns whether [n] stays.
bool _prune(PlayNode n) {
  if (n.isComplete) return true;
  n._children.removeWhere((_, c) => !_prune(c));
  return n._children.isNotEmpty;
}

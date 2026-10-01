/// Helpers for play-generation tests.
library;

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

/// The position after [steps] for [s] under [rules], each step asserted to
/// be basically legal on the way.
Position after(Position p, Side s, VariantRules rules, List<Step> steps) {
  final r = StepRules(rules);
  final m = p.toMutable();
  for (final step in steps) {
    expect(r.basicSteps(m, s, step.die), contains(step), reason: '$step');
    r.apply(m, s, step);
  }
  return m.freeze();
}

/// Every complete step sequence in [tree], in trie order.
List<List<Step>> sequencesOf(PlayTree tree) {
  final out = <List<Step>>[];
  void walk(PlayNode n, List<Step> prefix) {
    if (n.isComplete) out.add(List.of(prefix));
    for (final s in n.nextSteps) {
      walk(n.child(s)!, [...prefix, s]);
    }
  }

  walk(tree.root, []);
  return out;
}

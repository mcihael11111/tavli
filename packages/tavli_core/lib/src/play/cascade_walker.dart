part of 'play_generator.dart';

/// Complete plays of a lazy cascade tree without enumerating its finals,
/// which can run to millions (design spec SP2 §2).
///
/// Both methods walk [PlayNode.nextSteps] from the root to a complete
/// node, so each returned [Play] is a legal path by construction.
final class CascadeWalker {
  /// Throws [ArgumentError] unless [tree] is a lazy cascade tree.
  CascadeWalker(this.tree) {
    if (!tree.isLazy) {
      throw ArgumentError.value(tree, 'tree', 'not a lazy cascade tree');
    }
  }

  final PlayTree tree;

  /// Up to [n] plays with distinct finals, each from a random walk that
  /// picks uniformly among the next steps until the play is complete.
  ///
  /// Stops after [n] distinct finals or `4n` walks, so it can return fewer
  /// when the tree has few finals. [stop], when given, is checked before
  /// each walk (including the first); once it returns true the plays found
  /// so far are returned, so a deadline can cut a costly sample short (one
  /// walk on a bad cascade can expand thousands of states). Deterministic
  /// for a given [rng] state and stop sequence. Empty if `n <= 0` or the
  /// tree has no play.
  List<Play> sampleCompletions(int n, Random rng, {bool Function()? stop}) {
    final out = <Play>[];
    if (n <= 0 || !tree.hasPlay) return out;
    final found = <Position>{};
    for (var walk = 0; walk < 4 * n && out.length < n; walk++) {
      if (stop != null && stop()) break;
      var node = tree.root;
      final steps = <Step>[];
      while (!node.isComplete) {
        final next = node.nextSteps;
        final s = next.elementAt(rng.nextInt(next.length));
        steps.add(s);
        node = node.child(s)!;
      }
      final f = node.finalPosition!;
      if (found.add(f)) out.add(Play(f, List.unmodifiable(steps)));
    }
    return out;
  }

  /// The play built by taking, at each node, the next step whose child
  /// position has the highest [score] (the first such step on a tie).
  ///
  /// Takes no stop callback: it must return a complete play, and it is a
  /// single walk. Throws [StateError] if the tree has no play.
  Play greedyCompletion(double Function(BoardView p) score) {
    if (!tree.hasPlay) throw StateError('the cascade tree has no play');
    var node = tree.root;
    final steps = <Step>[];
    while (!node.isComplete) {
      Step? best;
      PlayNode? bestChild;
      var bestScore = double.negativeInfinity;
      for (final s in node.nextSteps) {
        final c = node.child(s)!;
        final v = score(c._position!);
        if (best == null || v > bestScore) {
          best = s;
          bestChild = c;
          bestScore = v;
        }
      }
      steps.add(best!);
      node = bestChild!;
    }
    return Play(node.finalPosition!, List.unmodifiable(steps));
  }
}

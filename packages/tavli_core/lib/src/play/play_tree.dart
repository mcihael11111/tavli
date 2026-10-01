part of 'play_generator.dart';

/// A node of the [PlayTree]: a prefix of one or more legal plays.
///
/// Every node lies on at least one legal play, so [nextSteps] is empty only
/// at a complete node. Prefixes reaching the same state (position, turn
/// context and dice used) share one node, so walk the tree by steps; do not
/// enumerate every path of a long cascade.
final class PlayNode {
  PlayNode._();

  // Insertion order follows the search, so iteration is deterministic.
  final Map<Step, PlayNode> _children = {};
  Position? _final;

  /// The steps that continue this prefix towards a legal play.
  Iterable<Step> get nextSteps => _children.keys;

  /// The node after [s], or null if [s] does not continue a legal play.
  PlayNode? child(Step s) => _children[s];

  /// Whether this prefix is a full legal play.
  bool get isComplete => _final != null;

  /// The position after the play; set iff [isComplete].
  Position? get finalPosition => _final;
}

/// Every legal play of one roll, as a prefix tree of step sequences
/// (design spec §4.4).
///
/// The tree holds every surviving sequence, in every step order that is
/// legal, so a play can be entered step by step in any valid order.
/// Equal states share nodes (a DAG), which keeps cascades tractable.
final class PlayTree {
  PlayTree._(this.root, Set<Position> finals, this.diceUsed, this.remainder)
      : finals = Set.unmodifiable(finals);

  final PlayNode root;

  /// The distinct legal final positions.
  final Set<Position> finals;

  /// The dice used by every legal play (G4). Bearing off the last checker
  /// ends the game, so such a play counts as using all its dice (G8).
  final int diceUsed;

  /// Cascade only (D16-B): the queue entries no legal play reaches, which
  /// the opponent plays next. Empty otherwise.
  final List<int> remainder;

  /// Whether there is a legal play of at least one step (G9 otherwise).
  bool get hasPlay => finals.isNotEmpty && diceUsed > 0;

  /// Whether exactly one final position is legal.
  bool get isForced => finals.length == 1;

  /// The node reached by [steps] from [root], or null if they leave the
  /// tree.
  PlayNode? walk(List<Step> steps) {
    PlayNode? n = root;
    for (final s in steps) {
      n = n!.child(s);
      if (n == null) return null;
    }
    return n;
  }
}

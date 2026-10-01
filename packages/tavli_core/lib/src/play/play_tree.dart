part of 'play_generator.dart';

/// A node of the [PlayTree]: a prefix of one or more legal plays.
///
/// Every node lies on at least one legal play, so [nextSteps] is empty only
/// at a complete node. Prefixes reaching the same state (position, turn
/// context and dice used) share one node, so walk the tree by steps; do not
/// enumerate every path of a long cascade.
final class PlayNode {
  PlayNode._();

  /// A cascade node whose children are computed on first access.
  PlayNode._lazy(_Cascade cascade, Position pos, TurnContext ctx, int index,
      {required bool complete})
      : _lazy = _LazyState(cascade, pos, ctx, index) {
    if (complete) _final = pos;
  }

  // Insertion order follows the search, so iteration is deterministic.
  final Map<Step, PlayNode> _children = {};
  Position? _final;

  /// Set until a lazy node is expanded.
  _LazyState? _lazy;

  /// The steps that continue this prefix towards a legal play.
  Iterable<Step> get nextSteps {
    _expand();
    return _children.keys;
  }

  /// The node after [s], or null if [s] does not continue a legal play.
  PlayNode? child(Step s) {
    _expand();
    return _children[s];
  }

  /// Whether this prefix is a full legal play.
  bool get isComplete => _final != null;

  /// The position after the play; set iff [isComplete].
  Position? get finalPosition => _final;

  void _expand() {
    final lazy = _lazy;
    if (lazy == null) return;
    _lazy = null;
    if (!isComplete) lazy.cascade.expand(this, lazy);
  }
}

/// What a lazy cascade node needs to compute its children.
final class _LazyState {
  _LazyState(this.cascade, this.position, this.ctx, this.index);

  final _Cascade cascade;
  final Position position;
  final TurnContext ctx;

  /// Steps taken so far = the queue index of the next die.
  final int index;
}

/// Every legal play of one roll, as a prefix tree of step sequences
/// (design spec §4.4).
///
/// The tree holds every surviving sequence, in every step order that is
/// legal, so a play can be entered step by step in any valid order.
/// Equal states share nodes (a DAG). Cascade trees are lazy: nodes are
/// built as they are walked, and [finals] is not materialized.
final class PlayTree {
  PlayTree._(this.root, Set<Position>? finals, this.diceUsed, this.remainder)
      : _finals = finals == null ? null : Set.unmodifiable(finals);

  final PlayNode root;
  final Set<Position>? _finals;
  bool? _forced;

  /// Whether this is a lazy cascade tree (no materialized [finals]).
  bool get isLazy => _finals == null;

  /// The distinct legal final positions.
  ///
  /// Throws [StateError] on a lazy cascade tree, where there can be
  /// millions; walk the tree or use [enumerateFinals] instead.
  Set<Position> get finals =>
      _finals ??
      (throw StateError('finals is not materialized for cascade trees'));

  /// The dice used by every legal play (G4). A play ending the game counts
  /// as using all its dice (matrix A4).
  final int diceUsed;

  /// Cascade only (D16-B): the queue entries no legal play reaches, which
  /// the opponent plays next. Empty otherwise.
  final List<int> remainder;

  /// Whether there is a legal play of at least one step (G9 otherwise).
  bool get hasPlay => diceUsed > 0;

  /// Whether exactly one final position is legal. On a lazy tree this
  /// walks the tree until a second final turns up.
  bool get isForced => _forced ??= _finalsUpTo(1).length == 1;

  /// The distinct legal finals, walking a lazy tree if needed. Throws
  /// [StateError] if there are more than [limit].
  Set<Position> enumerateFinals({int limit = 100000}) {
    final f = _finalsUpTo(limit);
    if (f.length > limit) throw StateError('more than $limit finals');
    return Set.unmodifiable(f);
  }

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

  /// Up to `limit + 1` distinct finals: the search stops once it has more
  /// than [limit].
  Set<Position> _finalsUpTo(int limit) {
    final eager = _finals;
    if (eager != null) return eager;
    final out = <Position>{};
    if (!hasPlay) return out;
    final seen = HashSet<PlayNode>.identity();
    bool visit(PlayNode n) {
      if (!seen.add(n)) return false;
      final f = n.finalPosition;
      if (f != null) {
        out.add(f);
        return out.length > limit;
      }
      for (final s in n.nextSteps) {
        if (visit(n.child(s)!)) return true;
      }
      return false;
    }

    visit(root);
    return out;
  }
}

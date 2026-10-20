part of 'play_generator.dart';

/// Lazy cascade generation (design spec §4.4, D15-D16).
///
/// The queue is played strictly in order, so G4 means "reach as far along
/// the queue as possible". [_maxFrom] is a memoized search for the most
/// queue entries playable from a state. Nodes then offer exactly the steps
/// whose continuation still reaches [diceUsed]. Sound only without play
/// filters (Gul Bara has none, D17).
///
/// With block contact, no pins and a non-decreasing queue (Gul Bara's
/// queues and remainders), [_maxFrom] also cuts with
/// the [_CascadeBound] upper bound (SP3 design §5.4 (a)): a state stops
/// once it reaches its bound, and a state whose bound cannot beat what
/// its caller already has is not searched. Without [pruned] it is the
/// plain search (the fuzz reference).
final class _Cascade {
  _Cascade(this._rules, this.side, this.queue, Position start,
      {bool pruned = true})
      : _steps = StepRules(_rules),
        _validators = StepValidators(_rules),
        _checksAfter = StepValidators(_rules).checksAfter,
        _bound = pruned &&
                _rules.contact == Contact.block &&
                _rules.pin == null &&
                _nonDecreasing(queue)
            ? _CascadeBound(start, side, queue)
            : null;

  static bool _nonDecreasing(List<int> q) {
    for (var i = 1; i < q.length; i++) {
      if (q[i] < q[i - 1]) return false;
    }
    return true;
  }

  final VariantRules _rules;
  final Side side;
  final List<int> queue;
  final StepRules _steps;
  final StepValidators _validators;
  final bool _checksAfter;
  final _CascadeBound? _bound;

  /// Most entries playable from (position, context, queue index): `v` when
  /// exact, `~v` when only known to be at most v (see [_maxFrom]).
  final _max = _Memo<int>();
  final _nodes = HashMap<_Key, PlayNode>();
  int diceUsed = 0;

  /// The root node; also sets [diceUsed].
  PlayNode start(Position p, TurnContext ctx) {
    diceUsed = _maxFrom(p.toMutable(), ctx, 0, -1);
    return _node(p, ctx, 0, ended: false);
  }

  /// Fills the children of [n]: the legal steps of the next die whose
  /// continuation still reaches [diceUsed].
  void expand(PlayNode n, _LazyState s) {
    final need = diceUsed - s.index;
    if (need <= 0) return;
    final m = n._position!.toMutable();
    final die = queue[s.index];
    for (final step in _steps.basicSteps(m, side, die)) {
      final a = _tryStep(m, step, s.ctx);
      if (a == null) continue;
      final ctx = _validators.next(s.ctx, a);
      final ended = _endsGame(m);
      if (ended || 1 + _maxFrom(m, ctx, s.index + 1, need - 2) >= need) {
        n._children[step] = _node(m.freeze(), ctx, s.index + 1, ended: ended);
      }
      _steps.undo(m, side, a);
    }
  }

  PlayNode _node(
    Position p,
    TurnContext ctx,
    int index, {
    required bool ended,
  }) =>
      _nodes[_Key(p, ctx, index)] ??= PlayNode._lazy(
        this,
        p,
        ctx,
        index,
        complete: index > 0 && (ended || index == diceUsed),
      );

  /// The most queue entries playable from the state of [m] at [index];
  /// a game-ending step counts the whole rest of the queue (matrix A4).
  /// [m] is restored before returning.
  ///
  /// Fail-soft below [floor]: the result is exact when the true maximum
  /// is above [floor]; otherwise it is an upper bound <= [floor] (callers
  /// only compare it with [floor] + 1). [floor] = -1 asks for the exact
  /// value. Proof sketch:
  /// - every child is asked with floor `max(floor, best) - 1`, so a child
  ///   that could raise the result above both is answered exactly, and an
  ///   inexact child adds at most `max(floor, best)`;
  /// - the bound `ub` is >= the true maximum, so `ub <= floor` answers at
  ///   once, and `best == ub` (only reachable by exact children, as
  ///   `ub > floor`) means best is the maximum;
  /// - otherwise every child is searched, so best >= the maximum and
  ///   equals it whenever it exceeds [floor].
  ///
  /// The memo keeps exact values and upper bounds, so the values compared
  /// by [start] and [expand] are the same as an unpruned search's.
  int _maxFrom(MutablePosition m, TurnContext ctx, int index, int floor) {
    final full = queue.length - index;
    if (full == 0) return 0;
    final known = _max.lookup(m, ctx, index);
    if (known != null && (known >= 0 || ~known <= floor)) {
      return known >= 0 ? known : ~known;
    }
    final bound = _bound;
    var ub = bound == null ? full : bound.of(m, index);
    if (known != null && ~known < ub) ub = ~known;
    if (ub <= floor) return ub;
    var best = 0;
    for (final step in _steps.basicSteps(m, side, queue[index])) {
      final a = _tryStep(m, step, ctx);
      if (a == null) continue;
      final int r;
      if (_endsGame(m)) {
        r = full;
      } else {
        final next = _validators.next(ctx, a);
        final f = bound == null ? -1 : (best > floor ? best : floor) - 1;
        r = 1 + _maxFrom(m, next, index + 1, f);
      }
      _steps.undo(m, side, a);
      if (r > best) best = r;
      if (best >= ub) break;
    }
    // Unpruned, every value is exact.
    final exact = bound == null || best > floor;
    _max.add(m, m.freeze(), ctx, index, exact ? best : ~best);
    return best;
  }

  /// Whether the step just applied to [m] ended the game (A4).
  bool _endsGame(MutablePosition m) => endsGame(m, _rules, side);

  /// Applies [step] to [m] if the validators allow it, else leaves [m]
  /// untouched and returns null. The caller must undo a returned step.
  AppliedStep? _tryStep(MutablePosition m, Step step, TurnContext ctx) {
    if (!_validators.allowsBefore(m, side, step, ctx)) return null;
    final a = _steps.apply(m, side, step);
    if (_checksAfter && !_validators.allowsAfter(m, side, a, ctx)) {
      _steps.undo(m, side, a);
      return null;
    }
    return a;
  }
}

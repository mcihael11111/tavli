part of 'play_generator.dart';

/// Lazy cascade generation (design spec §4.4, D15-D16).
///
/// The queue is played strictly in order, so G4 means "reach as far along
/// the queue as possible". [_maxFrom] is a memoized search for the most
/// queue entries playable from a state; it stops as soon as the rest of
/// the queue is reachable. Nodes then offer exactly the steps whose
/// continuation still reaches [diceUsed]. Sound only without play filters
/// (Gul Bara has none, D17).
final class _Cascade {
  _Cascade(VariantRules rules, this.side, this.queue)
      : _steps = StepRules(rules),
        _validators = StepValidators(rules),
        _checksAfter = StepValidators(rules).checksAfter;

  final Side side;
  final List<int> queue;
  final StepRules _steps;
  final StepValidators _validators;
  final bool _checksAfter;

  /// Most entries playable from (position, context, queue index).
  final _max = HashMap<_Key, int>();
  final _nodes = HashMap<_Key, PlayNode>();
  int diceUsed = 0;

  /// The root node; also sets [diceUsed].
  PlayNode start(Position p, TurnContext ctx) {
    diceUsed = _maxFrom(p.toMutable(), ctx, 0);
    return _node(p, ctx, 0, ended: false);
  }

  /// Fills the children of [n]: the legal steps of the next die whose
  /// continuation still reaches [diceUsed].
  void expand(PlayNode n, _LazyState s) {
    final need = diceUsed - s.index;
    if (need <= 0) return;
    final m = s.position.toMutable();
    final die = queue[s.index];
    for (final step in _steps.basicSteps(m, side, die)) {
      final a = _tryStep(m, step, s.ctx);
      if (a == null) continue;
      final ctx = _validators.next(s.ctx, a);
      final ended = _endsGame(m);
      if (ended || 1 + _maxFrom(m, ctx, s.index + 1) >= need) {
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
  int _maxFrom(MutablePosition m, TurnContext ctx, int index) {
    final full = queue.length - index;
    if (full == 0) return 0;
    final key = _Key(m.freeze(), ctx, index);
    final known = _max[key];
    if (known != null) return known;
    var best = 0;
    for (final step in _steps.basicSteps(m, side, queue[index])) {
      final a = _tryStep(m, step, ctx);
      if (a == null) continue;
      final r = _endsGame(m)
          ? full
          : 1 + _maxFrom(m, _validators.next(ctx, a), index + 1);
      _steps.undo(m, side, a);
      if (r > best) best = r;
      if (best == full) break;
    }
    return _max[key] = best;
  }

  /// Whether the step just applied to [m] ended the game.
  bool _endsGame(MutablePosition m) => m.checkersOnBoard(side) == 0;

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

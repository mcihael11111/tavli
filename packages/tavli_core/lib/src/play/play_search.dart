part of 'play_generator.dart';

/// One maximal step sequence end found by the search: its node plus what
/// the max-dice selection and the play filters read. Everything here is a
/// function of the node's state, so nodes can be shared between paths.
final class _Leaf implements PlayCandidate {
  _Leaf(this.node, this.length, this.used, this.finalPosition, this.waste);

  final PlayNode node;

  /// Dice used; a game-ending sequence counts all its dice (A4).
  final int length;

  /// Bit i set => `dice[i]` was stepped.
  final int used;

  @override
  final Position finalPosition;

  @override
  final int waste;
}

/// A search state: equal states have identical continuations.
final class _Key {
  _Key(this.position, this.ctx, this.used)
      : hashCode = Object.hash(position, ctx, used);

  final Position position;
  final TurnContext ctx;
  final int used;

  @override
  final int hashCode;

  @override
  bool operator ==(Object other) =>
      other is _Key &&
      other.used == used &&
      other.position == position &&
      other.ctx == ctx;
}

/// Eager depth-first make/unmake search over one [MutablePosition], for
/// normal rolls (cascades use the lazy [_Cascade]).
///
/// Per node: `basicSteps` -> `allowsBefore` -> `apply` -> `allowsAfter`
/// (only when the validators check after) -> recurse with
/// `StepValidators.next` -> `undo`.
///
/// From depth 2 on, states are memoized by (position, context, dice used),
/// so transpositions share one subtree and the trie is a DAG.
final class _Search {
  _Search(this._rules, this.side, this.dice)
      : _steps = StepRules(_rules),
        _validators = StepValidators(_rules),
        _checksAfter = StepValidators(_rules).checksAfter;

  final VariantRules _rules;
  final Side side;

  /// The dice; each distinct unused value is tried at every node.
  final List<int> dice;

  final StepRules _steps;
  final StepValidators _validators;
  final bool _checksAfter;
  late MutablePosition _p;
  late int _startPips;
  final _memo = HashMap<_Key, PlayNode>();

  /// Leaves recorded so far; those shorter than [maxLength] are stale.
  final leaves = <_Leaf>[];
  int maxLength = 0;

  PlayNode run(Position start, TurnContext ctx) {
    _p = start.toMutable();
    _startPips = start.pipCount(side);
    return _visit(ctx, 0, 0);
  }

  PlayNode _visit(TurnContext ctx, int used, int depth) {
    Position? frozen;
    _Key? key;
    if (depth >= 2) {
      key = _Key(frozen = _p.freeze(), ctx, used);
      final known = _memo[key];
      if (known != null) return known;
    }
    final node = PlayNode._();
    if (key != null) _memo[key] = node;

    // A4: a game-ending step ends the play; it counts as all the dice.
    if (depth > 0 && endsGame(_p, _rules, side)) {
      _leaf(node, dice.length, used, frozen);
      return node;
    }
    var tried = 0, any = false;
    for (var i = 0; i < dice.length; i++) {
      if ((used >> i) & 1 == 1) continue;
      final die = dice[i];
      if ((tried >> die) & 1 == 0) {
        tried |= 1 << die;
        for (final step in _steps.basicSteps(_p, side, die)) {
          final a = _tryStep(step, ctx);
          if (a == null) continue;
          any = true;
          node._children[step] =
              _visit(_validators.next(ctx, a), used | (1 << i), depth + 1);
          _steps.undo(_p, side, a);
        }
      }
    }
    if (!any) _leaf(node, depth, used, frozen);
    return node;
  }

  /// Applies [step] if the validators allow it, else leaves the position
  /// untouched and returns null. The caller must undo a returned step.
  AppliedStep? _tryStep(Step step, TurnContext ctx) {
    if (!_validators.allowsBefore(_p, side, step, ctx)) return null;
    final a = _steps.apply(_p, side, step);
    if (_checksAfter && !_validators.allowsAfter(_p, side, a, ctx)) {
      _steps.undo(_p, side, a);
      return null;
    }
    return a;
  }

  void _leaf(PlayNode node, int length, int used, Position? frozen) {
    if (length == 0 || length < maxLength) return;
    maxLength = length;
    final f = frozen ?? _p.freeze();
    // D5 waste from the state alone: every pip of every used die moves a
    // checker except the overshoot of bear-offs, so
    // waste = sum(used dice) - (pips before - pips after).
    var sum = 0;
    for (var i = 0; i < dice.length; i++) {
      if ((used >> i) & 1 == 1) sum += dice[i];
    }
    final waste = sum - (_startPips - f.pipCount(side));
    leaves.add(_Leaf(node, length, used, f, waste));
  }
}

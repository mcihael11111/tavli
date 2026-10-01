part of 'play_generator.dart';

/// One maximal step sequence found by the search: its trie leaf plus what
/// the max-dice selection and the play filters read.
final class _Leaf implements PlayCandidate {
  _Leaf(this.node, this.length, this.finalPosition, this.firstDie, this.waste);

  final PlayNode node;

  /// Dice used; a game-ending sequence counts all its dice (G8).
  final int length;

  @override
  final Position finalPosition;

  /// The die of the first step (G4 higher-die rule).
  final int firstDie;

  @override
  final int waste;
}

/// Depth-first make/unmake search over one [MutablePosition].
///
/// Per node: `basicSteps` -> `allowsBefore` -> `apply` -> `allowsAfter`
/// (only when the validators check after) -> recurse with
/// `StepValidators.next` -> `undo`. Every reached prefix becomes a
/// [PlayNode]; leaves of the current maximum length are frozen and kept.
final class _Search {
  _Search(VariantRules rules, this.side, this.dice, {required this.ordered})
      : _steps = StepRules(rules),
        _validators = StepValidators(rules),
        _checksAfter = StepValidators(rules).checksAfter;

  final Side side;

  /// The dice; [ordered] plays them strictly in list order (cascade),
  /// otherwise each distinct unused value is tried at every node.
  final List<int> dice;
  final bool ordered;

  final StepRules _steps;
  final StepValidators _validators;
  final bool _checksAfter;
  late MutablePosition _p;
  final _canonical = HashSet<Position>();

  /// Leaves recorded so far; those shorter than [maxLength] are stale.
  final leaves = <_Leaf>[];
  int maxLength = 0;

  PlayNode run(Position start, TurnContext ctx) {
    _p = start.toMutable();
    final root = PlayNode._();
    _visit(root, ctx, 0, 0, 0, 0);
    return root;
  }

  void _visit(
    PlayNode node,
    TurnContext ctx,
    int used,
    int depth,
    int firstDie,
    int waste,
  ) {
    // G8: the last checker borne off ends the game and the turn.
    if (depth > 0 && _p.checkersOnBoard(side) == 0) {
      _leaf(node, dice.length, firstDie, waste);
      return;
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
          final child = PlayNode._();
          node._children[step] = child;
          _visit(
            child,
            _validators.next(ctx, a),
            used | (1 << i),
            depth + 1,
            depth == 0 ? die : firstDie,
            waste + (a.bearOff ? die - step.from : 0),
          );
          _steps.undo(_p, side, a);
        }
      }
      if (ordered) break;
    }
    if (!any) _leaf(node, depth, firstDie, waste);
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

  void _leaf(PlayNode node, int length, int firstDie, int waste) {
    if (length == 0 || length < maxLength) return;
    maxLength = length;
    final frozen = _p.freeze();
    final f = _canonical.lookup(frozen) ?? frozen;
    if (identical(f, frozen)) _canonical.add(f);
    leaves.add(_Leaf(node, length, f, firstDie, waste));
  }
}

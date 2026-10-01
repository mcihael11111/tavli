import '../board/board_view.dart';
import '../board/side.dart';
import '../play/step.dart';
import '../variant/variant_rules.dart';
import 'turn_context.dart';

/// Turn-scoped step rules (plan Task 5): head (D18), sole runner
/// (advancement), six-block trap (D19) and Tavla hit-and-run (D4).
///
/// The generator checks [allowsBefore] on each basic step, applies it, then
/// checks [allowsAfter] and undoes the step when that returns false.
final class StepValidators {
  StepValidators(this.rules)
      : _head = rules.head,
        _releasePip = rules.advancement?.releasePip,
        _noHitAndRun = rules.hit?.noHitAndRunInHome ?? false,
        _noTrap = rules.primes.noPrimeTrappingAll;

  final VariantRules rules;
  final HeadRule? _head;
  final int? _releasePip;
  final bool _noHitAndRun;
  final bool _noTrap;

  /// Whether [allowsAfter] can ever return false, so callers may skip it.
  bool get checksAfter => _noTrap;

  /// Whether [step] is allowed for [s] given [ctx], before applying it.
  bool allowsBefore(BoardView p, Side s, Step step, TurnContext ctx) {
    final from = step.from;
    // D4: no checker may leave a home point where I hit this turn.
    if (_noHitAndRun && (ctx.homeHitMask >> from) & 1 == 1) return false;
    if (from != 24) return true;

    // D18: limit head departures per turn.
    final head = _head;
    if (head != null && ctx.headDepartures >= _headLimit(head, ctx)) {
      return false;
    }

    // Sole runner: until released, a full head lets any one checker go;
    // otherwise only the checker off the head may move.
    final release = _releasePip;
    if (release != null && p.count(s, 24) != 15 && !_released(p, s, release)) {
      return false;
    }
    return true;
  }

  /// Whether the position [p] after [a] is allowed for [s] (D19).
  bool allowsAfter(BoardView p, Side s, AppliedStep a, TurnContext ctx) =>
      !_noTrap || !_trapsAll(p, s);

  /// The context for the next step after [a]; counts a head departure only
  /// under a head rule.
  TurnContext next(TurnContext ctx, AppliedStep a) =>
      ctx.afterStep(a, fromHead: _head != null && a.step.from == 24);

  static int _headLimit(HeadRule head, TurnContext ctx) {
    final exception = ctx.firstTurn &&
        ctx.isDouble &&
        head.firstTurnDoubles.contains(ctx.diceOfTurn[0]);
    return exception ? head.maxOnException : head.maxPerTurn;
  }

  /// Released: some checker of [s] is on pips 0..[release] (0 = borne off).
  static bool _released(BoardView p, Side s, int release) {
    for (var pip = 0; pip <= release; pip++) {
      if (p.count(s, pip) > 0) return true;
    }
    return false;
  }

  /// D19: the points [s] holds (unpinned) cover six consecutive opponent
  /// pips k..k+5 with no opponent checker in front (borne off or on an
  /// opponent pip below k). Pips are the opponent's, since "front" runs
  /// along the opponent's path.
  static bool _trapsAll(BoardView p, Side s) {
    final g = p.geometry;
    final pinned = p.pinnedMask(s);
    var held = 0;
    for (var pip = 1; pip <= 24; pip++) {
      if (p.count(s, pip) > 0 && (pinned >> pip) & 1 == 0) {
        held |= 1 << g.toOpponent(pip);
      }
    }
    // The lowest window decides: an opponent checker in front of it is in
    // front of every higher window too.
    var k = 1;
    while (k <= 19 && (held >> k) & 0x3F != 0x3F) {
      k++;
    }
    if (k > 19) return false;
    final them = s.opponent;
    for (var q = 0; q < k; q++) {
      if (p.count(them, q) > 0) return false;
    }
    return true;
  }
}

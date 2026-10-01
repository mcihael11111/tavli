import '../board/board_view.dart';
import '../board/position.dart';
import '../board/side.dart';
import '../variant/variant_rules.dart';
import 'step_rules.dart';
import 'step_validators.dart';
import 'turn_context.dart';

/// A candidate play as the play filters see it.
abstract interface class PlayCandidate {
  /// The position after the play.
  Position get finalPosition;

  /// Pips wasted by bear-offs: the sum over bear-off steps of
  /// `die - from` (D5).
  int get waste;
}

/// Play-level rules that run after G4 (design spec §4.4 step 4), in order:
/// - D5 no-waste bear-off (Tavla);
/// - end-of-turn prime limits: D12-A (Fevga) and D14-B (Moultezim);
/// - D13-A leave the opponent a move (Fevga).
///
/// Each filter removes plays only while at least one play survives.
final class PlayFilters {
  PlayFilters(this.rules)
      : _noWaste = rules.hit?.bearOffNoWaste ?? false,
        _primes = rules.primes;

  final VariantRules rules;
  final bool _noWaste;
  final PrimeRules _primes;

  bool get _hasPrimeLimit =>
      _primes.noSixOwnStartQuarter ||
      _primes.noSixBeforeOccupiedOppHead ||
      _primes.maxPointsInOppStartQuarter != null;

  /// Whether no filter applies to these rules (so [apply] returns its
  /// input), as lazy cascade trees require.
  bool get isNoOp =>
      !_noWaste && !_hasPrimeLimit && !_primes.mustLeaveOpponentAMove;

  /// The plays of [s] in [plays] that survive every filter, in order.
  List<C> apply<C extends PlayCandidate>(List<C> plays, Side s) {
    var out = plays;
    if (_noWaste) out = _leastWaste(out, s);
    if (_hasPrimeLimit) {
      out = _keepIf(out, (f) => !_primeViolation(f, s));
    }
    if (_primes.mustLeaveOpponentAMove) {
      final cache = <Position, bool>{};
      out = _keepIf(
        out,
        (f) => cache[f] ??= _hasFirstStep(f, s.opponent),
      );
    }
    return out;
  }

  /// [plays] that pass [keep], or all of them if none does.
  static List<C> _keepIf<C extends PlayCandidate>(
    List<C> plays,
    bool Function(Position) keep,
  ) {
    final kept = [
      for (final c in plays)
        if (keep(c.finalPosition)) c,
    ];
    return kept.isEmpty ? plays : kept;
  }

  /// D5: the most checkers borne off, then the least waste. Never empties.
  static List<C> _leastWaste<C extends PlayCandidate>(List<C> plays, Side s) {
    var bestOff = -1, bestWaste = 0;
    for (final c in plays) {
      final off = c.finalPosition.borneOff(s);
      if (off > bestOff || off == bestOff && c.waste < bestWaste) {
        bestOff = off;
        bestWaste = c.waste;
      }
    }
    return [
      for (final c in plays)
        if (c.finalPosition.borneOff(s) == bestOff && c.waste == bestWaste) c,
    ];
  }

  /// D12-A (a)/(b) and D14-B on the final position.
  bool _primeViolation(BoardView f, Side s) {
    bool held(int pip) => f.count(s, pip) > 0;
    bool holdsAll(int lo, int hi) {
      for (var pip = lo; pip <= hi; pip++) {
        if (!held(pip)) return false;
      }
      return true;
    }

    // D12-A(a), D14-B: all of my 19..24.
    if (_primes.noSixOwnStartQuarter && holdsAll(19, 24)) return true;
    // D12-A(b): all of my 6..11 while the opponent's head (its 24) is
    // occupied.
    if (_primes.noSixBeforeOccupiedOppHead &&
        f.count(s.opponent, 24) > 0 &&
        holdsAll(6, 11)) {
      return true;
    }
    // D14-B: at most this many points of my 7..12.
    final max = _primes.maxPointsInOppStartQuarter;
    if (max != null) {
      var n = 0;
      for (var pip = 7; pip <= 12; pip++) {
        if (held(pip)) n++;
      }
      if (n > max) return true;
    }
    return false;
  }

  /// D13-A: whether [them] has a legal first step for some die 1..6 in [f],
  /// under its own validators and a fresh, not-first-turn context. A legal
  /// first step for die d means every roll containing d gives a play.
  bool _hasFirstStep(Position f, Side them) {
    final steps = StepRules(rules);
    final validators = StepValidators(rules);
    const ctx = TurnContext();
    MutablePosition? m;
    for (var die = 1; die <= 6; die++) {
      for (final step in steps.basicSteps(f, them, die)) {
        if (!validators.allowsBefore(f, them, step, ctx)) continue;
        if (!validators.checksAfter) return true;
        final p = m ??= f.toMutable();
        final a = steps.apply(p, them, step);
        final ok = validators.allowsAfter(p, them, a, ctx);
        steps.undo(p, them, a);
        if (ok) return true;
      }
    }
    return false;
  }
}

import '../board/board_view.dart';
import '../board/position.dart';
import '../board/side.dart';
import '../play/step.dart';
import '../variant/variant_rules.dart';

/// Single-step legality, apply and undo (plan Task 4).
///
/// [basicSteps] checks only per-step rules: G2 (open landing point), G5/G6
/// and D11 (bear-off), contact, pins and bar-first. Turn-scoped rules (head,
/// sole runner, six-block, hit-and-run) live in `StepValidators`.
final class StepRules {
  StepRules(this.rules)
      : _contact = rules.contact,
        _pinBlocksBearOff = rules.pin?.noBearOffWhilePinned ?? false;

  final VariantRules rules;
  final Contact _contact;
  final bool _pinBlocksBearOff;

  /// Every basically legal step of [s] with [die] (1..6), highest pip first.
  ///
  /// While [s] has checkers on the bar only entries (from 25) are returned.
  /// Pinned checkers never move.
  List<Step> basicSteps(BoardView p, Side s, int die) {
    assert(die >= 1 && die <= 6, 'die $die');
    if (p.onBar(s) > 0) {
      return _isOpen(p, s, 25 - die) ? [Step(25, 25 - die, die)] : const [];
    }
    final canBearOff = _canBearOff(p, s);
    final pinned = p.pinnedMask(s);
    List<Step>? out;
    for (var from = 24; from >= 1; from--) {
      if (p.count(s, from) == 0 || (pinned >> from) & 1 == 1) continue;
      final to = from - die;
      final ok = to >= 1
          ? _isOpen(p, s, to)
          : canBearOff && (to == 0 || _noneAbove(p, s, from));
      if (ok) (out ??= <Step>[]).add(Step(from, to < 0 ? 0 : to, die));
    }
    return out ?? const [];
  }

  /// Applies [step] for [s] to [p] and records its effects. Does no legality
  /// checking: [step] must come from [basicSteps] on this position.
  AppliedStep apply(MutablePosition p, Side s, Step step) {
    final from = step.from, to = step.to;
    final them = s.opponent;
    final g = p.geometry;
    p.move(s, from, to);

    var unpinned = false;
    if (from <= 24 && p.count(s, from) == 0) {
      final q = g.toOpponent(from);
      if (p.isPinned(them, q)) {
        p.setPinned(them, q, false);
        unpinned = true;
      }
    }

    var hit = false, pinned = false;
    if (to >= 1) {
      final q = g.toOpponent(to);
      if (p.count(them, q) == 1 && !p.isPinned(them, q)) {
        if (_contact == Contact.hit) {
          p.move(them, q, 25);
          hit = true;
        } else if (_contact == Contact.pin) {
          p.setPinned(them, q, true);
          pinned = true;
        }
      }
    }

    return AppliedStep(
      step,
      hit: hit,
      pinned: pinned,
      unpinned: unpinned,
      bearOff: to == 0,
    );
  }

  /// Exactly reverses [apply]: `undo(apply(x)) == x`, pinned bits included.
  void undo(MutablePosition p, Side s, AppliedStep a) {
    final from = a.step.from, to = a.step.to;
    final them = s.opponent;
    final g = p.geometry;
    if (a.hit) p.move(them, 25, g.toOpponent(to));
    if (a.pinned) p.setPinned(them, g.toOpponent(to), false);
    p.move(s, to, from);
    if (a.unpinned) p.setPinned(them, g.toOpponent(from), true);
  }

  /// Whether [s] may land on its own pip [to] (1..24), by contact rule:
  /// - hit: the opponent has at most one checker there;
  /// - pin: as hit, but never where my own checker is pinned (the opponent
  ///   controls that point);
  /// - block: the opponent has no checker there.
  bool _isOpen(BoardView p, Side s, int to) {
    final o = p.count(s.opponent, p.geometry.toOpponent(to));
    switch (_contact) {
      case Contact.hit:
        return o <= 1;
      case Contact.pin:
        return o == 0 || (o == 1 && !p.isPinned(s, to));
      case Contact.block:
        return o == 0;
    }
  }

  /// G5 (all 15 home) and D11 (no own pinned checker, pin games).
  bool _canBearOff(BoardView p, Side s) =>
      p.allHome(s) && !(_pinBlocksBearOff && p.pinnedMask(s) != 0);

  /// G6 overshoot: no own checker on pips `from+1..6`.
  static bool _noneAbove(BoardView p, Side s, int from) {
    for (var pip = from + 1; pip <= 6; pip++) {
      if (p.count(s, pip) > 0) return false;
    }
    return true;
  }
}

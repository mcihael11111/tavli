/// The reference play generator: a deliberately naive test oracle (design
/// spec §4.5) for differential tests against `generatePlays` and
/// `generateCascade`.
///
/// It shares only single-step legality with the fast generator
/// (`StepRules.basicSteps` / `apply`, `StepValidators`, `endsGame`) and
/// re-implements everything else by a different route:
/// - immutable positions: every step is applied to a fresh mutable copy;
/// - every distinct order (permutation) of the dice, with no memo;
/// - G4, A4, the higher-die rule and the play filters on explicit step
///   lists (D5 waste summed over bear-off steps, D13 over all 21 rolls).
///
/// It is slow by design; use it in tests only.
library;

import '../board/position.dart';
import '../board/side.dart';
import '../rules/game_end.dart';
import '../rules/step_rules.dart';
import '../rules/step_validators.dart';
import '../rules/turn_context.dart';
import '../variant/variant_rules.dart';
import 'step.dart';

/// The legal final positions for [s] in [p].
///
/// Normal rolls: [dice] is `[a, b]` (a != b) or `[d, d, d, d]`. With
/// [cascade], [dice] is a Gul Bara queue played strictly in order, as far
/// as possible (D15-D16). [ctx] is the context before the first step; the
/// dice are written into it here, as the fast generator does.
Set<Position> referenceFinals(
  Position p,
  Side s,
  List<int> dice,
  VariantRules rules,
  TurnContext ctx, {
  bool cascade = false,
}) {
  final o = _Oracle(rules, s);
  final c = ctx.withDice(dice);
  return cascade ? o.cascadeFinals(p, dice, c) : o.normalFinals(p, dice, c);
}

/// One maximal step sequence.
final class _Line {
  _Line(this.steps, this.end, {required this.ended});

  final List<Step> steps;
  final Position end;

  /// The last step ended the game (A4).
  final bool ended;
}

final class _Oracle {
  _Oracle(this.rules, this.side)
      : _rules = StepRules(rules),
        _validators = StepValidators(rules);

  final VariantRules rules;
  final Side side;
  final StepRules _rules;
  final StepValidators _validators;

  /// [step] for [who] on a fresh copy of [p], or null if a validator
  /// rejects it.
  (Position, AppliedStep)? _play(
    Position p,
    Side who,
    Step step,
    TurnContext ctx,
  ) {
    if (!_validators.allowsBefore(p, who, step, ctx)) return null;
    final m = p.toMutable();
    final a = _rules.apply(m, who, step);
    if (!_validators.allowsAfter(m, who, a, ctx)) return null;
    return (m.freeze(), a);
  }

  // ---- normal rolls ------------------------------------------------------

  Set<Position> normalFinals(Position p, List<int> dice, TurnContext ctx) {
    final lines = <_Line>[];
    for (final order in _orders(dice)) {
      _extend(p, order, ctx, const [], lines);
    }
    if (lines.isEmpty) return {};

    // G4 with A4: a game-ending line counts as all the dice.
    int length(_Line l) => l.ended ? dice.length : l.steps.length;
    var best = 0;
    for (final l in lines) {
      if (length(l) > best) best = length(l);
    }
    var plays = [
      for (final l in lines)
        if (length(l) == best) l,
    ];
    if (best == 1 && dice.length == 2 && dice[0] != dice[1]) {
      final high = dice[0] > dice[1] ? dice[0] : dice[1];
      final withHigh = [
        for (final l in plays)
          if (l.steps.single.die == high) l,
      ];
      if (withHigh.isNotEmpty) plays = withHigh;
    }

    if (rules.hit?.bearOffNoWaste ?? false) plays = _d5(plays);
    final primes = rules.primes;
    if (primes.noSixOwnStartQuarter ||
        primes.noSixBeforeOccupiedOppHead ||
        primes.maxPointsInOppStartQuarter != null) {
      plays = _unlessAll(plays, (l) => !_breaksPrimeLimit(l.end));
    }
    if (primes.mustLeaveOpponentAMove) {
      final memo = <Position, bool>{};
      plays = _unlessAll(
        plays,
        (l) => memo[l.end] ??= _opponentCanMove(l.end),
      );
    }
    return {for (final l in plays) l.end};
  }

  /// Plays [order] from [pos] as far as it goes, adding every line that
  /// stops (no next step, all dice played, or the game ended) to [out].
  void _extend(
    Position pos,
    List<int> order,
    TurnContext ctx,
    List<Step> steps,
    List<_Line> out,
  ) {
    if (steps.length == order.length) {
      out.add(_Line(steps, pos, ended: false));
      return;
    }
    var any = false;
    for (final step in _rules.basicSteps(pos, side, order[steps.length])) {
      final r = _play(pos, side, step, ctx);
      if (r == null) continue;
      any = true;
      final (next, applied) = r;
      final longer = [...steps, step];
      if (endsGame(next, rules, side)) {
        out.add(_Line(longer, next, ended: true));
      } else {
        _extend(next, order, _validators.next(ctx, applied), longer, out);
      }
    }
    if (!any && steps.isNotEmpty) out.add(_Line(steps, pos, ended: false));
  }

  /// D5: the most checkers borne off, then the least waste, where waste is
  /// the sum of `die - from` over bear-off steps.
  List<_Line> _d5(List<_Line> plays) {
    int waste(_Line l) {
      var w = 0;
      for (final st in l.steps) {
        if (st.to == 0) w += st.die - st.from;
      }
      return w;
    }

    final mostOff = plays.map((l) => l.end.borneOff(side)).reduce(_max);
    final most = [
      for (final l in plays)
        if (l.end.borneOff(side) == mostOff) l,
    ];
    final least = most.map(waste).reduce(_min);
    return [
      for (final l in most)
        if (waste(l) == least) l,
    ];
  }

  /// D12-A (a)+(b) and D14-B as one check (A5).
  bool _breaksPrimeLimit(Position f) {
    final primes = rules.primes;
    final held = [for (var pip = 0; pip <= 24; pip++) f.count(side, pip) > 0];
    bool all(int lo, int hi) =>
        [for (var pip = lo; pip <= hi; pip++) held[pip]].every((h) => h);
    if (primes.noSixOwnStartQuarter && all(19, 24)) return true;
    if (primes.noSixBeforeOccupiedOppHead &&
        f.count(side.opponent, 24) > 0 &&
        all(6, 11)) {
      return true;
    }
    final cap = primes.maxPointsInOppStartQuarter;
    if (cap != null) {
      final points = [for (var pip = 7; pip <= 12; pip++) held[pip]];
      if (points.where((h) => h).length > cap) return true;
    }
    return false;
  }

  /// D13-A: whether the opponent has a play of at least one step for at
  /// least one of the 21 rolls, from a fresh not-first-turn context.
  bool _opponentCanMove(Position f) {
    final them = side.opponent;
    for (var a = 1; a <= 6; a++) {
      for (var b = a; b <= 6; b++) {
        final roll = a == b ? [a, a, a, a] : [a, b];
        final ctx = TurnContext().withDice(roll);
        for (final die in roll.toSet()) {
          for (final step in _rules.basicSteps(f, them, die)) {
            if (_play(f, them, step, ctx) != null) return true;
          }
        }
      }
    }
    return false;
  }

  // ---- cascades ----------------------------------------------------------

  /// Breadth-first along [queue]: each level is every distinct (position,
  /// context) after that many steps. A game-ending step counts as the
  /// whole queue (A4).
  Set<Position> cascadeFinals(Position p, List<int> queue, TurnContext ctx) {
    var level = <(Position, TurnContext)>{(p, ctx)};
    final ended = <Position>{};
    var depth = 0;
    while (depth < queue.length) {
      final next = <(Position, TurnContext)>{};
      for (final (pos, c) in level) {
        for (final step in _rules.basicSteps(pos, side, queue[depth])) {
          final r = _play(pos, side, step, c);
          if (r == null) continue;
          final (after, applied) = r;
          if (endsGame(after, rules, side)) {
            ended.add(after);
          } else {
            next.add((after, _validators.next(c, applied)));
          }
        }
      }
      if (next.isEmpty) break;
      level = next;
      depth++;
    }
    final reachedEnd = depth == queue.length;
    return {
      ...ended,
      if (depth > 0 && (ended.isEmpty || reachedEnd))
        for (final (pos, _) in level) pos,
    };
  }
}

/// Every distinct ordering of the multiset [dice].
List<List<int>> _orders(List<int> dice) {
  if (dice.length <= 1) return [List.of(dice)];
  final out = <List<int>>[];
  final firsts = <int>{};
  for (var i = 0; i < dice.length; i++) {
    if (!firsts.add(dice[i])) continue;
    final rest = [...dice.sublist(0, i), ...dice.sublist(i + 1)];
    for (final tail in _orders(rest)) {
      out.add([dice[i], ...tail]);
    }
  }
  return out;
}

int _max(int a, int b) => a > b ? a : b;
int _min(int a, int b) => a < b ? a : b;

/// [plays] that pass [keep], or all of them if none does.
List<_Line> _unlessAll(List<_Line> plays, bool Function(_Line) keep) {
  final kept = plays.where(keep).toList();
  return kept.isEmpty ? plays : kept;
}

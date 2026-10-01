/// State invariants for fuzz tests (plan Task 16), written as plain
/// checks rather than `expect` so they stay cheap in hot loops.
library;

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

void _check(bool ok, String Function() what) {
  if (!ok) fail(what());
}

/// Board invariants of [p] under [rules]:
/// - 15 checkers per side, counting board + bar + off;
/// - no physical point holds both sides unless it is a pinned pair;
/// - pinned bits only where the owner has exactly 1 checker and the
///   opponent at least 1 on the same physical point (pin variants only);
/// - checkers on the bar only in hitting variants;
/// - pip counts are non-negative and match the checker counts.
void checkBoard(Position p, VariantRules rules) {
  final g = p.geometry;
  for (final s in Side.values) {
    var total = 0, pips = 0;
    for (var pip = 0; pip <= 25; pip++) {
      final n = p.count(s, pip);
      _check(n >= 0, () => '${s.name}:$pip negative in $p');
      total += n;
      pips += pip * n;
    }
    _check(total == 15, () => '${s.name} has $total checkers in $p');
    _check(p.pipCount(s) == pips && pips >= 0,
        () => '${s.name} pipCount ${p.pipCount(s)} != $pips in $p');
    _check(rules.contact == Contact.hit || p.onBar(s) == 0,
        () => '${s.name} on the bar in a ${rules.contact.name} game: $p');
  }
  for (var pip = 1; pip <= 24; pip++) {
    final q = g.toOpponent(pip);
    final one = p.count(Side.one, pip), two = p.count(Side.two, q);
    final pinOne = p.isPinned(Side.one, pip), pinTwo = p.isPinned(Side.two, q);
    _check(!pinOne || !pinTwo, () => 'one:$pip/two:$q pinned both ways: $p');
    _check(rules.contact == Contact.pin || !pinOne && !pinTwo,
        () => 'pinned bit in a ${rules.contact.name} game: $p');
    if (pinOne) {
      _check(one == 1 && two >= 1, () => 'bad pin on one:$pip in $p');
    } else if (pinTwo) {
      _check(two == 1 && one >= 1, () => 'bad pin on two:$q in $p');
    } else {
      _check(one == 0 || two == 0, () => 'one:$pip/two:$q shared in $p');
    }
  }
}

/// Phase invariants of [s], plus [checkBoard] on its board.
void checkState(GameState s) {
  final rules = s.variant.rules;
  checkBoard(s.position, rules);
  String at() => '$s';
  _check(s.cube.value >= 1 && s.cube.value <= 64, () => 'cube ${at()}');
  _check(!s.remainderTurn || s.cascadeMode, () => 'remainder ${at()}');
  switch (s.phase) {
    case GamePhase.opening:
      _check(s.sideToMove == null && s.dice.isEmpty, () => 'opening ${at()}');
    case GamePhase.awaitingRoll || GamePhase.cubeOffered:
      _check(
        s.sideToMove != null &&
            s.dice.isEmpty &&
            s.steps.isEmpty &&
            s.position == s.turnStart &&
            s.cube.offeredBy ==
                (s.phase == GamePhase.cubeOffered ? s.sideToMove : null),
        () => 'between turns ${at()}',
      );
    case GamePhase.moving:
      final side = s.sideToMove;
      _check(side != null && s.dice.isNotEmpty && s.tree.hasPlay,
          () => 'moving ${at()}');
      _check(s.tree.walk(s.steps) != null, () => 'steps off the tree ${at()}');
      // The board is the turn start with the steps applied.
      final m = s.turnStart.toMutable();
      final stepRules = StepRules(rules);
      for (final st in s.steps) {
        stepRules.apply(m, side!, st);
      }
      _check(m.freeze() == s.position, () => 'board != steps ${at()}');
    case GamePhase.gameOver:
      final r = s.result;
      _check(
        r != null &&
            (r.winner == null ? r.kind == ResultKind.draw : r.points > 0) &&
            r.cubeValue == s.cube.value &&
            s.cube.offeredBy == null,
        () => 'result ${at()}',
      );
  }
}

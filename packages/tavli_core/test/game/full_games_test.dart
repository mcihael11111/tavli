import 'dart:math';

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/random_play.dart';
import '../support/reducer.dart';
import '../support/results.dart';

/// Games per variant played to their natural end.
const _gamesPerVariant = 12;

/// Plays one game of [v] with random legal actions only (no resign, no
/// drop) until it ends; returns the final state and how many remainders
/// were handed over.
(GameState, int) _playOut(Variant v, Random r) {
  var s = GameState.initial(v, cubeEnabled: true);
  var remainders = 0;
  for (var i = 0; i < 3000; i++) {
    final a = randomLegalAction(s, r);
    if (a == null) return (s, remainders);
    final res = reduce(s, a);
    if (res is GameUpdate) {
      remainders += res.events.whereType<RemainderPassed>().length;
      s = res.state;
    } else if (a is! OfferDouble) {
      fail('${v.name}: $a rejected: $res');
    }
  }
  fail('${v.name}: no natural end within 3000 actions');
}

void main() {
  test('random legal games run to their natural end with valid results', () {
    final r = Random(7);
    final kinds = <ResultKind, int>{};
    var remainders = 0;
    for (final v in Variant.values) {
      for (var g = 0; g < _gamesPerVariant; g++) {
        final (s, rem) = _playOut(v, r);
        remainders += rem;
        checkNaturalResult(s);
        kinds.update(s.result!.kind, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    printOnFailure('kinds $kinds, remainders $remainders');
    for (final k in [
      ResultKind.single,
      ResultKind.gammon,
      ResultKind.triple,
      ResultKind.mother,
      ResultKind.draw,
      ResultKind.checkersRemaining,
    ]) {
      expect(kinds[k] ?? 0, greaterThan(0), reason: '${k.name}: $kinds');
    }
    expect(remainders, greaterThan(0), reason: 'Gul Bara remainders');
  });

  test('playAny stops at a game-ending step', () {
    // One checker left: bearing it off ends the game; no commit follows.
    final s = GameState.initial(Variant.portes, starter: Side.one).withPosition(
        Position.fromPips(
            one: const {1: 1},
            two: const {6: 15},
            direction: Direction.opposing));
    final end = playAny(ok(s, const RollDice(3, 1)).state);
    expect(end.phase, GamePhase.gameOver);
  });
}

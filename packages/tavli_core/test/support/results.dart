/// Checks that a finished game's result agrees with its final board.
library;

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

/// The result of a game that ended naturally (no resign, timeout or
/// drop) agrees with the final position (G8, D6, D8-D10, D21).
void checkNaturalResult(GameState s) {
  final r = s.result!, p = s.position, rules = s.variant.rules;
  final cube = s.cube.value;
  expect(r.cubeValue, cube);
  final winner = r.winner;
  if (winner == null) {
    expect(r.kind, ResultKind.draw);
    expect(p.isPinned(Side.one, 24) && p.isPinned(Side.two, 24), isTrue);
    expect(r.points, rules.pin!.bothPinnedPoints);
    return;
  }
  final loser = winner.opponent;
  switch (r.kind) {
    case ResultKind.mother:
      expect(p.isPinned(loser, 24), isTrue);
      expect(p.count(winner, 24), 0);
      expect(r.points, rules.pin!.motherPoints);
    case ResultKind.checkersRemaining:
      expect(p.borneOff(winner), 15);
      expect(r.points, p.checkersOnBoard(loser));
    case ResultKind.single:
      expect(p.borneOff(winner), 15);
      expect(p.borneOff(loser), greaterThanOrEqualTo(1));
      expect(r.points, cube);
    case ResultKind.gammon:
      expect(p.borneOff(winner), 15);
      expect(p.borneOff(loser), 0);
      expect(r.points, 2 * cube);
    case ResultKind.triple:
      expect(p.borneOff(winner), 15);
      expect(p.borneOff(loser), 0);
      expect(r.points, rules.scoring.triple! * cube);
    case ResultKind.draw || ResultKind.resign || ResultKind.timeout:
      fail('unexpected natural result $r');
  }
}

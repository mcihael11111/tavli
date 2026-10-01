/// Random legal play for fuzz-style tests.
library;

import 'dart:math';

import 'package:tavli_core/tavli_core.dart';

/// A random action that `reduce` accepts in [s] (except an [OfferDouble],
/// which may be refused): opening and normal rolls, a random next step,
/// commit when complete, take every offer. Never resigns or drops, so a
/// game runs to its natural end. Null once the game is over.
GameAction? randomLegalAction(GameState s, Random r) {
  int die() => 1 + r.nextInt(6);
  switch (s.phase) {
    case GamePhase.opening:
      return RollOpening(die(), die());
    case GamePhase.awaitingRoll:
      return s.cube.enabled && r.nextInt(20) == 0
          ? const OfferDouble()
          : RollDice(die(), die());
    case GamePhase.cubeOffered:
      return const Take();
    case GamePhase.moving:
      final n = s.node;
      if (n.isComplete) return const CommitPlay();
      final next = n.nextSteps.toList();
      return StepAction(next[r.nextInt(next.length)]);
    case GamePhase.gameOver:
      return null;
  }
}

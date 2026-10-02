/// Small Gul Bara cascade cases (side one to move), shared by the lazy
/// tree tests.
library;

import 'package:tavli_core/tavli_core.dart';

import 'positions.dart';

/// Name -> (position, queue). Each tree has at most a few dozen finals.
final smallCascades = <String, (Position, List<int>)>{
  // Stuck checker on 24 (my 21, 20, 19 closed), 2 movers on 13; the queue
  // runs out of room in the 5s.
  'fails mid-queue': (
    posSame(
      one: {24: 1, 13: 2, 1: 12},
      two: {24: 12, 9: 1, 8: 1, 7: 1},
    ),
    cascadeQueue(4),
  ),
  // From random play: failing cascades with several finals.
  'random A (11 of 16, 8 finals)': (
    posSame(
      one: {24: 3, 21: 1, 19: 1, 12: 1, 11: 2, 4: 2, 2: 3, 1: 2},
      two: {19: 4, 18: 2, 11: 1, 5: 1, 4: 1, 3: 1, 2: 1, 1: 4},
    ),
    cascadeQueue(3),
  ),
  'random B (7 of 8, 9 finals)': (
    posSame(
      one: {23: 1, 21: 1, 17: 1, 16: 2, 4: 5, 1: 5},
      two: {22: 1, 17: 4, 15: 2, 10: 1, 3: 3, 2: 2, 1: 2},
    ),
    cascadeQueue(5),
  ),
  // Bear-off: some lines end the game early (A4).
  'game-ending lines': (
    posSame(one: {6: 2, 4: 1, 3: 1}, two: {24: 15}),
    cascadeQueue(2),
  ),
  'full queue': (
    posSame(one: {24: 2, 18: 1, 1: 12}, two: {24: 15}),
    cascadeQueue(5),
  ),
};

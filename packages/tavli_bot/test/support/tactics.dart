/// The labelled tactics suite (plan Task 5 test 4): hand-built positions
/// with the expected play and a one-line rationale, four or more per
/// family. Side one is to move; maps are own pips (see positions.dart).
library;

import 'package:tavli_core/tavli_core.dart';

import 'positions.dart';

/// One labelled position. [expected] says whether a chosen final is the
/// tactic: either the final of [steps] (an exact play) or a named
/// property for tactics any of several plays satisfy.
final class Tactic {
  Tactic(this.name, this.variant, this.position, this.dice, this.why,
      {List<Step>? steps, bool Function(Position)? property})
      : assert((steps == null) != (property == null)),
        _steps = steps,
        _property = property;

  final String name;
  final Variant variant;
  final Position position;
  final List<int> dice;
  final String why;
  final List<Step>? _steps;
  final bool Function(Position)? _property;

  /// The expected final, for an exact play.
  Position? get expectedFinal {
    final s = _steps;
    if (s == null) return null;
    return generatePlays(position, Side.one, dice, variant.rules, TurnContext())
        .walk(s)!
        .finalPosition;
  }

  bool expected(Position f) => _property?.call(f) ?? f == expectedFinal;

  @override
  String toString() => name;
}

const _one = Side.one, _two = Side.two;

/// Opponent: two back on my 1-point, five home points and three on its
/// 13 (my 12): every blot I leave in front of the anchor is a shot.
const _anchorAndBoard = {24: 2, 13: 3, 6: 2, 5: 2, 4: 2, 3: 2, 2: 2};

/// Hitting family (Portes).
final hittingTactics = [
  Tactic(
      'make the 5-point with 3-1',
      Variant.portes,
      Position.forRules(Variant.portes.rules),
      [3, 1],
      'the opening 3-1: 8/5 6/5 makes the best point',
      steps: const [Step(8, 5, 3), Step(6, 5, 1)]),
  Tactic(
      'hit and cover',
      Variant.portes,
      posOpp({8: 3, 7: 2, 6: 4, 4: 3, 3: 3},
          {6: 4, 5: 4, 4: 3, 3: 2, 20: 1, 1: 1}),
      [3, 1],
      'their straggler sits on my 5-point: 8/5* 6/5 hits it and makes '
          'the point, sending it back in a race I trail',
      steps: const [Step(8, 5, 3), Step(6, 5, 1)]),
  Tactic(
      'point on the blot',
      Variant.portes,
      posOpp(
          {24: 2, 13: 4, 10: 1, 8: 3, 6: 5}, {24: 1, 21: 1, 13: 5, 8: 3, 6: 5}),
      [6, 4],
      '10/4* 8/4 hits their blot on my 4-point and covers it: no return '
          'shot',
      steps: const [Step(10, 4, 6), Step(8, 4, 4)]),
  Tactic(
      'safe bear-off',
      Variant.portes,
      posOpp({6: 2, 5: 3, 4: 2, 3: 2, 2: 2},
          {24: 2, 8: 2, 6: 3, 5: 2, 4: 2, 3: 2, 2: 2}),
      [6, 1],
      '6/off 6/5 clears the 6-point; any other 1 leaves a blot in front '
          'of their anchor and five-point board',
      steps: const [Step(6, 0, 6), Step(6, 5, 1)]),
  Tactic(
      'clear from the back (3-2)',
      Variant.portes,
      posOpp({9: 2, 8: 2, 7: 2, 6: 2, 3: 2, 2: 3}, _anchorAndBoard),
      [3, 2],
      '9/6 9/7 clears the rearmost point safely; making the 5-point '
          '(8/5 7/5) leaves two blots in direct range of the anchor',
      steps: const [Step(9, 6, 3), Step(9, 7, 2)]),
  Tactic(
      'clear from the back (5-3)',
      Variant.portes,
      posOpp({10: 2, 7: 2, 6: 2, 5: 3, 4: 2, 3: 2}, _anchorAndBoard),
      [5, 3],
      '10/5 10/7 clears the rearmost point safely; making the 2-point '
          '(7/2 5/2) leaves a blot on 7 in direct range',
      steps: const [Step(10, 5, 5), Step(10, 7, 3)]),
];

/// Pinning family (Plakoto).
final pinningTactics = [
  Tactic(
      'pin in my home',
      Variant.plakoto,
      posOpp({24: 4, 13: 5, 8: 3, 7: 3}, {24: 8, 21: 1, 15: 2, 14: 2, 11: 2}),
      [4, 2],
      'their blot on my 4-point can be pinned with 8/4: pin it',
      property: (f) => f.isPinned(_two, 21)),
  Tactic(
      'keep the mother covered',
      Variant.plakoto,
      posOpp({24: 2, 10: 1, 1: 12}, {13: 6, 7: 3, 6: 3, 4: 3}),
      [4, 1],
      'their home checkers reach my 24 with every roll: leaving one '
          'checker there loses to a mother pin, so play 10/5',
      steps: const [Step(10, 6, 4), Step(6, 5, 1)]),
  Tactic(
      'pin the mother to win',
      Variant.plakoto,
      posOpp({8: 3, 6: 4, 5: 4, 4: 4}, {24: 1, 13: 4, 7: 5, 6: 5}),
      [2, 1],
      'their mother is alone on my 1-point and I have left my start: '
          '4/2/1 pins it and wins at once',
      steps: const [Step(4, 2, 2), Step(2, 1, 1)]),
  Tactic(
      'pin the mother',
      Variant.plakoto,
      posOpp({24: 2, 13: 5, 8: 3, 6: 3, 4: 2}, {24: 1, 18: 5, 16: 4, 15: 5}),
      [3, 2],
      'their mother is alone on my 1-point: pinning it (4/1 or 6/3/1) '
          'is worth far more than any point',
      property: (f) => f.isPinned(_two, 24)),
];

/// Running family (Fevga, Long Nard, Moultezim).
final runningTactics = [
  Tactic(
      'extend the blockade (Fevga)',
      Variant.fevga,
      posSame({24: 9, 10: 2, 7: 1, 6: 1, 5: 1, 4: 1}, {24: 14, 20: 1}),
      [6, 1],
      'their runner (on my 8) faces my 7..4: 10/3 makes it a five-point '
          'blockade',
      steps: const [Step(10, 4, 6), Step(4, 3, 1)]),
  Tactic(
      'extend the blockade (Moultezim)',
      Variant.moultezim,
      posSame({24: 9, 10: 2, 7: 1, 6: 1, 5: 1, 4: 1}, {24: 14, 20: 1}),
      [6, 1],
      'the same five-point blockade under Moultezim rules',
      steps: const [Step(10, 4, 6), Step(4, 3, 1)]),
  Tactic(
      'leave the head (Long Nard)',
      Variant.longNard,
      posSame({24: 12, 18: 1, 15: 1, 13: 1}, {24: 13, 20: 1, 17: 1}),
      [5, 3],
      'only one checker may leave the head per turn: use this turn to '
          'take one',
      property: (f) => f.count(_one, 24) == 11),
  Tactic(
      'escape the last checker (Fevga)',
      Variant.fevga,
      posSame(
          {20: 1, 10: 5, 9: 4, 8: 3, 7: 2}, {7: 2, 6: 2, 5: 2, 4: 2, 24: 7}),
      [6, 2],
      'my last checker (on 20) faces their four-point block on my '
          '19..16: 20/14 jumps it',
      property: (f) => f.count(_one, 20) == 0),
];

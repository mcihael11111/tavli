/// Test builders for positions in player-relative pips (plan "Test notation").
library;

import 'dart:math';

import 'package:tavli_core/tavli_core.dart';

/// Builds an opposing-direction [Position]; omitted checkers are borne off.
///
/// [offOne] / [offTwo], when given, must match the derived borne-off count.
Position pos({
  required Map<int, int> one,
  required Map<int, int> two,
  int? offOne,
  int? offTwo,
  int barOne = 0,
  int barTwo = 0,
  Set<int> pinnedOne = const {},
  Set<int> pinnedTwo = const {},
  Direction direction = Direction.opposing,
}) {
  final p = Position.fromPips(
    one: one,
    two: two,
    barOne: barOne,
    barTwo: barTwo,
    pinnedOne: pinnedOne,
    pinnedTwo: pinnedTwo,
    direction: direction,
  );
  if (offOne != null && p.borneOff(Side.one) != offOne) {
    throw ArgumentError.value(
        offOne, 'offOne', 'derived ${p.borneOff(Side.one)}');
  }
  if (offTwo != null && p.borneOff(Side.two) != offTwo) {
    throw ArgumentError.value(
        offTwo, 'offTwo', 'derived ${p.borneOff(Side.two)}');
  }
  return p;
}

/// As [pos], with [Direction.same] (running games).
Position posSame({
  required Map<int, int> one,
  required Map<int, int> two,
  int? offOne,
  int? offTwo,
  Set<int> pinnedOne = const {},
  Set<int> pinnedTwo = const {},
}) =>
    pos(
      one: one,
      two: two,
      offOne: offOne,
      offTwo: offTwo,
      pinnedOne: pinnedOne,
      pinnedTwo: pinnedTwo,
      direction: Direction.same,
    );

/// [n] positions sampled from random legal games of [v]: each turn plays
/// a random legal play of a random roll (cascades for Gul Bara doubles
/// after its normal rolls; a remainder is dropped), sampling every 2..7
/// turns. A game that ends starts a new one; no sample is a finished game.
List<Position> randomReachablePositions(Variant v, int n, Random rng) {
  final rules = v.rules;
  final cascade = rules.cascade;
  final out = <Position>[];
  while (out.length < n) {
    var p = Position.forRules(rules);
    var side = rng.nextBool() ? Side.one : Side.two;
    final turns = {Side.one: 0, Side.two: 0};
    var gap = 2 + rng.nextInt(6);
    for (var roll = 1; roll <= 400 && out.length < n; roll++) {
      final a = 1 + rng.nextInt(6), b = 1 + rng.nextInt(6);
      final ctx = TurnContext(firstTurn: turns[side] == 0);
      final tree = cascade != null && a == b && roll > cascade.normalRolls
          ? generateCascade(p, side, cascadeQueue(a), rules, ctx)
          : generatePlays(p, side, a == b ? [a, a, a, a] : [a, b], rules, ctx);
      turns[side] = turns[side]! + 1;
      if (tree.hasPlay) {
        final f = _randomFinal(tree, rng);
        if (endsGame(f, rules, side)) break;
        p = f;
      }
      side = side.opponent;
      if (--gap == 0) {
        out.add(p);
        gap = 2 + rng.nextInt(6);
      }
    }
  }
  return out;
}

/// A random legal final of [tree] (which has a play): uniform over the
/// finals of an eager tree, a random walk down a lazy one.
Position _randomFinal(PlayTree tree, Random rng) {
  if (!tree.isLazy) {
    final f = tree.finals;
    return f.elementAt(rng.nextInt(f.length));
  }
  var node = tree.root;
  while (!node.isComplete) {
    final next = node.nextSteps.toList();
    node = node.child(next[rng.nextInt(next.length)])!;
  }
  return node.finalPosition!;
}

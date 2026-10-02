/// Test positions for the bot: builders, mirroring and random reachable
/// positions.
library;

import 'dart:convert';
import 'dart:math';

import 'package:tavli_bot/src/eval/evaluator.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

/// An opposing-direction position from own-pip maps; omitted checkers are
/// borne off.
Position opp(
  Map<int, int> one,
  Map<int, int> two, {
  int barOne = 0,
  int barTwo = 0,
  Set<int> pinnedOne = const {},
  Set<int> pinnedTwo = const {},
}) =>
    Position.fromPips(
      one: one,
      two: two,
      barOne: barOne,
      barTwo: barTwo,
      pinnedOne: pinnedOne,
      pinnedTwo: pinnedTwo,
      direction: Direction.opposing,
    );

/// A same-direction position from own-pip maps.
Position same(Map<int, int> one, Map<int, int> two) =>
    Position.fromPips(one: one, two: two, direction: Direction.same);

/// [p] with the two sides' checkers swapped.
Position mirror(Position p) {
  final j = jsonDecode(jsonEncode(p.toJson())) as Map<String, Object?>;
  return Position.fromJson({
    ...j,
    'one': j['two'],
    'two': j['one'],
    'pinnedOne': j['pinnedTwo'],
    'pinnedTwo': j['pinnedOne'],
  });
}

/// [n] positions from random legal games of [v]: each turn plays a random
/// legal play of a random roll (Gul Bara doubles after the normal rolls
/// cascade), sampling every 2..7 turns. No sample is a finished game.
List<Position> randomPositions(Variant v, int n, Random rng) {
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
        final f = tree.isLazy
            ? CascadeWalker(tree).sampleCompletions(1, rng).first.finalPosition
            : tree.finals.elementAt(rng.nextInt(tree.finals.length));
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

/// [e] is exactly antisymmetric on [p] (up to 1e-9): the two sides' views
/// swap win and loss, and gammon and loss-gammon, and negate equity.
void expectAntisymmetric(Evaluator e, Position p, VariantRules r,
    {String reason = ''}) {
  final a = e.evaluate(p, Side.one, r), b = e.evaluate(p, Side.two, r);
  final why = '$reason $p\n$a\n$b';
  expect(a.winProb + b.winProb, closeTo(1, 1e-9), reason: why);
  expect(a.gammonProb, closeTo(b.lossGammonProb, 1e-9), reason: why);
  expect(a.lossGammonProb, closeTo(b.gammonProb, 1e-9), reason: why);
  expect(a.equity, closeTo(-b.equity, 1e-9), reason: why);
  for (final x in [a, b]) {
    expect(x.winProb, inInclusiveRange(0, 1), reason: why);
    expect(x.gammonProb, inInclusiveRange(0, x.winProb), reason: why);
    expect(x.lossGammonProb, inInclusiveRange(0, 1 - x.winProb + 1e-12),
        reason: why);
  }
}

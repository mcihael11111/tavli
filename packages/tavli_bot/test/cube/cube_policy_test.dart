import 'dart:math';

import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';

final _nard = Variant.shortNard.rules;
const _one = Side.one, _two = Side.two;
const _centred = CubeState(enabled: true);

/// Side one, on roll, in a 70-pip race with no wastage (points 4..6
/// held, at most 3 on each of 1..3).
const _me = {8: 1, 7: 1, 6: 3, 5: 3, 4: 3, 3: 2, 2: 2};

/// Side two's home board (55 pips) plus two outfield checkers on [a]
/// and [b].
Map<int, int> _them(int a, int b) => {a: 1, b: 1, 6: 3, 5: 3, 4: 3, 3: 2, 2: 2};

// Race lead L = (pipsTwo - 70) / mean pips; side one's 0-ply winProb is
// logistic(11 * (L + 0.04)) (on roll).
final _even = posOpp(_me, _them(9, 7)); // 71 pips
final _take = posOpp(_me, {9: 2, 6: 3, 5: 3, 4: 3, 3: 2, 2: 2}); // 73 pips
final _easyTake = posOpp(_me, _them(11, 9)); // 75 pips
final _double = posOpp(_me, _them(12, 10)); // 77 pips
final _pass = posOpp(_me, _them(13, 12)); // 80 pips

bool _offer(Position p, BotLevel l,
        {CubeState cube = _centred, VariantRules? rules}) =>
    shouldOffer(
        position: p,
        side: _one,
        rules: rules ?? _nard,
        cube: cube,
        level: l,
        rng: Random(1),
        budget: const Duration(seconds: 10));

bool _takes(Position p, BotLevel l) => shouldTake(
    position: p,
    side: _two,
    rules: _nard,
    cube: _centred.copyWith(value: 2, owner: _two, offeredBy: _one),
    level: l,
    rng: Random(1),
    budget: const Duration(seconds: 10));

EvalResult _view(Position p, BotLevel l) =>
    cubeView(p, _one, _nard, l, budget: const Duration(seconds: 10));

void main() {
  const easy = BotLevel.easy, medium = BotLevel.medium;
  const searching = [BotLevel.hard, BotLevel.expert];

  test('fixtures are the races they claim', () {
    for (final (p, pips) in [
      (_take, 73),
      (_easyTake, 75),
      (_double, 77),
      (_pass, 80),
    ]) {
      expect(isRace(p, _nard), isTrue);
      expect(effectivePips(p, _one), 70);
      expect(effectivePips(p, _two), pips);
    }
  });

  group('labelled Short Nard positions', () {
    test('clear double: offer (not Easy)', () {
      // L = 7 / 73.5 = 0.095: winProb = logistic(11 * 0.135) = 0.816.
      expect(_view(_double, medium).winProb, closeTo(0.816, 0.005));
      expect(_offer(_double, medium), isTrue);
      for (final l in searching) {
        expect(_offer(_double, l), isTrue, reason: '$l');
      }
    });

    test('early start: no offer', () {
      final start = Position.forRules(_nard);
      // 0-ply: 0.50. 1-ply: about 0.60 (the side about to move gains).
      expect(_view(start, medium).winProb, closeTo(0.5, 1e-9));
      for (final l in [medium, ...searching]) {
        expect(_view(start, l).winProb, lessThan(0.65), reason: '$l');
        expect(_offer(start, l), isFalse, reason: '$l');
      }
    });

    test('too good (closed out, gammon likely): no offer, and a pass', () {
      // My closed board, two of theirs on the bar, none off: winProb
      // ~1.0 and gammonProb ~0.85, above 0.85 / 0.35.
      final p = posOpp(
          {6: 2, 5: 2, 4: 2, 3: 2, 2: 2, 1: 2, 9: 3}, {13: 5, 8: 4, 6: 4},
          barTwo: 2);
      for (final l in [medium, ...searching]) {
        final v = _view(p, l);
        expect(v.winProb, greaterThan(0.99), reason: '$l');
        expect(v.gammonProb, greaterThan(0.35), reason: '$l');
        expect(_offer(p, l), isFalse, reason: '$l');
        expect(_takes(p, l), isFalse, reason: '$l');
      }
    });

    test('clear take: taker at 30 %', () {
      // L = 3 / 71.5 = 0.042: offerer 0.711, taker 0.289 >= 0.25.
      expect(1 - _view(_take, medium).winProb, closeTo(0.289, 0.005));
      expect(_offer(_take, medium), isTrue); // double, take
      expect(_takes(_take, medium), isTrue);
    });

    test('clear take at 1-ply: taker at 29 % after the roll', () {
      // Even race, 70 v 71: taker 0.355 at 0-ply. Hard and Expert average
      // the offerer's 21 rolls, which here gives the offerer about 0.07
      // more than the 0-ply on-roll shift (the +-0.04 race shift is
      // smaller than one roll's swing at 70 pips), so their take is
      // labelled on a closer race than the 0-ply one above.
      expect(effectivePips(_even, _two), 71);
      for (final l in searching) {
        final taker = 1 - _view(_even, l).winProb;
        expect(taker, inInclusiveRange(0.27, 0.31), reason: '$l');
        expect(_takes(_even, l), isTrue, reason: '$l');
      }
    });

    test('clear pass: taker at 13 %', () {
      // L = 10 / 75 = 0.133: offerer 0.871, taker 0.129 < 0.20.
      expect(1 - _view(_pass, medium).winProb, closeTo(0.129, 0.005));
      for (final l in BotLevel.values) {
        expect(_takes(_pass, l), isFalse, reason: '$l');
      }
    });

    test('Easy never offers; takes iff winProb >= 0.20', () {
      for (final p in [_take, _double, _pass]) {
        expect(_offer(p, easy), isFalse);
      }
      // 70 v 75: L = 0.069, taker 1 - 0.768 = 0.232: in Easy's 0.20, not
      // in 0.25.
      expect(1 - _view(_easyTake, medium).winProb, closeTo(0.232, 0.005));
      expect(_takes(_easyTake, easy), isTrue);
      expect(_takes(_easyTake, medium), isFalse);
      expect(_takes(_take, easy), isTrue);
    });
  });

  group('who may double', () {
    test('only with a cube in use, not pending, held or centred', () {
      expect(_offer(_double, medium), isTrue);
      expect(_offer(_double, medium, cube: _centred.copyWith(owner: _one)),
          isTrue);
      expect(_offer(_double, medium, cube: _centred.copyWith(owner: _two)),
          isFalse);
      expect(_offer(_double, medium, cube: _centred.copyWith(offeredBy: _two)),
          isFalse);
      expect(
          _offer(_double, medium, cube: _centred.copyWith(value: 64)), isFalse);
      expect(_offer(_double, medium, cube: const CubeState(enabled: false)),
          isFalse);
      // Portes has no cube.
      final portes = Variant.portes.rules;
      expect(_offer(_double, medium, rules: portes), isFalse);
    });
  });

  group('the race on-roll shift', () {
    test('+0.04 lead on roll, -0.04 off roll; complementary', () {
      const race = RaceEvaluator();
      final me = race.evaluate(_double, _one, _nard);
      final opp = race.evaluate(_double, _two, _nard);
      final on = withRaceRoll(me, _double, _nard, onRoll: true);
      final off = withRaceRoll(opp, _double, _nard, onRoll: false);
      const lead = 7 / 73.5;
      expect(on.winProb, closeTo(logistic(11 * (lead + 0.04)), 1e-12));
      expect(off.winProb, closeTo(1 - on.winProb, 1e-12));
    });

    test('keeps the gammon shares; no change outside a race', () {
      final p = posOpp({6: 5, 5: 5, 4: 5}, {18: 2, 17: 13}); // race
      final e = const RaceEvaluator().evaluate(p, _one, _nard);
      expect(e.gammonProb, greaterThan(0));
      final s = withRaceRoll(e, p, _nard, onRoll: true);
      expect(s.gammonProb / s.winProb, closeTo(e.gammonProb / e.winProb, 1e-9));
      final start = Position.forRules(_nard);
      final x = evaluatorFor(_nard).evaluate(start, _one, _nard);
      expect(withRaceRoll(x, start, _nard, onRoll: true), same(x));
    });
  });

  test('Hard falls back to 0-ply when the budget is spent', () {
    final v =
        cubeView(_double, _one, _nard, BotLevel.hard, budget: Duration.zero);
    expect(v.winProb, _view(_double, medium).winProb);
  });
}

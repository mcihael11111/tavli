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
final _take = posOpp(_me, {9: 2, 6: 3, 5: 3, 4: 3, 3: 2, 2: 2}); // 73 pips
final _easyTake = posOpp(_me, _them(11, 9)); // 75 pips
final _double = posOpp(_me, _them(12, 10)); // 77 pips
final _pass = posOpp(_me, _them(13, 12)); // 80 pips

bool _offer(Position p, BotLevel l,
        {CubeState cube = _centred,
        VariantRules? rules,
        bool crawfordGame = false}) =>
    shouldOffer(
        position: p,
        side: _one,
        rules: rules ?? _nard,
        cube: cube,
        level: l,
        rng: Random(1),
        crawfordGame: crawfordGame);

bool _takes(Position p, BotLevel l) => shouldTake(
    position: p,
    side: _two,
    rules: _nard,
    cube: _centred.copyWith(value: 2, owner: _two, offeredBy: _one),
    level: l,
    rng: Random(1));

EvalResult _view(Position p) => cubeView(p, _one, _nard);

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
      expect(_view(_double).winProb, closeTo(0.816, 0.005));
      expect(_offer(_double, medium), isTrue);
      for (final l in searching) {
        expect(_offer(_double, l), isTrue, reason: '$l');
      }
    });

    test('early start: no offer', () {
      final start = Position.forRules(_nard);
      // Every level reads the 0-ply view: 0.50 for the side on roll (the
      // start is not a race, so no on-roll shift).
      expect(_view(start).winProb, lessThanOrEqualTo(0.56));
      for (final l in BotLevel.values) {
        expect(_offer(start, l), isFalse, reason: '$l');
      }
    });

    test('too good (closed out, gammon likely): no offer, and a pass', () {
      // My closed board, two of theirs on the bar, none off: winProb
      // ~1.0 and gammonProb ~0.85, above 0.85 / 0.35.
      final p = posOpp(
          {6: 2, 5: 2, 4: 2, 3: 2, 2: 2, 1: 2, 9: 3}, {13: 5, 8: 4, 6: 4},
          barTwo: 2);
      final v = _view(p);
      expect(v.winProb, greaterThan(0.99));
      expect(v.gammonProb, greaterThan(0.35));
      for (final l in [medium, ...searching]) {
        expect(_offer(p, l), isFalse, reason: '$l');
        expect(_takes(p, l), isFalse, reason: '$l');
      }
    });

    test('clear take: taker at 30 %', () {
      // L = 3 / 71.5 = 0.042: offerer 0.711, taker 0.289 >= 0.25.
      expect(1 - _view(_take).winProb, closeTo(0.289, 0.005));
      for (final l in [medium, ...searching]) {
        expect(_offer(_take, l), isTrue, reason: '$l'); // double, take
        expect(_takes(_take, l), isTrue, reason: '$l');
      }
    });

    test('clear pass: taker at 13 %', () {
      // L = 10 / 75 = 0.133: offerer 0.871, taker 0.129 < 0.20.
      expect(1 - _view(_pass).winProb, closeTo(0.129, 0.005));
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
      expect(1 - _view(_easyTake).winProb, closeTo(0.232, 0.005));
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

  test('never offers in the Crawford game', () {
    for (final l in BotLevel.values) {
      expect(_offer(_double, l, crawfordGame: true), isFalse, reason: '$l');
    }
  });
}

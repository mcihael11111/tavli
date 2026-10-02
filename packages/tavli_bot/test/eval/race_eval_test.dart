import 'package:tavli_bot/src/eval/race_eval.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';

const _one = Side.one;
final _portes = Variant.portes.rules;
const _race = RaceEvaluator();

void main() {
  test('equal pip counts: winProb 0.40..0.55, no real gammons', () {
    // Identical home boards, 75 pips each: either side needs ~9 rolls to
    // finish and has a checker off after one, so the smooth gammon share
    // is negligible (no cliff to exactly 0 any more).
    final p = posOpp({6: 5, 5: 5, 4: 5}, {6: 5, 5: 5, 4: 5});
    final e = _race.evaluate(p, _one, _portes);
    expect(e.winProb, inInclusiveRange(0.40, 0.55));
    expect(e.gammonProb, lessThan(1e-6));
    expect(e.lossGammonProb, lessThan(1e-6));
  });

  test('me 20 pips ahead in a 100-pip race: winProb > 0.7', () {
    // Me 80 (10 on 6, 5 on 4), them 100 (10 on 7, 5 on 6).
    final p = posOpp({6: 10, 4: 5}, {7: 10, 6: 5});
    expect((p.pipCount(Side.one), p.pipCount(Side.two)), (80, 100));
    expect(_race.evaluate(p, _one, _portes).winProb, greaterThan(0.7));
    // 100 vs 120 too.
    final q = posOpp({7: 10, 6: 5}, {8: 15});
    expect((q.pipCount(Side.one), q.pipCount(Side.two)), (100, 120));
    expect(_race.evaluate(q, _one, _portes).winProb, greaterThan(0.7));
  });

  test('14 off vs 15 on the 6-point: winProb > 0.95, gammonProb > 0.5', () {
    // My last checker is on my 1-point: I am off next turn. They need an
    // exact 6 (or 3-3, 2-2, 4-2, 5-1 ...) to get one off; 19 of 36 rolls
    // do not, so even with them on roll the gammon is 0.53.
    final p = posOpp({1: 1}, {6: 15});
    expect(p.borneOff(_one), 14);
    final e = _race.evaluate(p, _one, _portes);
    expect(e.winProb, greaterThan(0.95));
    expect(e.gammonProb, greaterThan(0.5));
    expect(e.lossGammonProb, lessThan(0.01));
  });

  test('more borne off / a better race scores better', () {
    final base = posOpp({6: 5, 5: 5, 4: 5}, {6: 5, 5: 5, 4: 5});
    final ahead = posOpp({6: 5, 5: 5, 4: 4}, {6: 5, 5: 5, 4: 5});
    final further = posOpp({6: 4, 5: 5, 4: 4}, {6: 5, 5: 5, 4: 5});
    final b = _race.evaluate(base, _one, _portes).equity;
    final a = _race.evaluate(ahead, _one, _portes).equity;
    final f = _race.evaluate(further, _one, _portes).equity;
    expect(a, greaterThan(b));
    expect(f, greaterThan(a));
  });

  test('wastage: stacked low points count against me', () {
    // Same 45 pips. Mine: 4 on each of the 1- and 2-points (1 wasted
    // each) and gaps on 4 and 5 (0.5 each): 3 wastage. Theirs: at most 3
    // on each low point, no gap: none.
    final stacked =
        posOpp({6: 4, 3: 3, 2: 4, 1: 4}, {6: 1, 5: 1, 4: 4, 3: 3, 2: 3, 1: 3});
    expect(stacked.pipCount(Side.one), stacked.pipCount(Side.two));
    final e = _race.evaluate(stacked, _one, _portes);
    expect(effectivePips(stacked, Side.one), 48);
    expect(effectivePips(stacked, Side.two), 45);
    expect(e.winProb, lessThan(0.5));
  });

  test('crossovers: 15 on their 7-point vs my 4 on the 6: gammon > 0.5', () {
    // They need 15 crossovers (~6.5 rolls at 2.3 a roll) before a checker
    // can come off; I need ~3 rolls for 24 pips.
    final p = posOpp({6: 4}, {7: 15});
    final e = _race.evaluate(p, _one, _portes);
    expect(e.gammonProb, greaterThan(0.5));
  });

  test('gammon share is monotone and smooth as my pips drop', () {
    // My runner walks from my 16 to my 7 (home unchanged, so the wastage
    // is constant); they have 15 on their 8.
    double? prev;
    for (var k = 16; k >= 7; k--) {
      final p = posOpp({k: 1, 6: 1, 5: 1, 4: 1}, {8: 15});
      final e = _race.evaluate(p, _one, _portes);
      final share = e.gammonProb / e.winProb;
      if (prev != null) {
        expect(share, greaterThanOrEqualTo(prev), reason: 'k=$k');
        expect(share - prev, lessThanOrEqualTo(0.1), reason: 'k=$k');
      }
      prev = share;
    }
  });
}

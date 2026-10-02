import 'package:tavli_bot/src/eval/features.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

const _one = Side.one, _two = Side.two;
final _portes = Variant.portes.rules;
final _plakoto = Variant.plakoto.rules;
final _fevga = Variant.fevga.rules;

Position _opp(Map<int, int> one, Map<int, int> two,
        {int barOne = 0,
        int barTwo = 0,
        Set<int> pinnedOne = const {},
        Set<int> pinnedTwo = const {}}) =>
    Position.fromPips(
      one: one,
      two: two,
      barOne: barOne,
      barTwo: barTwo,
      pinnedOne: pinnedOne,
      pinnedTwo: pinnedTwo,
      direction: Direction.opposing,
    );

Position _same(Map<int, int> one, Map<int, int> two) =>
    Position.fromPips(one: one, two: two, direction: Direction.same);

void main() {
  group('isRace', () {
    test('false at every start', () {
      for (final v in Variant.values) {
        expect(isRace(Position.forRules(v.rules), v.rules), isFalse,
            reason: '$v');
      }
    });

    test('true when disengaged, opposing directions', () {
      // Both sides home: rearmost 6 + 6 <= 24.
      final p = _opp({6: 5, 5: 5, 4: 5}, {6: 5, 5: 5, 4: 5});
      expect(isRace(p, _portes), isTrue);
      // Just passed: my rearmost 13 + their rearmost 11 = 24.
      expect(isRace(_opp({13: 1, 6: 14}, {11: 1, 6: 14}), _portes), isTrue);
      // Still engaged: 13 + 13 = 26 (their 13 is my 12; my 13 must pass
      // it).
      expect(isRace(_opp({13: 1, 6: 14}, {13: 1, 6: 14}), _portes), isFalse);
    });

    test('true when disengaged, same direction', () {
      // Both sides on their second halves (own pips 1..12).
      final p = _same({12: 5, 3: 10}, {10: 15});
      expect(isRace(p, _fevga), isTrue);
      // One checker of mine still on my 13: it crosses their path.
      expect(isRace(_same({13: 1, 3: 14}, {10: 15}), _fevga), isFalse);
      // One of theirs still on their 13 (my 1): it crosses mine.
      expect(isRace(_same({12: 5, 3: 10}, {13: 1, 10: 14}), _fevga), isFalse);
    });

    test('false with a checker on the bar or pinned', () {
      expect(isRace(_opp({6: 14}, {6: 15}, barOne: 1), _portes), isFalse);
      expect(isRace(_opp({6: 15}, {6: 14}, barTwo: 1), _portes), isFalse);
      // My checker on my 20 pinned under theirs (their 5).
      final pinned = _opp({20: 1, 6: 14}, {5: 1, 4: 14}, pinnedOne: {20});
      expect(isRace(pinned, _plakoto), isFalse);
    });
  });

  group('features', () {
    test('counts, blots and shots (Portes)', () {
      // Me (one): blots on my 10 and my 5; points on 24, 13, 8, 6.
      // Them: points on their 24, 13, 8, 6 (my 1, 12, 17, 19).
      // My blot on 10 is their 15: sources 16..21 none (direct 0); 22..27
      // has their 24 (indirect 1). My blot on 5 is their 20: 21..26 has
      // their 24 (direct 1). So direct 1, indirect 1.
      final p = _opp(
        {24: 2, 13: 5, 10: 1, 8: 3, 6: 3, 5: 1},
        {24: 2, 13: 5, 8: 3, 6: 5},
      );
      final f = extractFeatures(p, _one, _portes);
      expect((f.pipMe, f.pipOpp), (p.pipCount(_one), p.pipCount(_two)));
      expect((f.offMe, f.offOpp, f.barMe, f.barOpp), (0, 0, 0, 0));
      expect((f.blotsMe, f.directShotsMe, f.indirectShotsMe), (2, 1, 1));
      expect((f.blotsOpp, f.directShotsOpp, f.indirectShotsOpp), (0, 0, 0));
      expect((f.madePointsMe, f.madePointsOpp), (4, 4));
      expect((f.homePointsMe, f.homePointsOpp), (1, 1));
      // My 24 is their 1: an anchor in their home; theirs likewise.
      expect((f.anchorsMe, f.anchorsOpp), (1, 1));
      expect((f.primeLenMe, f.primeLenOpp), (1, 1));
      expect((f.pinnedMe, f.pinnedOpp), (0, 0));
      expect((f.headCountMe, f.headCountOpp), (2, 2));

      // Seen from the other side, everything swaps.
      final g = extractFeatures(p, _two, _portes);
      expect((g.blotsOpp, g.directShotsOpp, g.indirectShotsOpp), (2, 1, 1));
      expect((g.madePointsOpp, g.pipOpp), (4, p.pipCount(_one)));
    });

    test('shots from the bar and several sources', () {
      // My blot on my 20 = their 5. Their sources: bar (25, 20 away:
      // neither), their 8 (3 away: direct), their 11 (6: direct), their
      // 12 (7: indirect), their 17 (12: indirect). Direct 2, indirect 2.
      final p = _opp(
        {20: 1, 6: 14},
        {8: 2, 11: 2, 12: 2, 17: 2, 1: 6},
        barTwo: 1,
      );
      final f = extractFeatures(p, _one, _portes);
      expect((f.blotsMe, f.directShotsMe, f.indirectShotsMe), (1, 2, 2));
      expect(f.barOpp, 1);
    });

    test('prime length 4', () {
      // My 8, 7, 6, 5 made, then a gap, then 2.
      final p = _opp({8: 2, 7: 2, 6: 2, 5: 2, 2: 7}, {24: 15});
      final f = extractFeatures(p, _one, _portes);
      expect(f.primeLenMe, 4);
      expect(f.homePointsMe, 3);
      expect(f.madePointsMe, 5);
      expect(f.primeLenOpp, 1);
    });

    test('anchors', () {
      // My 24 and 21 made (their 1 and 4): two anchors; my 18 (their 7)
      // is outside their home.
      final p = _opp({24: 2, 21: 2, 18: 2, 6: 9}, {6: 15});
      expect(extractFeatures(p, _one, _portes).anchorsMe, 2);
    });

    test('pinned and mother-pinned flags (Plakoto)', () {
      // My mother (my 24 = their 1) is pinned under their single checker;
      // my single checker on my 5 pins theirs (their 20).
      final p = _opp(
        {24: 1, 5: 1, 6: 13},
        {1: 1, 20: 1, 24: 13},
        pinnedOne: {24},
        pinnedTwo: {20},
      );
      final f = extractFeatures(p, _one, _plakoto);
      expect((f.pinnedMe, f.pinnedOpp), (1, 1));
      expect((f.motherPinnedMe, f.motherPinnedOpp), (true, false));
      // Neither the pinned nor the pinning checker is a blot.
      expect(f.blotsMe, 0);
      // My points: 6 (13 checkers) and 5 (pinning). Theirs: 24 and 1
      // (pinning); their pinned 20 holds nothing.
      expect((f.madePointsMe, f.madePointsOpp), (2, 2));
      expect(f.headCountMe, 1);
      final g = extractFeatures(p, _two, _plakoto);
      expect((g.motherPinnedMe, g.motherPinnedOpp), (false, true));
    });

    test('block contact: single checkers are points, never blots', () {
      final p = _same({24: 10, 20: 1, 19: 1, 18: 1, 17: 1, 16: 1}, {24: 15});
      final f = extractFeatures(p, _one, _fevga);
      expect(f.blotsMe, 0);
      expect(f.primeLenMe, 5);
      expect(f.madePointsMe, 6);
      expect(f.headCountMe, 10);
    });
  });
}

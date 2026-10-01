import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/plays.dart';
import '../support/positions.dart';

typedef S = Side;

final _portes = Variant.portes.rules;
final _fevga = Variant.fevga.rules;
final _longNard = Variant.longNard.rules;
final _ctx = TurnContext();

/// Tree invariants that hold for every generated tree.
void expectWellFormed(PlayTree t) {
  final seqs = sequencesOf(t);
  expect(t.finals, {for (final q in seqs) t.walk(q)!.finalPosition});
  for (final q in seqs) {
    final n = t.walk(q)!;
    expect(n.nextSteps, isEmpty, reason: 'complete nodes are leaves');
    expect(t.finals, contains(n.finalPosition));
  }
  void check(PlayNode n) {
    expect(n.finalPosition != null, n.isComplete);
    if (!n.isComplete) expect(n.nextSteps, isNotEmpty, reason: 'pruned');
    for (final s in n.nextSteps) {
      check(n.child(s)!);
    }
  }

  if (t.hasPlay) check(t.root);
  expect(t.isForced, t.finals.length == 1);
}

void main() {
  group('G4 max dice', () {
    final start = Position.forRules(_portes);

    test('G4 standard opening 3-1 Portes', () {
      final t = generatePlays(start, S.one, const [3, 1], _portes, _ctx);
      expectWellFormed(t);
      // Hand count. two holds my 1, 12, 17, 19 (>= 2 each), so open steps:
      //   3: 24->21, 13->10, 8->5, 6->3      1: 24->23, 8->7, 6->5
      //   (13->12 is blocked; 13->10->9 still works via the 3 first).
      // One checker moving 4: from 24, 13, 8, 6                  =  4
      // Two checkers, 3 from {24,13,8,6} x 1 from {24,8,6}; each pair is
      // a distinct final, and none equals a one-checker final (x-3 and
      // y-1 never hit a source point)                             = 12
      // No hits are possible (two has no blots).          Total = 16
      expect(t.finals.length, 16);
      expect(
          t.finals,
          contains(after(start, S.one, _portes, const [
            Step(8, 5, 3),
            Step(6, 5, 1),
          ])));
      expect(
          t.finals,
          contains(after(start, S.one, _portes, const [
            Step(13, 10, 3),
            Step(10, 9, 1),
          ])));
      expect(
          t.finals,
          contains(after(start, S.one, _portes, const [
            Step(24, 21, 3),
            Step(24, 23, 1),
          ])));
      // Using only one die is never legal here.
      expect(
        t.finals,
        isNot(contains(after(start, S.one, _portes, const [Step(8, 5, 3)]))),
      );
      expect(t.isForced, isFalse);
      expect(t.hasPlay, isTrue);
      expect(t.diceUsed, 2);
      expect(t.remainder, isEmpty);
    });

    test('G4 the same opening for side two', () {
      final t = generatePlays(start, S.two, const [1, 3], _portes, _ctx);
      expectWellFormed(t);
      expect(t.finals.length, 16);
      expect(
          t.finals,
          contains(after(start, S.two, _portes, const [
            Step(8, 5, 3),
            Step(6, 5, 1),
          ])));
    });

    // one: bar 1 and a checker on 10. two holds my 17 (= two's 8) and my 8
    // (= two's 17). Entering with the 6 (25->19) leaves no 2 (19->17 and
    // 10->8 blocked); entering with the 2 (25->23) leaves 10->4 for the 6.
    final mustUseBoth = pos(
      one: {10: 1},
      barOne: 1,
      two: {8: 2, 17: 2, 1: 11},
    );

    test('G4 must use both dice', () {
      final t = generatePlays(mustUseBoth, S.one, const [6, 2], _portes, _ctx);
      expectWellFormed(t);
      expect(t.diceUsed, 2);
      expect(t.finals, {
        after(mustUseBoth, S.one, _portes, const [
          Step(25, 23, 2),
          Step(10, 4, 6),
        ]),
      });
    });

    test('G4 higher die when only one playable', () {
      // A lone checker on 13; two holds my 5 (= two's 20): 13->8->5 and
      // 13->10->5 both fail, so only one die plays, and it must be the 5.
      final p = pos(one: {13: 1}, two: {20: 2, 1: 13});
      final t = generatePlays(p, S.one, const [3, 5], _portes, _ctx);
      expectWellFormed(t);
      expect(t.diceUsed, 1);
      expect(t.finals, {
        after(p, S.one, _portes, const [Step(13, 8, 5)]),
      });
      expect(t.root.nextSteps, [const Step(13, 8, 5)]);
    });

    test('G4 higher die counts only validator-approved steps', () {
      // Fevga: runner on 20, 14 on the unreleased head. The 5 has only the
      // head step 24->19 (rejected by the sole-runner rule; 20->15 is
      // blocked by two on its 3). The 3 plays 20->17; then the 5 from 17
      // hits two's head (my 12). So the lower die is the only play.
      final p = posSame(one: {24: 14, 20: 1}, two: {24: 14, 3: 1});
      final t = generatePlays(p, S.one, const [5, 3], _fevga, _ctx);
      expectWellFormed(t);
      expect(t.diceUsed, 1);
      expect(t.finals, {
        after(p, S.one, _fevga, const [Step(20, 17, 3)]),
      });
    });

    // A7 (lower-die sequences dropped even when they reach the same final as
    // a higher-die one) has no test because no position can reach it. With
    // one die played, a play is a single step; two single steps with
    // different dice reach the same final only if they bear off the same
    // checker from the same pip h, so at least one die overshoots (> h).
    // G6 then puts every other checker on pips <= h, below the other die,
    // so after either step the other die bears off the highest remaining
    // checker. Nothing can block that: all are still home (G5), no own
    // checker is pinned (D11 would have blocked the first bear-off), the
    // turn has no hit (D4), and validators otherwise only restrict leaving
    // pip 24 or occupying a point. Both dice play, or the first step ends
    // the game (A4), so the max is never one die. The
    // generator still drops such sequences: it filters by dice used, not by
    // final (see the higher-die test above).

    test('G4 doubles play as many as possible', () {
      // A lone checker on 13; two holds my 5: 13->11->9->7, then 7->5 fails.
      final p = pos(one: {13: 1}, two: {20: 2, 1: 13});
      final t = generatePlays(p, S.one, const [2, 2, 2, 2], _portes, _ctx);
      expectWellFormed(t);
      expect(t.diceUsed, 3);
      expect(t.finals, {posAfterMove(p, 13, 7)});
      expect(t.isForced, isTrue);
    });

    test('G9 no legal play', () {
      // two holds my 19..24 (= two's 1..6): the bar checker cannot enter.
      final p = pos(
        one: {6: 14},
        barOne: 1,
        two: {1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 6: 5},
      );
      final t = generatePlays(p, S.one, const [5, 3], _portes, _ctx);
      expect(t.hasPlay, isFalse);
      expect(t.finals, isEmpty);
      expect(t.diceUsed, 0);
      expect(t.isForced, isFalse);
      expect(t.root.nextSteps, isEmpty);
      expect(t.root.isComplete, isFalse);
      expect(t.root.finalPosition, isNull);
    });
  });

  group('tree', () {
    final start = Position.forRules(_portes);

    test('dedup: two orders, one final, both prefixes', () {
      final t = generatePlays(start, S.one, const [3, 1], _portes, _ctx);
      final a = t.walk(const [Step(8, 5, 3), Step(5, 4, 1)]);
      final b = t.walk(const [Step(8, 7, 1), Step(7, 4, 3)]);
      expect(a, isNotNull);
      expect(b, isNotNull);
      expect(a!.isComplete, isTrue);
      expect(b!.isComplete, isTrue);
      expect(a.finalPosition, b.finalPosition);
      expect(t.finals.where((f) => f == a.finalPosition), hasLength(1));
    });

    test('tree walk: next steps only continue surviving plays', () {
      final p = pos(one: {10: 1}, barOne: 1, two: {8: 2, 17: 2, 1: 11});
      final t = generatePlays(p, S.one, const [6, 2], _portes, _ctx);
      // Entering with the 6 is a legal single step but no surviving play.
      expect(t.root.nextSteps, [const Step(25, 23, 2)]);
      expect(t.root.isComplete, isFalse);
      expect(t.root.child(const Step(25, 19, 6)), isNull);
      final n1 = t.root.child(const Step(25, 23, 2))!;
      expect(n1.isComplete, isFalse);
      expect(n1.finalPosition, isNull);
      expect(n1.nextSteps, [const Step(10, 4, 6)]);
      final n2 = n1.child(const Step(10, 4, 6))!;
      expect(n2.isComplete, isTrue);
      expect(n2.finalPosition, t.finals.single);
      expect(t.walk(const [Step(25, 23, 2), Step(10, 4, 6)]), same(n2));
      expect(t.walk(const []), same(t.root));
      expect(t.walk(const [Step(25, 19, 6)]), isNull);
    });

    test('isForced: exactly one legal final', () {
      final p = pos(one: {10: 1}, barOne: 1, two: {8: 2, 17: 2, 1: 11});
      expect(
        generatePlays(p, S.one, const [6, 2], _portes, _ctx).isForced,
        isTrue,
      );
      expect(
        generatePlays(start, S.one, const [6, 5], _portes, _ctx).isForced,
        isFalse,
      );
    });

    test('doubles: every order of a final is in the tree', () {
      final t = generatePlays(start, S.one, const [1, 1, 1, 1], _portes, _ctx);
      expectWellFormed(t);
      // 8->7, 6->5, 8->7, 6->5 in two of its orders.
      for (final q in const [
        [Step(8, 7, 1), Step(8, 7, 1), Step(6, 5, 1), Step(6, 5, 1)],
        [Step(6, 5, 1), Step(8, 7, 1), Step(6, 5, 1), Step(8, 7, 1)],
      ]) {
        expect(t.walk(q)?.isComplete, isTrue, reason: '$q');
      }
    });

    test('A4 G8 bearing off the last checker completes the play', () {
      // Portes, one on 3, dice 5-2: 3 off with the 5 ends the game at once;
      // 3->1, 1 off also uses both dice. Same final, both orders legal.
      final p = pos(one: {3: 1}, two: {1: 15});
      final t = generatePlays(p, S.one, const [5, 2], _portes, _ctx);
      expectWellFormed(t);
      expect(t.finals, hasLength(1));
      expect(t.diceUsed, 2);
      expect(t.walk(const [Step(3, 0, 5)])?.isComplete, isTrue);
      expect(t.walk(const [Step(3, 1, 2), Step(1, 0, 5)])?.isComplete, isTrue);
    });

    test('rejects malformed dice', () {
      for (final d in const [
        <int>[],
        [3],
        [3, 3],
        [3, 3, 3],
        [3, 4, 4, 4],
        [0, 2],
        [7, 2],
      ]) {
        expect(
          () => generatePlays(start, S.one, d, _portes, _ctx),
          throwsArgumentError,
          reason: '$d',
        );
      }
    });
  });

  group('A4 game-ending steps', () {
    final plakoto = Variant.plakoto.rules;

    test('D8a a 1-die mother pin is a full play', () {
      // two's mother on its 24 (= my 1); none of mine on my 24. 3->1 with
      // the 2 pins it and ends the game; the 5 could not follow (10->5 is
      // closed by two's 20). 10->8->3 uses both dice.
      final p = pos(one: {3: 1, 10: 14}, two: {24: 1, 20: 2, 13: 12});
      final t = generatePlays(p, S.one, const [2, 5], plakoto, _ctx);
      expectWellFormed(t);
      expect(t.diceUsed, 2);
      final mother = t.walk(const [Step(3, 1, 2)]);
      expect(mother?.isComplete, isTrue);
      expect(mother!.nextSteps, isEmpty);
      expect(t.finals, contains(mother.finalPosition));
      expect(
        t.finals,
        contains(after(p, S.one, plakoto, const [
          Step(10, 8, 2),
          Step(8, 3, 5),
        ])),
      );
      expect(t.finals, hasLength(2));
    });

    test('D8b leaving the start with the opp mother pinned ends the play', () {
      final p = pos(
        one: {24: 1, 1: 1, 10: 13},
        two: {24: 1, 20: 2, 13: 12},
        pinnedTwo: {24},
      );
      final t = generatePlays(p, S.one, const [6, 2], plakoto, _ctx);
      expectWellFormed(t);
      expect(t.diceUsed, 2);
      expect(t.walk(const [Step(24, 18, 6)])?.isComplete, isTrue);
      expect(t.walk(const [Step(24, 22, 2)])?.isComplete, isTrue);
      // A non-ending first step must still be followed by the other die.
      expect(t.walk(const [Step(10, 4, 6)])?.isComplete, isFalse);
    });
  });

  group('turn context', () {
    test('D18 first-turn 6-6 derives the dice into the context', () {
      // The caller's context has no dice; the generator must add them, or
      // the first-turn exception would silently not apply.
      final start = Position.forRules(_longNard);
      final ctx = TurnContext(firstTurn: true);
      final t = generatePlays(start, S.one, const [6, 6, 6, 6], _longNard, ctx);
      expectWellFormed(t);
      // 24->18 twice; 18->12 is two's head, so two steps in all.
      expect(t.diceUsed, 2);
      expect(t.finals, {
        posSame(one: {24: 13, 18: 2}, two: {24: 15}),
      });
    });

    test('D18 later turn 6-6: one head checker', () {
      final start = Position.forRules(_longNard);
      final t =
          generatePlays(start, S.one, const [6, 6, 6, 6], _longNard, _ctx);
      expect(t.diceUsed, 1);
      expect(t.finals, {
        posSame(one: {24: 14, 18: 1}, two: {24: 15}),
      });
    });

    test('D4 Tavla: no hit-and-run within the generated play', () {
      final tavla = Variant.tavla.rules;
      // two's blot on its 21 = my 4. After hitting 6->4 with the 2, the
      // hitter may not run on with the 3 (4->1) in Tavla; Portes allows it.
      final p = pos(one: {6: 2, 8: 1, 13: 12}, two: {21: 1, 1: 14});
      final t = generatePlays(p, S.one, const [2, 3], tavla, _ctx);
      expectWellFormed(t);
      expect(t.walk(const [Step(6, 4, 2), Step(4, 1, 3)]), isNull);
      expect(t.walk(const [Step(6, 4, 2), Step(6, 3, 3)])?.isComplete, isTrue);
      final portes = generatePlays(p, S.one, const [2, 3], _portes, _ctx);
      expect(
        portes.walk(const [Step(6, 4, 2), Step(4, 1, 3)])?.isComplete,
        isTrue,
      );
    });
  });
}

/// [p] with one checker of side one moved from [from] to [to] (no contact).
Position posAfterMove(Position p, int from, int to) {
  final m = p.toMutable()..move(S.one, from, to);
  return m.freeze();
}

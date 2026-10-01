import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/plays.dart';
import '../support/positions.dart';

typedef S = Side;

final _gul = Variant.gulBara.rules;
final _ctx = TurnContext();

void main() {
  group('cascadeQueue', () {
    test('D15 cascadeQueue(3) and (6)', () {
      expect(
        cascadeQueue(3),
        [3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6],
      );
      expect(cascadeQueue(6), [6, 6, 6, 6]);
      expect(cascadeQueue(1), hasLength(24));
      expect(() => cascadeQueue(0), throwsRangeError);
      expect(() => cascadeQueue(7), throwsRangeError);
    });

    test('generateCascade rejects malformed queues', () {
      final p = Position.forRules(_gul);
      for (final q in const [
        <int>[],
        [0, 1],
        [7],
      ]) {
        expect(
          () => generateCascade(p, S.one, q, _gul, _ctx),
          throwsArgumentError,
          reason: '$q',
        );
      }
    });
  });

  group('D16 cascade', () {
    test('D16 failure leaves remainder', () {
      // one: a stuck checker on 24 (two holds my 21, 20, 19 = its 9, 8, 7)
      // keeps bear-off off; 10 checkers on 1..3 never move a 3+; 4 movers
      // on 11. The 3s and 4s move 28 pips, leaving the movers 16 pips in
      // all (each >= 1). Two 5s need a mover on 11 (11->6->1); three would
      // need >= 6 + 6 + 6 + 1 = 19 > 16. So the most is 4 + 4 + 2 = 10.
      final p = posSame(
        one: {24: 1, 11: 4, 3: 4, 2: 3, 1: 3},
        two: {24: 12, 9: 1, 8: 1, 7: 1},
      );
      final t = generateCascade(p, S.one, cascadeQueue(3), _gul, _ctx);
      expect(t.hasPlay, isTrue);
      expect(t.diceUsed, 10);
      expect(t.remainder, [5, 5, 6, 6, 6, 6]);
      // 3s: 11->8->5 twice; 4s: 5->1 twice, 11->7->3; 5s: 11->6->1.
      const play = [
        Step(11, 8, 3),
        Step(8, 5, 3),
        Step(11, 8, 3),
        Step(8, 5, 3),
        Step(5, 1, 4),
        Step(5, 1, 4),
        Step(11, 7, 4),
        Step(7, 3, 4),
        Step(11, 6, 5),
        Step(6, 1, 5),
      ];
      expect(t.walk(play)?.isComplete, isTrue);
      expect(t.enumerateFinals(), contains(after(p, S.one, _gul, play)));
      // Every legal play stops at the same point of the queue.
      expect(t.walk(play.sublist(0, 9))?.isComplete, isFalse);
    });

    test('D16 the remainder is a valid queue for the opponent', () {
      final p = Position.forRules(_gul);
      final t = generateCascade(p, S.two, const [5, 5, 6, 6, 6, 6], _gul, _ctx);
      expect(t.diceUsed, 6);
      expect(t.remainder, isEmpty);
    });

    test('full cascade', () {
      // Gul Bara start: 72 pips of 3s..6s, only my 12 (two's head) closed.
      final p = Position.forRules(_gul);
      final t = generateCascade(p, S.one, cascadeQueue(3), _gul, _ctx);
      expect(t.diceUsed, 16);
      expect(t.remainder, isEmpty);
      expect(t.hasPlay, isTrue);
      // Order is fixed: the root offers only 3s.
      expect(t.root.nextSteps, [const Step(24, 21, 3)]);
    });

    test('cascade respects block contact', () {
      // A lone mover on 13 (14 on my 1 cannot move a 5 or 6).
      // two on my 3 (= its 15): 13->8, then 8->3 is blocked. The 6s could
      // still play (8->2) but the queue stops at the failing 5.
      final p = posSame(one: {13: 1, 1: 14}, two: {24: 14, 15: 1});
      final t = generateCascade(p, S.one, cascadeQueue(5), _gul, _ctx);
      expect(t.diceUsed, 1);
      expect(t.remainder, [5, 5, 5, 6, 6, 6, 6]);
      expect(t.enumerateFinals(), {
        after(p, S.one, _gul, const [Step(13, 8, 5)])
      });
      expect(sequencesOf(t), [
        [const Step(13, 8, 5)],
      ]);

      // two on my 8 (= its 20) as well: not even the first 5 plays.
      final q = posSame(one: {13: 1, 1: 14}, two: {24: 13, 15: 1, 20: 1});
      final none = generateCascade(q, S.one, cascadeQueue(5), _gul, _ctx);
      expect(none.hasPlay, isFalse);
      expect(none.diceUsed, 0);
      expect(none.enumerateFinals(), isEmpty);
      expect(none.remainder, cascadeQueue(5));
    });

    test('G8 bearing off the last checker ends the cascade', () {
      final p = posSame(one: {3: 1}, two: {24: 15});
      final t = generateCascade(p, S.one, cascadeQueue(4), _gul, _ctx);
      expect(t.diceUsed, 12);
      expect(t.remainder, isEmpty);
      expect(sequencesOf(t), [
        [const Step(3, 0, 4)],
      ]);
    });
  });
}

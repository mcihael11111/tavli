import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

void main() {
  test('defaults', () {
    const c = TurnContext();
    expect(c.headDepartures, 0);
    expect(c.firstTurn, isFalse);
    expect(c.homeHitMask, 0);
    expect(c.diceOfTurn, isEmpty);
    expect(c.isDouble, isFalse);
  });

  test('D18 isDouble for two- and four-dice forms', () {
    expect(const TurnContext(diceOfTurn: [6, 6]).isDouble, isTrue);
    expect(const TurnContext(diceOfTurn: [3, 3, 3, 3]).isDouble, isTrue);
    expect(const TurnContext(diceOfTurn: [5, 3]).isDouble, isFalse);
  });

  test('D18 afterStep counts head departures only when told', () {
    const c = TurnContext(firstTurn: true, diceOfTurn: [6, 6]);
    const a = AppliedStep(Step(24, 18, 6));
    final c1 = c.afterStep(a, fromHead: true);
    expect(c1.headDepartures, 1);
    expect(c1.firstTurn, isTrue);
    expect(c1.diceOfTurn, [6, 6]);
    expect(identical(c1.afterStep(a, fromHead: false), c1), isTrue);
  });

  test('D4 afterStep records hits on home pips 1..6 only', () {
    const c = TurnContext();
    final c1 = c.afterStep(
      const AppliedStep(Step(6, 4, 2), hit: true),
      fromHead: false,
    );
    expect(c1.homeHitMask, 1 << 4);
    final c2 = c1.afterStep(
      const AppliedStep(Step(13, 7, 6), hit: true),
      fromHead: false,
    );
    expect(identical(c2, c1), isTrue, reason: 'pip 7 is not home');
    final c3 = c1.afterStep(
      const AppliedStep(Step(4, 1, 3)),
      fromHead: false,
    );
    expect(identical(c3, c1), isTrue, reason: 'no hit');
    final c4 = c1.afterStep(
      const AppliedStep(Step(8, 2, 6), hit: true),
      fromHead: false,
    );
    expect(c4.homeHitMask, (1 << 4) | (1 << 2));
  });
}

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

void main() {
  test('defaults', () {
    final c = TurnContext();
    expect(c.headDepartures, 0);
    expect(c.firstTurn, isFalse);
    expect(c.homeHitMask, 0);
    expect(c.diceOfTurn, isEmpty);
    expect(c.isDouble, isFalse);
  });

  test('D18 isDouble for two- and four-dice forms', () {
    expect(TurnContext(diceOfTurn: [6, 6]).isDouble, isTrue);
    expect(TurnContext(diceOfTurn: [3, 3, 3, 3]).isDouble, isTrue);
    expect(TurnContext(diceOfTurn: [5, 3]).isDouble, isFalse);
  });

  test('D18 afterStep counts head departures only when told', () {
    final c = TurnContext(firstTurn: true, diceOfTurn: [6, 6]);
    const a = AppliedStep(Step(24, 18, 6));
    final c1 = c.afterStep(a, fromHead: true, homeHit: false);
    expect(c1.headDepartures, 1);
    expect(c1.firstTurn, isTrue);
    expect(c1.diceOfTurn, [6, 6]);
    expect(
      identical(c1.afterStep(a, fromHead: false, homeHit: false), c1),
      isTrue,
    );
  });

  test('D4 afterStep records hits on home pips 1..6 only', () {
    final c = TurnContext();
    final c1 = c.afterStep(
      const AppliedStep(Step(6, 4, 2), hit: true),
      fromHead: false,
      homeHit: true,
    );
    expect(c1.homeHitMask, 1 << 4);
    final c2 = c1.afterStep(
      const AppliedStep(Step(13, 7, 6), hit: true),
      fromHead: false,
      homeHit: true,
    );
    expect(identical(c2, c1), isTrue, reason: 'pip 7 is not home');
    final c3 = c1.afterStep(
      const AppliedStep(Step(4, 1, 3)),
      fromHead: false,
      homeHit: false,
    );
    expect(identical(c3, c1), isTrue, reason: 'no hit');
    final c4 = c1.afterStep(
      const AppliedStep(Step(8, 2, 6), hit: true),
      fromHead: false,
      homeHit: true,
    );
    expect(c4.homeHitMask, (1 << 4) | (1 << 2));
  });

  test('D4 afterStep ignores a hit when not told it is a D4 hit', () {
    final c = TurnContext();
    final c1 = c.afterStep(
      const AppliedStep(Step(6, 4, 2), hit: true),
      fromHead: false,
      homeHit: false,
    );
    expect(identical(c1, c), isTrue);
  });

  test('value equality and hashCode', () {
    final a = TurnContext(firstTurn: true, diceOfTurn: [6, 6, 6, 6]);
    final b = TurnContext(
      firstTurn: true,
      diceOfTurn: List.of([6, 6, 6, 6]),
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == TurnContext(diceOfTurn: [6, 6, 6, 6]), isFalse);
    expect(a == a.withDice(const [6, 6]), isFalse);
    expect(
      TurnContext(headDepartures: 1) == TurnContext(),
      isFalse,
    );
    expect(
      TurnContext(homeHitMask: 1 << 3) == TurnContext(),
      isFalse,
    );
  });

  test('dice are copied, so the cached hash stays valid', () {
    final dice = [5, 3];
    final c = TurnContext(diceOfTurn: dice);
    final h = c.hashCode;
    dice[0] = 6;
    expect(c.diceOfTurn, [5, 3]);
    expect(c.hashCode, h);
    expect(() => c.diceOfTurn[0] = 1, throwsUnsupportedError);
  });

  test('withDice replaces only the dice', () {
    final c = TurnContext(headDepartures: 1, firstTurn: true, homeHitMask: 4);
    final d = c.withDice(const [3, 3, 3, 3]);
    expect(d.diceOfTurn, [3, 3, 3, 3]);
    expect(d.headDepartures, 1);
    expect(d.firstTurn, isTrue);
    expect(d.homeHitMask, 4);
    expect(d.isDouble, isTrue);
  });
}

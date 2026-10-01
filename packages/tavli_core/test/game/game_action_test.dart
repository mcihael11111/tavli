import 'dart:math';

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

void main() {
  test('every action round-trips through JSON', () {
    for (final a in const <GameAction>[
      RollOpening(5, 2),
      RollDice(6, 6),
      StepAction(Step(3, 0, 5)),
      UndoStep(),
      CommitPlay(),
      OfferDouble(),
      Take(),
      Drop(),
      Resign(Side.one),
      ClockTimeout(Side.two),
    ]) {
      final back = GameAction.fromJson(a.toJson());
      expect(back, a, reason: '${a.toJson()}');
      expect(back.runtimeType, a.runtimeType);
      expect(back.hashCode, a.hashCode);
    }
    expect(const Resign(Side.one), isNot(const ClockTimeout(Side.one)));
    expect(const Take(), isNot(const Drop()));
  });

  test('fromJson throws only FormatException', () {
    for (final j in <Map<String, Object?>>[
      {},
      {'type': 'fly'},
      {'type': 'rollDice', 'd1': 3},
      {'type': 'rollDice', 'd1': 3, 'd2': '4'},
      {'type': 'step'},
      {
        'type': 'step',
        'step': {'from': 3, 'to': 1, 'die': 5},
      },
      {'type': 'resign', 'side': 'three'},
      {'type': 'timeout'},
      {'type': 'clockTimeout'},
    ]) {
      expect(() => GameAction.fromJson(j), throwsFormatException, reason: '$j');
    }
  });

  test('fromJson takes any decoded JSON; non-objects are FormatException', () {
    for (final j in <Object?>[
      null,
      3,
      'take',
      [],
      {1: 2}
    ]) {
      expect(() => GameAction.fromJson(j), throwsFormatException, reason: '$j');
    }
    // Unknown extra keys are ignored.
    expect(GameAction.fromJson({'type': 'take', 'side': 'one'}), const Take());
  });

  test('DiceRoll.random stays in 1..6 and validates', () {
    final rng = Random(5);
    final rolls = [for (var i = 0; i < 500; i++) DiceRoll.random(rng)];
    final seen = {
      for (final r in rolls) ...[r.d1, r.d2]
    };
    expect(seen, {1, 2, 3, 4, 5, 6});
    expect(() => DiceRoll(0, 3), throwsRangeError);
    expect(() => DiceRoll(3, 7), throwsRangeError);
    expect(DiceRoll(4, 4).isDouble, isTrue);
  });
}

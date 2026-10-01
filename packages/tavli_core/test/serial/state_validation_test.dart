import 'dart:convert';

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';
import '../support/reducer.dart';

typedef S = Side;

/// Through a JSON string and back, as over the wire.
Map<String, Object?> wire(Object? json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

/// A Portes board with a Plakoto-style pin: one's lone checker on its pip
/// 20 under two's checker on two's pip 5 (reviewer repro). A valid
/// [Position], but no hitting game can reach it.
final _pinnedBoard = pos(
  one: {24: 1, 13: 5, 8: 3, 6: 5, 20: 1},
  two: {24: 2, 13: 5, 8: 3, 6: 4, 5: 1},
  pinnedOne: {20},
);

/// A start-like board in [d] with one of one's checkers on the bar.
Position _barBoard(Direction d) =>
    pos(one: {24: 14}, two: {24: 15}, barOne: 1, direction: d);

/// [s] as JSON with [key] set to [value].
Map<String, Object?> _with(GameState s, String key, Object? value) =>
    wire({...s.toJson(), key: value});

Map<String, Object?> _cube(int value, {S? owner, S? offeredBy}) => {
      'value': value,
      'owner': owner?.name,
      'offeredBy': offeredBy?.name,
      'enabled': true,
    };

void main() {
  group('the board must suit the variant', () {
    test('no pinned checkers outside a pinning game', () {
      final s = GameState.initial(Variant.portes, starter: S.one);
      expect(() => s.withPosition(_pinnedBoard), throwsArgumentError);
      expect(
        () => GameState.fromJson(_with(s, 'turnStart', _pinnedBoard.toJson())),
        throwsFormatException,
      );
      // The same pin is fine in Plakoto.
      final plakoto = GameState.initial(Variant.plakoto, starter: S.one);
      final ok = plakoto.withPosition(_pinnedBoard);
      expect(GameState.fromJson(wire(ok.toJson())), ok);
    });

    test('no checkers on the bar outside a hitting game', () {
      for (final v in [Variant.plakoto, Variant.fevga]) {
        final s = GameState.initial(v, starter: S.one);
        final bar = _barBoard(v.rules.direction);
        expect(() => s.withPosition(bar), throwsArgumentError, reason: v.name);
        expect(
          () => GameState.fromJson(_with(s, 'turnStart', bar.toJson())),
          throwsFormatException,
          reason: v.name,
        );
      }
      final portes = GameState.initial(Variant.portes, starter: S.one);
      final ok = portes.withPosition(_barBoard(Direction.opposing));
      expect(GameState.fromJson(wire(ok.toJson())), ok);
    });
  });

  group('a pending double must be one _offer could make', () {
    final toRoll =
        GameState.initial(Variant.shortNard, starter: S.one, cubeEnabled: true);

    Map<String, Object?> offered(Map<String, Object?> cube,
            {bool crawford = false}) =>
        wire({
          ...toRoll.toJson(),
          'phase': 'cubeOffered',
          'cube': cube,
          'crawfordGame': crawford,
        });

    test('accepted: centered or owned by the offerer, below 64', () {
      for (final cube in [
        _cube(1, offeredBy: S.one),
        _cube(32, owner: S.one, offeredBy: S.one),
      ]) {
        final s = GameState.fromJson(offered(cube));
        expect(s.phase, GamePhase.cubeOffered);
        expect(GameState.fromJson(wire(s.toJson())), s);
      }
    });

    test('rejected: cube at 64, Crawford game, opponent owns the cube', () {
      for (final (why, json) in [
        ('64', offered(_cube(64, owner: S.one, offeredBy: S.one))),
        ('crawford', offered(_cube(1, offeredBy: S.one), crawford: true)),
        ('owner', offered(_cube(2, owner: S.two, offeredBy: S.one))),
      ]) {
        expect(() => GameState.fromJson(json), throwsFormatException,
            reason: why);
      }
    });
  });

  group('Gul Bara cascade dice', () {
    /// Two to roll at roll 4 (cascades on): see gul_bara_test.dart D16.
    GameState twoToRoll() {
      var s = GameState.initial(Variant.gulBara, starter: S.one);
      for (final d in const [3, 4, 2]) {
        s = playAny(ok(s, RollDice(d, d)).state);
      }
      return s.withPosition(posSame(
        two: {24: 15},
        one: {6: 2, 1: 2, 20: 2, 15: 2, 24: 7},
      ));
    }

    test('a fresh cascade is a whole cascade queue', () {
      final s = ok(twoToRoll(), const RollDice(5, 5)).state;
      expect(GameState.fromJson(wire(s.toJson())), s);
      for (final dice in [
        [5, 5, 6, 6, 6, 6], // a suffix, but not a remainder turn
        [5, 5, 5, 5, 6, 6, 6], // short
        [5, 5, 5, 5, 6, 6, 6, 6, 6], // long
        [6, 6, 6, 6, 5, 5, 5, 5], // out of order
        [5, 3, 6],
      ]) {
        expect(() => GameState.fromJson(_with(s, 'dice', dice)),
            throwsFormatException,
            reason: '$dice');
      }
    });

    test('a remainder turn plays a suffix of a cascade queue', () {
      var s = ok(twoToRoll(), const RollDice(5, 5)).state;
      for (var i = 0; i < 4; i++) {
        s = ok(s, const StepAction(Step(24, 19, 5))).state;
      }
      final rem = ok(s, const CommitPlay()).state;
      expect(rem.remainderTurn, isTrue);
      expect(GameState.fromJson(wire(rem.toJson())), rem);
      for (final dice in [
        [6, 6, 6, 6, 6],
        [6, 5, 6],
        [4, 6],
      ]) {
        expect(() => GameState.fromJson(_with(rem, 'dice', dice)),
            throwsFormatException,
            reason: '$dice');
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/game/data/models/game_result.dart' as app;
import 'package:tavli/features/game/domain/engine/variants/game_variant.dart';
import 'package:tavli/gameplay/adapters/difficulty_adapter.dart';
import 'package:tavli/gameplay/adapters/result_adapter.dart';
import 'package:tavli/gameplay/adapters/variant_adapter.dart';
import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart' as core;

void main() {
  group('variant adapter', () {
    test('maps all 13 variants one-to-one', () {
      expect(GameVariant.values, hasLength(13));
      final mapped = GameVariant.values.map((v) => v.core).toSet();
      expect(mapped, core.Variant.values.toSet());
    });

    test('round-trips both ways', () {
      for (final v in GameVariant.values) {
        expect(v.core.app, v);
        expect(v.core.name, v.name);
      }
      for (final v in core.Variant.values) {
        expect(v.app.core, v);
      }
    });
  });

  group('difficulty adapter', () {
    test('maps every level to a bot level and teaching flag', () {
      expect(DifficultyLevel.easy.botSetting,
          (level: BotLevel.easy, teaching: false));
      expect(DifficultyLevel.easyWithHelp.botSetting,
          (level: BotLevel.easy, teaching: true));
      expect(DifficultyLevel.medium.botSetting,
          (level: BotLevel.medium, teaching: false));
      expect(DifficultyLevel.hard.botSetting,
          (level: BotLevel.hard, teaching: false));
      expect(DifficultyLevel.pappous.botSetting,
          (level: BotLevel.expert, teaching: false));
    });
  });

  group('result adapter', () {
    core.GameResult r(core.ResultKind kind, int points,
            {core.Side? winner = core.Side.one, int cube = 1}) =>
        core.GameResult(
            winner: winner, kind: kind, points: points, cubeValue: cube);

    void expectApp(core.GameResult c, int winner, app.GameResultType type,
        {int cube = 1}) {
      final a = appResultOf(c)!;
      expect(a.winner, winner);
      expect(a.type, type);
      expect(a.cubeValue, cube);
    }

    test('single', () {
      expectApp(r(core.ResultKind.single, 1), 1, app.GameResultType.single);
    });

    test('gammon, cube carried', () {
      final c = r(core.ResultKind.gammon, 8, winner: core.Side.two, cube: 4);
      expectApp(c, 2, app.GameResultType.gammon, cube: 4);
      expect(appResultOf(c)!.points, 8);
    });

    test('triple maps to backgammon', () {
      expectApp(r(core.ResultKind.triple, 3), 1, app.GameResultType.backgammon);
    });

    test('mother (2 points) maps to gammon', () {
      final c = r(core.ResultKind.mother, 2);
      expectApp(c, 1, app.GameResultType.gammon);
      expect(appResultOf(c)!.points, 2);
    });

    test('draw has no app result', () {
      expect(appResultOf(r(core.ResultKind.draw, 1, winner: null)), isNull);
    });

    test('checkers remaining maps by points', () {
      expectApp(r(core.ResultKind.checkersRemaining, 1), 1,
          app.GameResultType.single);
      expectApp(r(core.ResultKind.checkersRemaining, 2), 1,
          app.GameResultType.gammon);
      expectApp(r(core.ResultKind.checkersRemaining, 9), 1,
          app.GameResultType.backgammon);
    });

    test('resign and timeout map by points before the cube', () {
      expectApp(r(core.ResultKind.resign, 2, cube: 2, winner: core.Side.two), 2,
          app.GameResultType.single,
          cube: 2);
      expectApp(
          r(core.ResultKind.resign, 4, cube: 2), 1, app.GameResultType.gammon,
          cube: 2);
      expectApp(
          r(core.ResultKind.timeout, 3), 1, app.GameResultType.backgammon);
    });
  });
}

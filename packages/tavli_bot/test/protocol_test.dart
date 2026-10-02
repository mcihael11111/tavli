import 'dart:isolate';

import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

BotRequest request({
  int id = 7,
  List<int> dice = const [5, 3],
  List<Step> steps = const [],
  Duration? budget,
  int? supersedes,
}) =>
    BotRequest(
      id: id,
      kind: BotRequestKind.choosePlay,
      variant: Variant.plakoto,
      position: Position.forRules(Variant.plakoto.rules),
      side: Side.two,
      dice: dice,
      cascade: false,
      context: TurnContext(firstTurn: true, diceOfTurn: dice),
      cube: const CubeState(value: 2, owner: Side.one, enabled: true),
      level: BotLevel.hard,
      seed: 1234,
      budget: budget,
      steps: steps,
      supersedes: supersedes,
    );

const _stats =
    BotStats(evaluated: 120, depthReached: 1, elapsedUs: 5300, timedOut: true);

void main() {
  group('BotRequest', () {
    test('value equality over every field', () {
      expect(request(), request());
      expect(request().hashCode, request().hashCode);
      expect(request(id: 8), isNot(request()));
      expect(request(dice: const [6, 3]), isNot(request()));
      expect(request(steps: const [Step(24, 19, 5)]), isNot(request()));
      expect(
          request(budget: const Duration(milliseconds: 5)), isNot(request()));
      expect(request(supersedes: 6), isNot(request()));
    });

    test('lists are unmodifiable copies', () {
      final dice = [5, 3];
      final steps = [const Step(24, 19, 5)];
      final r = request(dice: dice, steps: steps);
      dice[0] = 6;
      steps.clear();
      expect(r.dice, [5, 3]);
      expect(r.steps, [const Step(24, 19, 5)]);
      expect(() => r.dice.add(1), throwsUnsupportedError);
      expect(() => r.steps.add(const Step(1, 0, 1)), throwsUnsupportedError);
    });

    test('survives an isolate round trip', () async {
      final r = request(
        steps: const [Step(24, 19, 5)],
        budget: const Duration(milliseconds: 40),
        supersedes: 6,
      );
      final back = await Isolate.run(() => r);
      expect(back, r);
      expect(identical(back, r), isFalse);
    });

    test('a cascade analyze request survives the round trip', () async {
      final r = BotRequest(
        id: 1,
        kind: BotRequestKind.analyze,
        variant: Variant.gulBara,
        position: Position.forRules(Variant.gulBara.rules),
        side: Side.one,
        dice: cascadeQueue(4),
        cascade: true,
        context: TurnContext(diceOfTurn: cascadeQueue(4)),
        cube: const CubeState(enabled: false),
        level: BotLevel.medium,
        seed: 9,
      );
      expect(r.steps, isEmpty);
      expect(r.budget, isNull);
      expect(r.supersedes, isNull);
      expect(await Isolate.run(() => r), r);
    });
  });

  group('BotReply', () {
    test('each kind keeps value equality across an isolate', () async {
      final replies = <BotReply>[
        PlayReply(
            id: 1,
            stats: _stats,
            steps: const [Step(24, 19, 5), Step(19, 16, 3)]),
        const DecisionReply(id: 2, stats: _stats, yes: true),
        AnalysisReply(
          id: 3,
          stats: _stats,
          analysis: TurnAnalysis(
            nextStepQuality: {
              const Step(24, 19, 5): StepQuality.best,
              const Step(13, 8, 5): StepQuality.poor,
            },
            nextStepEquity: {
              const Step(24, 19, 5): 0.25,
              const Step(13, 8, 5): 0.1,
            },
            bestEquity: 0.25,
            playEquityLoss: null,
          ),
        ),
        const ErrorReply(id: 4, stats: _stats, message: 'boom'),
      ];
      for (final r in replies) {
        final back = await Isolate.run(() => r);
        expect(back, r, reason: '$r');
        expect(back.id, r.id);
        expect(back.stats, _stats);
      }
      expect(replies.toSet(), hasLength(4));
    });

    test('play steps are an unmodifiable copy', () {
      final steps = [const Step(24, 19, 5)];
      final r = PlayReply(id: 1, stats: _stats, steps: steps);
      steps.clear();
      expect(r.steps, hasLength(1));
      expect(() => r.steps.clear(), throwsUnsupportedError);
    });

    test('analysis maps are unmodifiable copies', () {
      final q = {const Step(24, 19, 5): StepQuality.good};
      final a = TurnAnalysis(
        nextStepQuality: q,
        nextStepEquity: {const Step(24, 19, 5): 0.0},
        bestEquity: 0.02,
        playEquityLoss: 0.02,
      );
      q.clear();
      expect(a.nextStepQuality, hasLength(1));
      expect(() => a.nextStepEquity.clear(), throwsUnsupportedError);
    });

    test('a sealed switch covers every reply', () {
      String kind(BotReply r) => switch (r) {
            PlayReply() => 'play',
            DecisionReply() => 'decision',
            AnalysisReply() => 'analysis',
            ErrorReply() => 'error',
          };
      expect(
          kind(const ErrorReply(id: 1, stats: _stats, message: 'x')), 'error');
    });
  });
}

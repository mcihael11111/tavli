import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/gameplay/session/board_command.dart';
import 'package:tavli/gameplay/session/match_setup.dart';
import 'package:tavli/gameplay/session/match_view.dart';
import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';

import 'match_harness.dart';

const _stats =
    BotStats(evaluated: 0, depthReached: 0, elapsedUs: 0, timedOut: false);

/// Real decisions, except the cube questions, answered [yes].
BotReply Function(BotRequest) _cube({required bool yes}) => (r) =>
    r.kind == BotRequestKind.offerDouble || r.kind == BotRequestKind.takeDouble
        ? DecisionReply(id: r.id, stats: _stats, yes: yes)
        : Bot.decide(r);

const _nard = Variant.shortNard;
final _nardStart = Position.forRules(_nard.rules);

MatchSetup _vs(Variant v, {DifficultyLevel d = DifficultyLevel.easy}) =>
    MatchSetup(mode: MatchMode.vsBot, variant: v, difficulty: d);

/// Side two (the bot) about to roll at the start of [v].
MatchState _botToRoll(Variant v, {bool cube = false}) => matchOf(
    v,
    GameState.initial(v, starter: Side.two, cubeEnabled: cube)
        .withPosition(Position.forRules(v.rules)),
    cubeEnabled: cube);

void main() {
  late Harness h;
  tearDown(() => h.dispose());

  group('cube vs bot', () {
    Future<void> humanOffers({required bool botTakes}) async {
      h = await Harness.create(_vs(_nard),
          backend: FakeBackend(answer: _cube(yes: botTakes)));
      h.controller.debugLoad(oneToRoll(_nard, _nardStart, cubeEnabled: true));
      expect(h.controller.offerDouble(), isTrue);
      expect(h.view.pendingDouble, Side.one);
      expect(h.view.busy, isTrue);
      await settle();
    }

    test('the bot takes: cube 2 to the bot, the human rolls', () async {
      await humanOffers(botTakes: true);
      expect(h.game.phase, GamePhase.awaitingRoll);
      expect(h.game.sideToMove, Side.one);
      expect(h.game.cube.value, 2);
      expect(h.game.cube.owner, Side.two);
      expect(h.notices.whereType<CubeAnswerNotice>().single.took, isTrue);
      expect(h.commands.whereType<CubeChanged>(), hasLength(2));
      expect(h.controller.offerDouble(), isFalse); // the bot owns it
    });

    test('the bot drops: the human wins and it is recorded', () async {
      await humanOffers(botTakes: false);
      expect(h.view.match.isOver, isTrue);
      final out = h.view.outcome as GoVictory;
      expect(out.result.winner, 1);
      expect(out.result.points, 1);
      expect(h.recorder.calls, hasLength(1));
    });

    Future<void> botOffers() async {
      h = await Harness.create(_vs(_nard),
          backend: FakeBackend(answer: _cube(yes: true)));
      h.controller.debugLoad(_botToRoll(_nard, cube: true));
      await settle();
      expect(h.game.phase, GamePhase.cubeOffered);
      expect(h.view.pendingDouble, Side.two);
      expect(h.view.busy, isFalse);
    }

    test('the bot offers, the human takes, the bot plays on', () async {
      await botOffers();
      expect(h.controller.take(), isTrue);
      await settle();
      expect(h.game.cube.value, 2);
      expect(h.game.cube.owner, Side.one);
      expect(h.game.sideToMove, Side.one);
      expect(h.game.phase, isNot(GamePhase.cubeOffered));
    });

    test('the bot offers, the human drops and loses', () async {
      await botOffers();
      expect(h.controller.drop(), isTrue);
      expect((h.view.outcome as GoVictory).result.winner, 2);
      expect(h.recorder.calls.single.winner, 2);
    });
  });

  test('a bot play is animated one step at a time, then synced', () async {
    h = await Harness.create(_vs(Variant.portes), dice: [6, 5]);
    h.controller.debugLoad(_botToRoll(Variant.portes));
    await settle();
    expect(h.game.sideToMove, Side.one);
    final i = h.commands.indexWhere((c) => c is DiceLanded);
    final after = h.commands.sublist(i + 1);
    final moves = after.whereType<AnimateSteps>().toList();
    expect(moves, hasLength(2));
    expect(
        moves.every((m) => m.steps.length == 1 && m.side == Side.two), isTrue);
    expect(after.last, isA<Sync>());
    expect(h.commands.whereType<Rattle>().last.side, Side.two);
  });

  test('a bot error falls back to a legal play', () async {
    h = await Harness.create(_vs(Variant.portes),
        backend: FakeBackend(
            answer: (r) => ErrorReply(id: r.id, stats: _stats, message: 'x')));
    h.controller.debugLoad(_botToRoll(Variant.portes));
    await settle();
    expect(h.game.sideToMove, Side.one);
    expect(h.game.turnsTaken[Side.two], 1);
  });

  test('pause halts the bot loop; resume continues it', () async {
    h = await Harness.create(_vs(Variant.portes));
    h.controller.debugLoad(_botToRoll(Variant.portes));
    h.controller.pause();
    await settle();
    expect(h.game.phase, GamePhase.awaitingRoll);
    expect(h.game.sideToMove, Side.two);
    expect(h.backend.requests, isEmpty);
    expect(h.controller.roll(), isFalse);
    h.controller.resume();
    await settle();
    expect(h.game.sideToMove, Side.one);
    expect(h.view.busy, isFalse);
  });

  test('dispose cancels the pending bot request', () async {
    h = await Harness.create(_vs(Variant.portes));
    h.backend.hold = true;
    h.controller.debugLoad(_botToRoll(Variant.portes));
    await settle();
    final pending = h.backend.requests.single;
    expect(pending.kind, BotRequestKind.choosePlay);
    await h.closeController();
    expect(h.backend.cancelled, [pending.id]);
    h.backend.release(); // a late reply is ignored
    await settle();
  });

  test('resign during the bot turn abandons it', () async {
    h = await Harness.create(_vs(Variant.portes));
    h.backend.hold = true;
    h.controller.debugLoad(_botToRoll(Variant.portes));
    await settle();
    expect(h.controller.leaveMatch(), isTrue);
    h.backend.release();
    await settle();
    expect(h.view.busy, isFalse);
    expect(h.view.match.forfeitedBy, Side.one);
    expect(h.recorder.calls, hasLength(1));
  });

  group('teaching', () {
    MatchSetup teach() => _vs(Variant.portes, d: DifficultyLevel.easyWithHelp);

    test('qualities in the highlights and end-of-turn feedback', () async {
      h = await Harness.create(teach(), dice: [6, 5]);
      h.controller.rollOpening();
      await settle();
      final a = h.view.lastAnalysis!;
      h.controller.selectSource(24);
      final hl = h.view.selection.highlights;
      expect(hl, isNotEmpty);
      for (final x in hl) {
        expect(x.quality, a.nextStepQuality[x.step]);
        expect(x.quality, isNotNull);
      }
      h.controller.quickMove(24);
      h.controller.quickMove(13);
      await settle();
      final fb = h.notices.whereType<TeachingFeedback>().single;
      expect(fb.equityLoss, greaterThanOrEqualTo(0));
      expect(
          h.backend.requests.where((r) => r.side == Side.one),
          everyElement(
              predicate<BotRequest>((r) => r.kind == BotRequestKind.analyze)));
    });

    test('a newer analysis supersedes the pending one', () async {
      h = await Harness.create(teach(),
          prefs: {'tavli_move_confirm': true}, dice: [6, 5]);
      h.backend.hold = true;
      h.controller.rollOpening();
      await settle();
      final first = h.backend.requests.single;
      h.controller.quickMove(24);
      await settle();
      final second = h.backend.requests.last;
      expect(second.supersedes, first.id);
      expect(second.steps, [const Step(24, 18, 6)]);
      expect(h.backend.cancelled, contains(first.id));
      h.backend.release();
      await settle();
      expect(h.view.lastAnalysis, isNotNull);
    });

    test('no analysis without teaching', () async {
      h = await Harness.create(_vs(Variant.portes), dice: [6, 5]);
      h.controller.rollOpening();
      await settle();
      expect(h.backend.requests, isEmpty);
      expect(h.view.lastAnalysis, isNull);
    });
  });

  test('a draw (both mothers pinned) shows a draw and records nothing',
      () async {
    const v = Variant.plakoto;
    // One's mother (24) is pinned; one pins two's lone mother from 2.
    final p = Position.fromPips(
      one: {24: 1, 2: 1, 6: 13},
      two: {1: 1, 24: 1, 6: 13},
      pinnedOne: {24},
      direction: v.rules.direction,
    );
    h = await Harness.create(_vs(v),
        prefs: {'tavli_autoplay_forced': false}, dice: [1, 3]);
    h.controller.debugLoad(oneToRoll(v, p));
    h.controller.roll();
    expect(h.controller.selectSource(2), isTrue);
    expect(h.controller.stepTo(1), isTrue);
    expect(h.game.result!.kind, ResultKind.draw);
    final out = h.view.outcome as MatchDrawn;
    expect(out.result.winner, isNull);
    expect(h.recorder.calls, isEmpty);
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/game/data/models/game_result.dart' as app;
import 'package:tavli/gameplay/session/board_command.dart';
import 'package:tavli/gameplay/session/match_setup.dart';
import 'package:tavli/gameplay/session/match_view.dart';
import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';

import 'match_harness.dart';

const _stats =
    BotStats(evaluated: 0, depthReached: 0, elapsedUs: 0, timedOut: false);
const _noForced = {'tavli_autoplay_forced': false};

MatchSetup _vs(Variant v, {DifficultyLevel d = DifficultyLevel.easy}) =>
    MatchSetup(mode: MatchMode.vsBot, variant: v, difficulty: d);

/// Side two about to roll on [p] in Gul Bara, past the normal rolls (so a
/// double cascades).
MatchState _gulBaraBotToRoll(Position p) {
  final j = GameState.initial(Variant.gulBara, starter: Side.two)
      .withPosition(p)
      .toJson();
  j['rollIndex'] = 3;
  return matchOf(Variant.gulBara, GameState.fromJson(j));
}

MatchState _botToRoll(Variant v) => matchOf(
    v,
    GameState.initial(v, starter: Side.two)
        .withPosition(Position.forRules(v.rules)));

void main() {
  late Harness h;
  tearDown(() => h.dispose());

  group('a bot turn ending in a human Gul Bara remainder turn', () {
    // The bot's 4-4 cascade fails mid-queue; one plays the remainder.
    final failing = Position.fromPips(
        one: {24: 12, 9: 1, 8: 1, 7: 1},
        two: {24: 1, 13: 2, 1: 12},
        direction: Direction.same);

    test('selection, notices and analysis wait for the animations', () async {
      h = await Harness.create(
          _vs(Variant.gulBara, d: DifficultyLevel.easyWithHelp),
          prefs: _noForced,
          dice: [4, 4]);
      final from = h.commands.length;
      h.controller.debugLoad(_gulBaraBotToRoll(failing));
      await settle();
      final g = h.game;
      expect(g.remainderTurn, isTrue);
      expect(g.sideToMove, Side.one);
      expect(h.view.selection.sources, isNotEmpty);
      expect(h.notices.whereType<RemainderNotice>().single.to, Side.one);

      final cmds = h.commands.sublist(from);
      final lastBotStep =
          cmds.lastIndexWhere((c) => c is AnimateSteps && c.side == Side.two);
      final firstSelection = cmds.indexWhere(
          (c) => c is ShowSelection && c.selection.sources.isNotEmpty);
      expect(lastBotStep, greaterThan(0));
      expect(firstSelection, greaterThan(lastBotStep));

      final kinds = h.backend.requests.map((r) => r.kind).toList();
      expect(kinds.first, BotRequestKind.choosePlay);
      final analyze = h.backend.requests
          .where((r) => r.kind == BotRequestKind.analyze)
          .toList();
      expect(analyze, isNotEmpty);
      expect(analyze.every((r) => r.side == Side.one && r.cascade), isTrue);
    });

    test('A6: a blocked cascade hands the queue over; both notices kept',
        () async {
      // Two's lone stack on 24 cannot move at all (one holds two's 18..23).
      final blocked = Position.fromPips(
          one: {6: 2, 7: 2, 8: 2, 9: 2, 10: 2, 11: 2, 24: 3},
          two: {24: 15},
          direction: Direction.same);
      h = await Harness.create(_vs(Variant.gulBara),
          prefs: _noForced, dice: [5, 5]);
      h.controller.debugLoad(_gulBaraBotToRoll(blocked));
      await settle();
      expect(h.game.remainderTurn, isTrue);
      expect(h.game.sideToMove, Side.one);
      expect(h.notices.whereType<TurnPassedNotice>().single.side, Side.two);
      expect(h.notices.whereType<RemainderNotice>().single.to, Side.one);
      expect(h.view.selection.sources, isNotEmpty);
    });
  });

  test('Crawford game vs bot: no one may double', () async {
    const v = Variant.shortNard;
    h = await Harness.create(
        MatchSetup(mode: MatchMode.vsBot, variant: v, cubeEnabled: true),
        backend: FakeBackend(
            answer: (r) => r.kind == BotRequestKind.offerDouble
                ? DecisionReply(id: r.id, stats: _stats, yes: true)
                : Bot.decide(r)));
    h.controller.debugLoad(MatchState(
      config: MatchConfig.to(5, const [v], cubeEnabled: true),
      scores: const {Side.one: 4, Side.two: 0},
      gameIndex: 1,
      game: GameState.initial(v,
              starter: Side.two, crawfordGame: true, cubeEnabled: true)
          .withPosition(Position.forRules(v.rules)),
      history: const [
        GameResult(
            winner: Side.one, kind: ResultKind.single, points: 4, cubeValue: 4)
      ],
      crawfordUsed: true,
      winner: null,
    ));
    await settle();
    expect(h.backend.requests.map((r) => r.kind),
        isNot(contains(BotRequestKind.offerDouble)));
    expect(h.game.turnsTaken[Side.two], 1);
    if (h.game.phase == GamePhase.awaitingRoll) {
      expect(h.controller.offerDouble(), isFalse);
    }
  });

  group('Tawla 31 (a multi-game match)', () {
    test('resignGame ends the game only; nextGame starts the next', () async {
      h = await Harness.create(_vs(Variant.tawla31));
      expect(h.view.isMultiGame, isTrue);
      expect(h.controller.resignGame(), isTrue);
      expect(h.game.result!.kind, ResultKind.resign);
      expect(h.view.match.isOver, isFalse);
      expect(h.view.betweenGames, isTrue);
      expect(h.view.outcome, isNull);
      expect(h.recorder.calls, isEmpty);
      expect(h.controller.resignGame(), isFalse);
      expect(h.controller.nextGame(), isTrue);
      expect(h.view.match.gameIndex, 1);
      expect(h.game.phase, isNot(GamePhase.gameOver));
    });

    test('leaving between games after a won game records a single', () async {
      h = await Harness.create(_vs(Variant.tawla31));
      final over = reduce(GameState.initial(Variant.tawla31, starter: Side.two),
          const Resign(Side.two)) as GameUpdate;
      final won = over.state.result!;
      expect(won.winner, Side.one);
      h.controller.debugLoad(MatchState(
        config: MatchConfig.single(Variant.tawla31),
        scores: {Side.one: won.points, Side.two: 0},
        gameIndex: 0,
        game: over.state,
        history: [won],
        crawfordUsed: false,
        winner: null,
      ));
      expect(h.view.betweenGames, isTrue);
      expect(h.controller.leaveMatch(), isTrue);
      final r = (h.view.outcome as GoVictory).result;
      expect(r.winner, 2);
      expect(r.type, app.GameResultType.single);
      expect(r.cubeValue, 1);
      expect(h.recorder.calls.single, r);
    });

    test('a single-game match is not multi-game', () async {
      h = await Harness.create(_vs(Variant.portes));
      expect(h.view.isMultiGame, isFalse);
    });
  });

  test('pass & play: leaving during a pending handoff forfeits the viewer',
      () async {
    h = await Harness.create(
        MatchSetup(mode: MatchMode.passAndPlay, variant: Variant.portes),
        dice: [2, 5]);
    h.controller.rollOpening(); // two starts; the device is still one's
    expect(h.view.handoff, Side.two);
    expect(h.view.viewer, Side.one);
    expect(h.view.selection.sources, isEmpty);
    expect(h.view.awaitingConfirm, isFalse);
    expect(h.controller.leaveMatch(), isTrue);
    expect(h.view.match.forfeitedBy, Side.one);
    expect(h.recorder.calls, isEmpty);
  });

  test('pass & play: acknowledging the handoff restores the selection',
      () async {
    h = await Harness.create(
        MatchSetup(mode: MatchMode.passAndPlay, variant: Variant.portes),
        dice: [2, 5]);
    h.controller.rollOpening();
    expect(h.controller.acknowledgeHandoff(), isTrue);
    expect(h.view.viewer, Side.two);
    expect(h.view.selection.sources, isNotEmpty);
    expect(h.controller.selectSource(h.view.selection.sources.first), isTrue);
  });

  test('a board subscribing mid bot turn continues from the animated steps',
      () async {
    final gate = GatedDelay();
    h = await Harness.create(_vs(Variant.portes),
        dice: [6, 5], delay: gate.call);
    h.controller.debugLoad(_botToRoll(Variant.portes));
    bool botStepped() =>
        h.commands.any((c) => c is AnimateSteps && c.side == Side.two);
    for (var i = 0; i < 20 && !botStepped(); i++) {
      gate.release();
      await settle();
    }
    expect(botStepped(), isTrue);
    expect(h.view.busy, isTrue);

    final late = <BoardCommand>[];
    final sub = h.controller.commands.listen(late.add);
    addTearDown(sub.cancel);
    for (var i = 0; i < 20 && h.view.busy; i++) {
      gate.release();
      await settle();
    }
    expect(h.view.busy, isFalse);

    // The first Sync is the position after the step already animated;
    // replaying the later animations on it reaches the final board.
    var board = (late.first as Sync).game;
    expect(board.steps, hasLength(1));
    for (final a in late.whereType<AnimateSteps>()) {
      for (final s in a.steps) {
        board = (reduce(board, StepAction(s.step)) as GameUpdate).state;
      }
    }
    expect(board.position, h.game.position);
  });

  group('teaching latency', () {
    MatchSetup teach() => _vs(Variant.portes, d: DifficultyLevel.easyWithHelp);

    test('commit cancels the pending step analysis', () async {
      h = await Harness.create(teach(),
          prefs: {'tavli_move_confirm': true}, dice: [6, 5]);
      h.backend.hold = true;
      h.controller.rollOpening();
      h.controller.quickMove(24);
      h.controller.quickMove(13);
      await settle();
      final pending = h.backend.requests.last;
      expect(pending.steps, hasLength(2));
      expect(h.controller.commit(), isTrue);
      await settle();
      expect(h.backend.cancelled, contains(pending.id));
      h.backend.release();
      await settle();
      expect(h.notices.whereType<TeachingFeedback>(), hasLength(1));
    });

    test('feedback reuses the analysis of the complete play', () async {
      h = await Harness.create(teach(),
          prefs: {'tavli_move_confirm': true}, dice: [6, 5]);
      h.controller.rollOpening();
      h.controller.quickMove(24);
      h.controller.quickMove(13);
      await settle();
      expect(h.view.lastAnalysis!.playEquityLoss, isNotNull);
      final asked = h.backend.requests.length;
      h.backend.hold = true; // the bot's turn waits
      expect(h.controller.commit(), isTrue);
      expect(h.notices.whereType<TeachingFeedback>(), hasLength(1));
      await settle();
      expect(
          h.backend.requests
              .skip(asked)
              .where((r) => r.kind == BotRequestKind.analyze),
          isEmpty);
    });
  });

  test('a bot that keeps failing stops with an error notice', () async {
    h = await Harness.create(_vs(Variant.portes), dice: [6, 5]);
    // The bot mid-turn (one step taken): its whole-play SubmitPlay is
    // rejected every time.
    final rolled = (reduce(GameState.initial(Variant.portes, starter: Side.two),
            const RollDice(6, 5)) as GameUpdate)
        .state;
    final mid =
        (reduce(rolled, StepAction(rolled.node.nextSteps.first)) as GameUpdate)
            .state;
    h.controller.debugLoad(matchOf(Variant.portes, mid));
    await settle();
    expect(h.backend.requests.where((r) => r.kind == BotRequestKind.choosePlay),
        hasLength(3));
    expect(h.notices.whereType<BotErrorNotice>(), hasLength(1));
    expect(h.view.busy, isFalse);

    // Pause and resume act as a retry.
    h.controller
      ..pause()
      ..resume();
    await settle();
    expect(h.backend.requests.where((r) => r.kind == BotRequestKind.choosePlay),
        hasLength(6));
  });

  test('awaitingConfirm is false while paused', () async {
    h = await Harness.create(_vs(Variant.portes),
        prefs: {'tavli_move_confirm': true}, dice: [6, 5]);
    h.controller.rollOpening();
    h.controller.quickMove(24);
    h.controller.quickMove(13);
    expect(h.view.awaitingConfirm, isTrue);
    h.controller.pause();
    expect(h.view.awaitingConfirm, isFalse);
  });

  test('the command stream closes when the controller is disposed', () async {
    h = await Harness.create(_vs(Variant.portes));
    final done = Completer<void>();
    h.controller.commands.listen(null, onDone: done.complete);
    await h.closeController();
    await done.future.timeout(const Duration(seconds: 1));
  });

  test('intents after dispose are rejected', () async {
    h = await Harness.create(_vs(Variant.portes));
    final c = h.controller;
    await h.closeController();
    expect(c.rollOpening(), isFalse);
    c.clearSelection();
    expect(c.leaveMatch(), isFalse);
    expect(c.resignGame(), isFalse);
  });

  test('pass & play: a new subscriber gets the orientation first', () async {
    h = await Harness.create(
        MatchSetup(mode: MatchMode.passAndPlay, variant: Variant.portes),
        dice: [2, 5]);
    h.controller.rollOpening();
    h.controller.acknowledgeHandoff();
    final got = <BoardCommand>[];
    final sub = h.controller.commands.listen(got.add);
    addTearDown(sub.cancel);
    await settle();
    expect((got[0] as FlipView).viewer, Side.two);
    expect(got[1], isA<Sync>());
  });

  test('vs bot: the snapshot starts with the Sync', () async {
    h = await Harness.create(_vs(Variant.portes));
    final got = <BoardCommand>[];
    final sub = h.controller.commands.listen(got.add);
    addTearDown(sub.cancel);
    await settle();
    expect(got.first, isA<Sync>());
    expect(got.whereType<FlipView>(), isEmpty);
  });
}

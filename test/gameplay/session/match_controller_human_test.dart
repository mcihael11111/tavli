import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/game/data/models/game_result.dart' as app;
import 'package:tavli/gameplay/session/board_command.dart';
import 'package:tavli/gameplay/session/match_setup.dart';
import 'package:tavli/gameplay/session/match_view.dart';
import 'package:tavli/gameplay/session/step_picker.dart';
import 'package:tavli_core/tavli_core.dart';

import 'match_harness.dart';

const _confirm = {'tavli_move_confirm': true};
const _noForced = {'tavli_autoplay_forced': false};

/// One on the bar; two closes its 1..5 so only a 6 enters; one's 14 others
/// sit on pip 1 and cannot move until all are home: (6, 1) is forced.
final _forced = portes(
  one: {1: 14},
  barOne: 1,
  two: {1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 12: 5},
);

/// One on the bar against a closed board: no play with any dice.
final _closed = portes(
  one: {1: 14},
  barOne: 1,
  two: {1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 6: 2, 12: 3},
);

/// A bear-off with two checkers left (two far away on its own 19).
final _bearOff = portes(one: {3: 1, 1: 1}, two: {19: 15});

MatchSetup _portes() =>
    MatchSetup(mode: MatchMode.vsBot, variant: Variant.portes);

void main() {
  late Harness h;
  tearDown(() => h.dispose());

  group('opening', () {
    test('playOpeningDice: the winner plays the opening dice', () async {
      h = await Harness.create(_portes(), dice: [5, 3]);
      expect(h.game.phase, GamePhase.opening);
      expect(h.controller.rollOpening(), isTrue);
      expect(h.game.phase, GamePhase.moving);
      expect(h.game.sideToMove, Side.one);
      expect(h.game.dice, [5, 3]);
      expect(h.view.selection.sources, isNotEmpty);
      await settle();
      expect(h.commands.whereType<Rattle>(), hasLength(1));
      final landed = h.commands.whereType<DiceLanded>().single;
      expect(landed.opening, isTrue);
      expect(landed.dice, [5, 3]);
    });

    test('a tie stays in the opening', () async {
      h = await Harness.create(_portes(), dice: [4, 4]);
      expect(h.controller.rollOpening(), isTrue);
      expect(h.game.phase, GamePhase.opening);
    });

    test('winnerRerolls: the winner then rolls its own dice', () async {
      h = await Harness.create(
          MatchSetup(mode: MatchMode.vsBot, variant: Variant.tavla),
          dice: [6, 2, 3, 1]);
      expect(h.controller.rollOpening(), isTrue);
      expect(h.game.phase, GamePhase.awaitingRoll);
      expect(h.game.sideToMove, Side.one);
      expect(h.controller.roll(), isTrue);
      expect(h.game.dice, [3, 1]);
    });

    test('auto-roll rolls the opening and the turn', () async {
      h = await Harness.create(
          MatchSetup(mode: MatchMode.vsBot, variant: Variant.tavla),
          prefs: {'tavli_auto_roll': true},
          dice: [6, 2, 3, 1]);
      expect(h.game.phase, GamePhase.moving);
      expect(h.game.dice, [3, 1]);
    });
  });

  test('illegal intents change nothing and never throw', () async {
    h = await Harness.create(_portes());
    final before = h.view;
    expect(h.controller.roll(), isFalse);
    expect(h.controller.selectSource(13), isFalse);
    expect(h.controller.stepTo(8, from: 13), isFalse);
    expect(h.controller.quickMove(13), isFalse);
    expect(h.controller.swapDice(), isFalse);
    expect(h.controller.undo(), isFalse);
    expect(h.controller.commit(), isFalse);
    expect(h.controller.offerDouble(), isFalse);
    expect(h.controller.take(), isFalse);
    expect(h.controller.drop(), isFalse);
    expect(h.controller.nextGame(), isFalse);
    expect(h.controller.acknowledgeHandoff(), isFalse);
    expect(h.controller.acknowledgePass(), isFalse);
    expect(identical(h.view, before), isTrue);

    h.dice.push([5, 3]);
    h.controller.rollOpening();
    final moving = h.view;
    expect(h.controller.rollOpening(), isFalse);
    expect(h.controller.roll(), isFalse);
    expect(h.controller.stepTo(2, from: 24), isFalse); // no such step
    expect(h.controller.stepTo(20), isFalse); // nothing selected
    expect(h.controller.quickMove(7), isFalse); // no checker there
    expect(h.controller.selectSource(-3), isFalse);
    expect(h.controller.commit(), isFalse); // incomplete
    expect(h.controller.take(), isFalse);
    expect(h.game, moving.game);
  });

  test('highlights are node.nextSteps from the source, one per target',
      () async {
    h = await Harness.create(_portes(), dice: [6, 5]);
    h.controller.rollOpening();
    final g = h.game;
    for (final from in StepPicker.sources(g)) {
      expect(h.controller.selectSource(from), isTrue);
      final sel = h.view.selection;
      expect(sel.source, from);
      final legal = g.node.nextSteps.where((s) => s.from == from).toSet();
      expect(sel.highlights.map((x) => x.step).toSet(), legal);
      expect(sel.highlights.map((x) => x.to).toSet(),
          legal.map((s) => s.to).toSet());
    }
    await settle();
    expect(h.commands.whereType<ShowSelection>(), isNotEmpty);
  });

  test('selecting an unmovable pip clears the selection', () async {
    h = await Harness.create(_portes(), dice: [6, 5]);
    h.controller.rollOpening();
    h.controller.selectSource(24);
    expect(h.view.selection.source, 24);
    expect(h.controller.selectSource(3), isFalse);
    expect(h.view.selection.source, isNull);
    expect(h.view.selection.sources, isNotEmpty);
  });

  group('bear-off die disambiguation', () {
    Future<void> load(List<int> dice) async {
      h = await Harness.create(_portes(),
          prefs: {..._confirm, ..._noForced}, dice: dice);
      h.controller.debugLoad(oneToRoll(Variant.portes, _bearOff));
      h.controller.roll();
    }

    test('prefers the exact die on a tie', () async {
      await load([3, 5]);
      expect(h.controller.selectSource(3), isTrue);
      expect(h.view.selection.at(0)!.die, 3);
      expect(h.controller.stepTo(0), isTrue);
      expect(h.game.steps.single, const Step(3, 0, 3));
    });

    test('else the smaller overshooting die', () async {
      await load([6, 4]);
      h.controller.selectSource(3);
      expect(h.view.selection.at(0)!.die, 4);
      h.controller.stepTo(0);
      expect(h.game.steps.single, const Step(3, 0, 4));
    });
  });

  test('quickMove uses the active die, else the other; swapDice', () async {
    h = await Harness.create(_portes(), prefs: _confirm, dice: [6, 5]);
    h.controller.rollOpening();
    expect(h.view.selection.activeDie, 6);
    expect(h.controller.swapDice(), isTrue);
    expect(h.view.selection.activeDie, 5);
    expect(h.controller.quickMove(13), isTrue);
    expect(h.game.steps.single, const Step(13, 8, 5));
    // Only the 6 is left: the swap has nothing to swap to.
    expect(h.controller.swapDice(), isFalse);
    expect(h.controller.quickMove(24), isTrue);
    expect(h.game.steps.last, const Step(24, 18, 6));
  });

  test('undo back to the turn start', () async {
    h = await Harness.create(_portes(), prefs: _confirm, dice: [6, 5]);
    h.controller.rollOpening();
    final start = h.game.position;
    h.controller.quickMove(24);
    h.controller.quickMove(13);
    expect(h.view.awaitingConfirm, isTrue);
    expect(h.controller.undo(), isTrue);
    expect(h.controller.undo(), isTrue);
    expect(h.game.steps, isEmpty);
    expect(h.game.position, start);
    expect(h.controller.undo(), isFalse);
    await settle();
    expect(h.commands.whereType<AnimateSteps>().where((a) => a.undo),
        hasLength(2));
  });

  group('commit', () {
    test('auto-commits a complete play without moveConfirmation', () async {
      h = await Harness.create(_portes(), dice: [6, 5]);
      h.controller.rollOpening();
      h.controller.quickMove(24);
      h.controller.quickMove(13);
      expect(h.game.sideToMove, Side.two);
      expect(h.view.busy, isTrue); // the bot's turn began
    });

    test('waits for Confirm with moveConfirmation', () async {
      h = await Harness.create(_portes(), prefs: _confirm, dice: [6, 5]);
      h.controller.rollOpening();
      h.controller.quickMove(24);
      h.controller.quickMove(13);
      expect(h.game.phase, GamePhase.moving);
      expect(h.view.awaitingConfirm, isTrue);
      expect(h.controller.commit(), isTrue);
      expect(h.game.sideToMove, Side.two);
    });
  });

  group('autoplay', () {
    Future<void> load(Map<String, Object> prefs, Position p) async {
      h = await Harness.create(_portes(), prefs: prefs, dice: [6, 1]);
      h.backend.hold = true; // keep the bot's turn pending
      h.controller.debugLoad(oneToRoll(Variant.portes, p));
    }

    test('forced play is played and committed', () async {
      await load(const {}, _forced);
      h.controller.roll();
      expect(h.game.sideToMove, Side.two);
      await settle();
      final moves = h.commands.whereType<AnimateSteps>().toList();
      expect(moves.map((m) => m.steps.single.step),
          [const Step(25, 19, 6), const Step(19, 18, 1)]);
    });

    test('forced play waits for Confirm with moveConfirmation', () async {
      await load(_confirm, _forced);
      h.controller.roll();
      expect(h.game.steps, hasLength(2));
      expect(h.view.awaitingConfirm, isTrue);
      // Undo does not replay the forced play.
      h.controller.undo();
      expect(h.game.steps, hasLength(1));
    });

    test('forced autoplay off leaves the play to the player', () async {
      await load(_noForced, _forced);
      h.controller.roll();
      expect(h.game.steps, isEmpty);
      expect(h.view.selection.sources, {25});
    });

    test('auto-pass moves on with a notice', () async {
      await load(const {}, _closed);
      h.controller.roll();
      expect(h.view.notice, isA<TurnPassedNotice>());
      expect(h.view.passAck, isNull);
      expect(h.view.busy, isTrue);
    });

    test('auto-pass off waits for acknowledgePass', () async {
      await load({'tavli_auto_pass': false}, _closed);
      h.controller.roll();
      expect(h.view.passAck, Side.one);
      expect(h.view.busy, isFalse);
      expect(h.controller.acknowledgePass(), isTrue);
      expect(h.view.busy, isTrue);
    });

    test('auto-roll rolls unless a double is possible', () async {
      const v = Variant.shortNard;
      h = await Harness.create(
          MatchSetup(mode: MatchMode.vsBot, variant: v, cubeEnabled: true),
          prefs: {'tavli_auto_roll': true},
          dice: [6, 5]);
      final p = Position.forRules(v.rules);
      h.controller.debugLoad(oneToRoll(v, p, cubeEnabled: true));
      expect(h.game.phase, GamePhase.awaitingRoll); // may double
      h.controller.debugLoad(oneToRoll(v, p, cubeEnabled: false));
      expect(h.game.phase, GamePhase.moving);
    });

    test('auto-roll off waits for roll', () async {
      await load(const {}, _forced);
      expect(h.game.phase, GamePhase.awaitingRoll);
    });
  });

  test('resign concedes the A9 result and records it', () async {
    h = await Harness.create(_portes());
    expect(h.controller.resign(), isTrue);
    expect(h.view.match.isOver, isTrue);
    final r = h.view.match.history.single;
    expect(r.kind, ResultKind.resign);
    expect(r.winner, Side.two);
    expect(r.points, 2); // nothing borne off: a gammon
    final out = h.view.outcome as GoVictory;
    expect(out.result.winner, 2);
    expect(out.result.type, app.GameResultType.gammon);
    expect(out.extras['recorded'], isTrue);
    expect(h.recorder.calls, hasLength(1));
    expect(h.controller.resign(), isFalse);
  });
}

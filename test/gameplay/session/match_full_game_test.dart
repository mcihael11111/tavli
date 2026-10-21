import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/gameplay/session/board_command.dart';
import 'package:tavli/gameplay/session/match_setup.dart';
import 'package:tavli/gameplay/session/match_view.dart';
import 'package:tavli_core/tavli_core.dart';

import 'match_harness.dart';

/// Plays the human seat(s) through the controller's intents (the first
/// legal source and destination each time) until the first game ends.
/// Returns the number of driver iterations.
Future<int> playToGameEnd(Harness h) async {
  final c = h.controller;
  for (var i = 0; i < 20000; i++) {
    await settle();
    final v = h.view, g = v.game;
    if (g.phase == GamePhase.gameOver) return i;
    if (v.busy) continue;
    if (v.handoff != null) {
      expect(c.acknowledgeHandoff(), isTrue);
    } else if (v.passAck != null) {
      expect(c.acknowledgePass(), isTrue);
    } else {
      final ok = switch (g.phase) {
        GamePhase.opening => c.rollOpening(),
        GamePhase.awaitingRoll => c.roll(),
        GamePhase.cubeOffered => c.take(),
        GamePhase.moving when v.awaitingConfirm => c.commit(),
        GamePhase.moving => c.selectSource(v.selection.sources.first) &&
            c.stepTo(h.view.selection.highlights.first.to),
        GamePhase.gameOver => false,
      };
      expect(ok, isTrue, reason: 'intent in ${g.phase} at $i');
    }
  }
  fail('the game did not end');
}

/// Every Sync keeps 15 checkers a side.
void expectSaneCommands(List<BoardCommand> commands) {
  final syncs = commands.whereType<Sync>().toList();
  expect(syncs, isNotEmpty);
  for (final s in syncs) {
    final p = s.game.position;
    for (final side in Side.values) {
      expect(p.checkersOnBoard(side) + p.borneOff(side), 15);
    }
  }
  final moved = commands.whereType<AnimateSteps>().map((a) => a.side).toSet();
  expect(moved, Side.values.toSet(), reason: 'both sides moved');
}

void main() {
  for (final v in Variant.values) {
    test('${v.name}: a full game vs the bot (real decide) ends', () async {
      final h = await Harness.create(
          MatchSetup(mode: MatchMode.vsBot, variant: v),
          seed: v.index + 11);
      addTearDown(h.dispose);
      await playToGameEnd(h);
      await settle();
      final m = h.view.match;
      final result = m.history.last;
      expect(h.game.result, result);
      expectSaneCommands(h.commands);
      // Bot requests are all bot-side choosePlay / cube questions.
      expect(h.backend.requests.every((r) => r.side == MatchSetup.botSide),
          isTrue);
      if (m.isOver) {
        final out = h.view.outcome!;
        if (result.winner == null) {
          expect(out, isA<MatchDrawn>());
          expect(h.recorder.calls, isEmpty);
        } else {
          expect(out, isA<GoVictory>());
          expect(h.recorder.calls, hasLength(1));
          expect(h.recorder.calls.single.winner,
              result.winner == Side.one ? 1 : 2);
        }
      } else {
        // Tawla 31 plays on to its target.
        expect(v.rules.match.fixedTarget, isNotNull);
        expect(h.view.betweenGames, isTrue);
        expect(h.controller.nextGame(), isTrue);
        expect(h.view.match.gameIndex, 1);
      }
    }, timeout: const Timeout(Duration(minutes: 2)));
  }

  test('pass & play: a full game, flipping, recording nothing', () async {
    final h = await Harness.create(
        MatchSetup(mode: MatchMode.passAndPlay, variant: Variant.portes),
        seed: 5);
    addTearDown(h.dispose);
    await playToGameEnd(h);
    await settle();
    expect(h.backend.requests, isEmpty);
    expect(h.commands.whereType<FlipView>(), isNotEmpty);
    expectSaneCommands(h.commands);
    final out = h.view.outcome as GoVictory;
    expect(out.mode, MatchMode.passAndPlay);
    expect(out.extras['mode'], 'passPlay');
    expect(out.extras['recorded'], isTrue);
    expect(h.recorder.calls, isEmpty);
  });
}

/// Shared fakes for the MatchController tests: scripted dice, a fake bot
/// backend (scripted or real `Bot.decide` in-process), a fake recorder and
/// a container wired with them.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/ai/personality/bot_personality.dart';
import 'package:tavli/features/game/data/models/game_result.dart' as app;
import 'package:tavli/gameplay/services/gameplay_settings.dart';
import 'package:tavli/gameplay/session/board_command.dart';
import 'package:tavli/gameplay/session/bot_client.dart';
import 'package:tavli/gameplay/session/game_recorder.dart';
import 'package:tavli/gameplay/session/match_controller.dart';
import 'package:tavli/gameplay/session/match_setup.dart';
import 'package:tavli/gameplay/session/match_view.dart';
import 'package:tavli/shared/services/settings_service.dart';
import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';

/// Dice from [dice] in order (each `nextInt(6)` gives the next die - 1),
/// then from a seeded fallback.
class ScriptedRandom implements Random {
  ScriptedRandom([List<int> dice = const [], int seed = 1])
      : _dice = [...dice],
        _rest = Random(seed);
  final List<int> _dice;
  final Random _rest;

  void push(List<int> dice) => _dice.addAll(dice);

  @override
  int nextInt(int max) =>
      max == 6 && _dice.isNotEmpty ? _dice.removeAt(0) - 1 : _rest.nextInt(max);
  @override
  double nextDouble() => _rest.nextDouble();
  @override
  bool nextBool() => _rest.nextBool();
}

/// A bot backend answering with [answer] (default: real `Bot.decide`),
/// asynchronously; [hold] keeps every request pending until released.
class FakeBackend implements BotBackend {
  FakeBackend({this.answer = Bot.decide});
  BotReply Function(BotRequest) answer;
  final requests = <BotRequest>[];
  final cancelled = <int>[];
  bool hold = false;
  final _held = <(BotRequest, Completer<BotReply>)>[];

  void release() {
    hold = false;
    for (final (r, c) in [..._held]) {
      c.complete(answer(r));
    }
    _held.clear();
  }

  @override
  Future<BotReply> request(BotRequest r) {
    requests.add(r);
    if (hold) {
      final c = Completer<BotReply>();
      _held.add((r, c));
      return c.future;
    }
    return Future(() => answer(r));
  }

  @override
  void cancel(int id) => cancelled.add(id);
  @override
  Future<void> warm() async {}
  @override
  Future<void> dispose() async {}
}

class FakeRecorder implements GameRecorder {
  final calls = <app.GameResult>[];

  @override
  RecordOutcome recordVsBot({
    required app.GameResult result,
    required DifficultyLevel difficulty,
    required BotPersonality personality,
  }) {
    calls.add(result);
    return (coinsEarned: 7, unlocked: const []);
  }
}

/// One controller under test.
class Harness {
  Harness._(this.container, this.setup, this.backend, this.recorder, this.dice,
      this.settings);

  final ProviderContainer container;
  final MatchSetup setup;
  final FakeBackend backend;
  final FakeRecorder recorder;
  final ScriptedRandom dice;
  final GameplaySettings settings;
  final commands = <BoardCommand>[];

  /// Every notice, in order.
  final notices = <MatchNotice?>[];
  late final StreamSubscription<BoardCommand> _sub;
  late final ProviderSubscription<MatchView> _keep;

  static Future<Harness> create(
    MatchSetup setup, {
    Map<String, Object> prefs = const {},
    List<int> dice = const [],
    FakeBackend? backend,
    int seed = 1,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final settings = GameplaySettings(
        SettingsService.withPrefs(await SharedPreferences.getInstance()));
    final b = backend ?? FakeBackend();
    final recorder = FakeRecorder();
    final rng = ScriptedRandom(dice, seed);
    final container = ProviderContainer(overrides: [
      gameplaySettingsProvider.overrideWithValue(settings),
      botClientProvider.overrideWith((ref) {
        final c = BotClient(spawn: () async => b);
        ref.onDispose(c.dispose);
        return c;
      }),
      matchEnvironmentProvider.overrideWithValue(MatchEnvironment(
        delay: (_) async {},
        recorder: recorder,
        random: (_) => rng,
      )),
    ]);
    final h = Harness._(container, setup, b, recorder, rng, settings);
    h._keep = container.listen(matchControllerProvider(setup), (prev, next) {
      if (next.noticeSeq != prev?.noticeSeq) h.notices.add(next.notice);
    });
    h._sub = h.controller.commands.listen(h.commands.add);
    await settle();
    return h;
  }

  MatchController get controller =>
      container.read(matchControllerProvider(setup).notifier);
  MatchView get view => container.read(matchControllerProvider(setup));
  GameState get game => view.game;

  /// Drops the last listener so the auto-disposed controller goes, while
  /// the bot client stays.
  Future<void> closeController() async {
    await _sub.cancel();
    _keep.close();
    await container.pump();
    await settle();
  }

  Future<void> dispose() async {
    await _sub.cancel();
    container.dispose();
  }
}

/// Lets queued microtasks, futures and stream events run.
Future<void> settle() => pumpEventQueue(times: 40);

/// A match of [v] at [game].
MatchState matchOf(Variant v, GameState game, {bool? cubeEnabled}) =>
    MatchState(
      config: MatchConfig.single(v, cubeEnabled: cubeEnabled),
      scores: const {Side.one: 0, Side.two: 0},
      gameIndex: 0,
      game: game,
      history: const [],
      crawfordUsed: false,
      winner: null,
    );

/// Side one about to roll on [p] in [v].
MatchState oneToRoll(Variant v, Position p, {bool? cubeEnabled}) => matchOf(
    v,
    GameState.initial(v, starter: Side.one, cubeEnabled: cubeEnabled)
        .withPosition(p),
    cubeEnabled: cubeEnabled);

Position portes({
  required Map<int, int> one,
  required Map<int, int> two,
  int barOne = 0,
  int barTwo = 0,
}) =>
    Position.fromPips(
        one: one,
        two: two,
        barOne: barOne,
        barTwo: barTwo,
        direction: Direction.opposing);

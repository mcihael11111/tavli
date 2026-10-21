/// The match session (design §3): one controller per open game, the single
/// source of truth. Input intents are reduced by `tavli_core` on the UI
/// isolate (≤ 2 ms; Gul Bara cascade rolls inline since the Task 1 pruning
/// bound, design §5.4(a)); every bot decision goes through [BotClient].
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tavli/features/ai/pacing/turn_pacing.dart';
import 'package:tavli/features/game/data/models/game_result.dart' as app;
import 'package:tavli/features/profile/data/achievements.dart';
import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';

import '../adapters/result_adapter.dart';
import '../adapters/variant_adapter.dart';
import '../services/gameplay_settings.dart';
import 'board_command.dart';
import 'bot_client.dart';
import 'match_environment.dart';
import 'match_setup.dart';
import 'match_view.dart';
import 'step_picker.dart';
import 'ui_selection.dart';

export 'match_environment.dart';

part 'bot_seat.dart';
part 'match_flow.dart';
part 'teaching.dart';

final matchControllerProvider = NotifierProvider.autoDispose
    .family<MatchController, MatchView, MatchSetup>(MatchController.new);

class MatchController extends AutoDisposeFamilyNotifier<MatchView, MatchSetup> {
  late MatchSetup _setup;
  late GameplaySettings _settings;
  late BotClient _bot;
  late MatchEnvironment _env;
  late Random _rng;

  /// Bot request seeds, apart from the dice so they never shift a roll.
  late Random _seedRng;
  late TurnPacing _pacing;
  final _out = StreamController<BoardCommand>.broadcast(sync: true);

  /// Bumped by dispose and resign: a bot loop from an older epoch stops.
  int _epoch = 0;
  bool _disposed = false;
  bool _botRunning = false;
  bool _advancing = false;
  Completer<void>? _resumed;

  /// The moving phase forced autoplay already ran in (it runs once, so an
  /// undo does not replay it).
  Object? _forcedKey;

  /// Teaching: the game an analysis was last requested for.
  GameState? _analysisPending;

  /// The last game snapshot the board was sent (the subscribe-time Sync;
  /// mid bot turn, the position after the steps animated so far).
  late GameState _boardGame;

  /// Bot-turn events whose notices wait for the turn's animations.
  final _deferred = <MatchEvent>[];

  /// Consecutive bot iterations that made no progress; at
  /// [maxBotFailures] the loop stops with a [BotErrorNotice].
  int _botFailures = 0;
  bool _botStuck = false;

  late final Object _botLane = (this, 'bot');
  late final Object _teachLane = (this, 'teach');
  late final Object _teachEndLane = (this, 'teachEnd');

  @override
  MatchView build(MatchSetup arg) {
    _setup = arg;
    _settings = ref.read(gameplaySettingsProvider);
    _bot = ref.read(botClientProvider);
    _env = ref.read(matchEnvironmentProvider);
    _rng = _env.random(arg.seed);
    _seedRng = Random(arg.seed ?? Random.secure().nextInt(1 << 32));
    _pacing = TurnPacing.forBot(arg.difficulty, arg.personality);
    ref.onDispose(_dispose);
    if (arg.mode == MatchMode.vsBot) unawaited(_bot.warmUp());
    scheduleMicrotask(() {
      if (!_disposed) _advance();
    });
    final m = MatchState.initial(arg.config);
    _boardGame = m.game;
    return MatchView(
      match: m,
      selection: UiSelection.none,
      viewer: MatchSetup.humanSide,
      mode: arg.mode,
    );
  }

  MatchSetup get setup => _setup;

  // The state, for the part-file extensions (`state` is protected).
  MatchView get _view => state;
  set _view(MatchView v) => state = v;

  /// The board's command stream: a [Sync] of the last snapshot sent (so
  /// the animations that follow apply to it; mid bot turn that is the
  /// position after the steps animated so far) and the current
  /// selection, then every command in order. Closes on dispose.
  Stream<BoardCommand> get commands => Stream.multi((c) {
        c.add(Sync(_boardGame));
        if (_hasMarks(state.selection)) c.add(ShowSelection(state.selection));
        if (_disposed) {
          c.close();
          return;
        }
        final sub = _out.stream.listen(c.add, onDone: c.close);
        c.onCancel = sub.cancel;
      });

  // ---- Human intents. Each returns whether it was accepted; a rejected
  // intent changes nothing and never throws.

  /// Rolls the opening (G7); on a tie the game stays in the opening.
  bool rollOpening() {
    if (!_canAct() || state.game.phase != GamePhase.opening) return false;
    return _act(_rollOpening);
  }

  /// Rolls for the human to move.
  bool roll() {
    if (!_humanPhase(GamePhase.awaitingRoll)) return false;
    return _act(_roll);
  }

  /// Selects the checker on [pip]; a pip with no legal step clears the
  /// selection (and returns false).
  bool selectSource(int pip) {
    if (!_humanPhase(GamePhase.moving)) return false;
    final g = state.game;
    if (!StepPicker.sources(g).contains(pip)) {
      _setSelection(_baseSelection(g));
      return false;
    }
    _setSelection(UiSelection(
      source: pip,
      activeDie: state.selection.activeDie,
      highlights: StepPicker.highlights(g, pip, quality: _qualities()),
      sources: StepPicker.sources(g),
    ));
    _requestAnalysis();
    return true;
  }

  /// Clears the selection (tap on empty board).
  void clearSelection() {
    if (_disposed || state.selection.source == null) return;
    _setSelection(_baseSelection(state.game));
  }

  /// Steps the selected checker (or the one on [from]) to [to]; the die is
  /// disambiguated per design §4.3.
  bool stepTo(int to, {int? from}) {
    if (!_humanPhase(GamePhase.moving)) return false;
    final src = from ?? state.selection.source;
    if (src == null) return false;
    final g = state.game;
    final step = StepPicker.disambiguate(g.node, [
      for (final s in g.node.nextSteps)
        if (s.from == src && s.to == to) s,
    ]);
    if (step == null) return false;
    return _act(() => _human(GameMove(StepAction(step))));
  }

  /// Moves the checker on [from] by the active die, else the other die.
  bool quickMove(int from) {
    if (!_humanPhase(GamePhase.moving)) return false;
    final step =
        StepPicker.quickStep(state.game, from, state.selection.activeDie);
    if (step == null) return false;
    return _act(() => _human(GameMove(StepAction(step))));
  }

  /// Makes the next distinct die still to play the active one (not in a
  /// cascade, whose order is fixed).
  bool swapDice() {
    if (!_humanPhase(GamePhase.moving) || state.game.cascadeMode) {
      return false;
    }
    final left = StepPicker.remainingDice(state.game).toSet().toList();
    if (left.length < 2) return false;
    final i = left.indexOf(state.selection.activeDie ?? left.first);
    _setSelection(
        state.selection.copyWith(activeDie: left[(i + 1) % left.length]));
    return true;
  }

  /// Takes back the last step of the play.
  bool undo() {
    if (!_humanPhase(GamePhase.moving) || state.game.steps.isEmpty) {
      return false;
    }
    return _act(() => _human(const GameMove(UndoStep())));
  }

  /// Commits a complete play (the Confirm button).
  bool commit() {
    if (!_humanPhase(GamePhase.moving) || !state.game.node.isComplete) {
      return false;
    }
    return _act(_commitHuman);
  }

  /// Offers a double before rolling.
  bool offerDouble() {
    if (!_humanPhase(GamePhase.awaitingRoll) || !_canDouble(state.game)) {
      return false;
    }
    return _act(() => _human(const GameMove(OfferDouble())));
  }

  /// Accepts the opponent's double.
  bool take() =>
      _humanPhase(GamePhase.cubeOffered) &&
      _act(() => _human(const GameMove(Take())));

  /// Declines the opponent's double and loses the game.
  bool drop() =>
      _humanPhase(GamePhase.cubeOffered) &&
      _act(() => _human(const GameMove(Drop())));

  /// Resigns the current game (A9 scoring); a longer match goes on.
  /// Allowed while the bot thinks (its turn is abandoned) and while paused.
  bool resignGame() {
    if (_disposed || state.game.phase == GamePhase.gameOver) return false;
    final side = _resigner;
    _cancelBot();
    return _act(() => _apply(GameMove(Resign(side)), by: side));
  }

  /// Leaves the match: forfeits it (`ForfeitMatch`; an unfinished game is
  /// resigned, A9). The single "Resign" of a one-game match.
  bool leaveMatch() {
    if (_disposed || state.match.isOver) return false;
    final side = _resigner;
    _cancelBot();
    return _act(() => _apply(ForfeitMatch(side), by: side));
  }

  /// Who resigns: the human vs bot; in pass & play the viewer, who holds
  /// the device (also while a handoff is pending).
  Side get _resigner =>
      _setup.mode == MatchMode.vsBot ? MatchSetup.humanSide : state.viewer;

  /// Starts the next game of a longer match (Tawla 31).
  bool nextGame() {
    if (_disposed || !state.betweenGames) return false;
    _forcedKey = null;
    return _act(() => _apply(const NextGame()));
  }

  /// Pass & play: the device has been handed to [MatchView.handoff].
  bool acknowledgeHandoff() {
    final to = state.handoff;
    if (_disposed || to == null) return false;
    state = state.copyWith(viewer: to, handoff: null);
    _out.add(FlipView(to));
    _setSelection(_baseSelection(state.game));
    _requestAnalysis();
    _advance();
    return true;
  }

  /// Auto-pass off: the player has seen the passed turn.
  bool acknowledgePass() {
    if (_disposed || state.passAck == null) return false;
    state = state.copyWith(passAck: null);
    _advance();
    return true;
  }

  /// Opens the pause menu: the bot loop halts at its next await.
  void pause() {
    if (_disposed || state.paused) return;
    _resumed = Completer<void>();
    state = state.copyWith(paused: true);
  }

  void resume() {
    if (_disposed || !state.paused) return;
    state = state.copyWith(paused: false);
    _resumed?.complete();
    _resumed = null;
    _advance();
  }

  /// Replaces the match (scenario tests): a [Sync], then autoplay.
  @visibleForTesting
  void debugLoad(MatchState m) {
    _cancelBot();
    _forcedKey = null;
    _botFailures = 0;
    _botStuck = false;
    state = state.copyWith(match: m, lastAnalysis: null);
    _setSelection(_baseSelection(m.game));
    _sync(m.game);
    _advance();
  }

  // ---- Guards.

  bool _canAct() =>
      !_disposed &&
      !state.busy &&
      !state.paused &&
      state.handoff == null &&
      state.passAck == null &&
      state.outcome == null;

  /// The human may act in [phase]: it is that phase and a human's input.
  bool _humanPhase(GamePhase phase) {
    if (!_canAct() || state.game.phase != phase) return false;
    final side = _inputSide(state.game);
    return side != null && !_setup.isBot(side);
  }

  /// Runs an accepted intent, then the automatic follow-ups.
  bool _act(bool Function() intent) {
    final ok = intent();
    if (ok) _advance();
    return ok;
  }

  void _dispose() {
    _disposed = true;
    _epoch++;
    _bot
      ..cancelLane(_botLane)
      ..cancelLane(_teachLane)
      ..cancelLane(_teachEndLane);
    _resumed?.complete();
    _resumed = null;
    unawaited(_out.close());
  }
}

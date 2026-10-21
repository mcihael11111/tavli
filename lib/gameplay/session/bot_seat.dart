part of 'match_controller.dart';

// The bot's seat (design §3, bot turn): pacing beats, cube decisions, the
// roll, then the chosen play animated one step at a time. Every decision
// is a BotClient request; nothing searches on the UI isolate.

/// The nominal checker move at normal speed; the bot waits this (times
/// the speed setting) plus `interMoveSettle` between its steps.
const checkerMoveDuration = Duration(milliseconds: 130);

/// Bot iterations in a row without progress (a rejected action, say)
/// before the loop gives up rather than spin.
const maxBotFailures = 3;

extension _BotSeat on MatchController {
  void _startBot() {
    if (_botRunning || _disposed) return;
    _botRunning = true;
    _view = _view.copyWith(busy: true);
    _setSelection(UiSelection.none);
    unawaited(_botLoop(_epoch));
  }

  /// Abandons the bot's turn: its loop stops at its next await and its
  /// pending request is cancelled.
  void _cancelBot() {
    _epoch++;
    _bot.cancelLane(_botLane);
    _deferred.clear();
    if (_botRunning) {
      _botRunning = false;
      if (!_disposed) _view = _view.copyWith(busy: false);
    }
  }

  /// Waits [d], then while paused; false once the loop must stop.
  Future<bool> _beat(int epoch, Duration d) async {
    if (d > Duration.zero) await _env.delay(d);
    while (!_disposed && epoch == _epoch && _view.paused) {
      await (_resumed ??= Completer<void>()).future;
    }
    return !_disposed && epoch == _epoch;
  }

  Future<void> _botLoop(int epoch) async {
    try {
      while (await _beat(epoch, Duration.zero)) {
        final g = _view.game;
        final actor = _inputSide(g);
        if (_view.match.isOver || actor == null || !_setup.isBot(actor)) {
          break;
        }
        final ok = switch (g.phase) {
          GamePhase.awaitingRoll => await _botRoll(epoch),
          GamePhase.moving => await _botPlay(epoch),
          GamePhase.cubeOffered => await _botAnswer(epoch),
          GamePhase.opening || GamePhase.gameOver => false,
        };
        final alive = !_disposed && epoch == _epoch;
        if (alive && !identical(_view.game, g)) {
          _botFailures = 0;
        } else if (alive && !ok) {
          _botFailures++;
        }
        if (!ok) break;
      }
    } finally {
      if (epoch == _epoch && !_disposed) {
        _botRunning = false;
        _view = _view.copyWith(busy: false);
        _flushBotTurn();
        _advance();
      }
    }
  }

  /// A fresh request seed from the match's random source.
  int _seed() => _seedRng.nextInt(1 << 30);

  Future<BotReply?> _ask(int epoch, BotRequestKind kind) async {
    final g = _view.game;
    final reply = await _bot.requestOn(
      _botLane,
      (id, supersedes) => BotRequests.fromState(g,
          kind: kind,
          level: _setup.level,
          id: id,
          seed: _seed(),
          supersedes: supersedes),
    );
    if (!await _beat(epoch, Duration.zero)) return null;
    if (reply is ErrorReply) debugPrint('MatchController: bot $reply');
    return reply;
  }

  /// Thinking beat, an optional double, then the roll.
  Future<bool> _botRoll(int epoch) async {
    if (!await _beat(epoch, _pacing.thinkingBeat)) return false;
    if (_canDouble(_view.game)) {
      final r = await _ask(epoch, BotRequestKind.offerDouble);
      if (r == null) return false;
      if (r is DecisionReply && r.yes) {
        return _apply(const GameMove(OfferDouble()), by: MatchSetup.botSide);
      }
    }
    final side = _view.game.sideToMove;
    _out.add(Rattle(side, _pacing.diceRattle));
    if (!await _beat(epoch, _pacing.diceRattle)) return false;
    final d = DiceRoll.random(_rng);
    if (!_apply(GameMove(RollDice(d.d1, d.d2)), by: MatchSetup.botSide)) {
      return false;
    }
    return _beat(epoch, _pacing.dicePostRollBreather);
  }

  /// Chooses a play, submits it, then animates its steps one by one.
  Future<bool> _botPlay(int epoch) async {
    final g = _view.game;
    final r = await _ask(epoch, BotRequestKind.choosePlay);
    if (r == null) return false;
    final steps = r is PlayReply && r.steps.isNotEmpty ? r.steps : _anyPlay(g);
    if (!identical(_view.game, g)) return false;
    final u = _applyGet(GameMove(SubmitPlay(steps)),
            by: MatchSetup.botSide, animate: false) ??
        _applyGet(GameMove(SubmitPlay(_anyPlay(g))),
            by: MatchSetup.botSide, animate: false);
    if (u == null) return false;
    final settle = checkerMoveDuration * _settings.animSpeed.durationFactor +
        _pacing.interMoveSettle;
    final next = u.state.game;
    var board = g;
    for (final e in u.events) {
      if (e is InGame && e.event is CheckerMoved) {
        final moved = e.event as CheckerMoved;
        // The board's snapshot advances with each animated step, so a
        // board subscribing now continues from here.
        if (reduce(board, StepAction(moved.step.step))
            case GameUpdate(:final state)) {
          _boardGame = board = state;
        }
        _out.add(AnimateSteps([moved.step], moved.side));
        if (!await _beat(epoch, settle)) return false;
      } else if (e is InGame) {
        _emit([e], next);
      }
    }
    _sync(_view.game);
    return _beat(epoch, _pacing.finalSettle);
  }

  /// Takes or drops the human's double.
  Future<bool> _botAnswer(int epoch) async {
    if (!await _beat(epoch, _pacing.thinkingBeat)) return false;
    final r = await _ask(epoch, BotRequestKind.takeDouble);
    if (r == null) return false;
    final take = r is! DecisionReply || r.yes;
    return _apply(GameMove(take ? const Take() : const Drop()),
        by: MatchSetup.botSide);
  }

  /// A legal play without search (the first path through the tree), for
  /// when the bot errs.
  static List<Step> _anyPlay(GameState g) {
    final steps = <Step>[];
    var n = g.tree.walk(g.steps)!;
    while (!n.isComplete) {
      final s = n.nextSteps.first;
      steps.add(s);
      n = n.child(s)!;
    }
    return steps;
  }
}

part of 'match_controller.dart';

// Reducing actions, board commands, autoplay and the match end.

bool _hasMarks(UiSelection s) =>
    s.source != null || s.highlights.isNotEmpty || s.sources.isNotEmpty;

/// The side whose input the game waits for; null in the opening, where
/// either side (vs bot: the human) rolls.
Side? _inputSide(GameState g) => switch (g.phase) {
      GamePhase.awaitingRoll || GamePhase.moving => g.sideToMove,
      GamePhase.cubeOffered => g.cube.offeredBy?.opponent,
      GamePhase.opening || GamePhase.gameOver => null,
    };

/// Whether the side to move may double now (the core decides).
bool _canDouble(GameState g) =>
    g.phase == GamePhase.awaitingRoll &&
    reduce(g, const OfferDouble()) is GameUpdate;

extension _Flow on MatchController {
  /// Applies [a]; false if the core rejects it (nothing changes). With
  /// [animate] the events go to the board now, else the caller sends them.
  bool _apply(MatchAction a, {bool animate = true}) =>
      _applyGet(a, animate: animate) != null;

  MatchUpdate? _applyGet(MatchAction a, {bool animate = true}) {
    final r = reduceMatch(_view.match, a);
    if (r is! MatchUpdate) return null;
    final g = r.state.game;
    if (animate) _emit(r.events, g);
    _view = _view.copyWith(match: r.state, lastAnalysis: null);
    _setSelection(_baseSelection(g));
    if (animate) _out.add(Sync(g));
    _notices(r.events);
    _requestAnalysis();
    return r;
  }

  /// The board commands for [events], ending at [g].
  void _emit(List<MatchEvent> events, GameState g) {
    for (final m in events) {
      if (m is! InGame) continue;
      switch (m.event) {
        case OpeningRolled(:final dieOne, :final dieTwo):
          _out.add(DiceLanded(null, [dieOne, dieTwo],
              toPlay: g.dice, opening: true));
        case DiceRolled(:final side, :final dice):
          _out.add(DiceLanded(side, dice,
              toPlay: g.sideToMove == side ? g.dice : const [],
              cascade: g.cascadeMode));
        case CheckerMoved(:final side, :final step):
          _out.add(AnimateSteps([step], side));
        case StepUndone(:final side, :final step):
          _out.add(AnimateSteps([step], side, undo: true));
        case CubeOffered() || CubeTaken() || CubeDropped():
          _out.add(CubeChanged(g.cube));
        default:
          break;
      }
    }
  }

  void _notices(List<MatchEvent> events) {
    for (final m in events) {
      if (m is! InGame) continue;
      switch (m.event) {
        case TurnPassed(:final side, :final dice):
          final ack = !_setup.isBot(side) && !_settings.autoPass;
          _view = _view.copyWith(
              notice: TurnPassedNotice(side, dice), passAck: ack ? side : null);
        case RemainderPassed(:final to, :final dice):
          _view = _view.copyWith(notice: RemainderNotice(to, dice));
        case CubeTaken(:final by):
          _view = _view.copyWith(notice: CubeAnswerNotice(by, took: true));
        case CubeDropped(:final by):
          _view = _view.copyWith(notice: CubeAnswerNotice(by, took: false));
        default:
          break;
      }
    }
  }

  /// No source selected: the movable sources and the active die during a
  /// human's moving phase, else nothing.
  UiSelection _baseSelection(GameState g) {
    final side = g.sideToMove;
    if (g.phase != GamePhase.moving || side == null || _setup.isBot(side)) {
      return UiSelection.none;
    }
    final left = StepPicker.remainingDice(g);
    final die = _view.selection.activeDie;
    return UiSelection(
      activeDie: die != null && left.contains(die) && !g.cascadeMode
          ? die
          : StepPicker.defaultActiveDie(g),
      sources: StepPicker.sources(g),
    );
  }

  void _setSelection(UiSelection s) {
    if (s == _view.selection) return;
    _view = _view.copyWith(selection: s);
    _out.add(_hasMarks(s) ? ShowSelection(s) : const ClearSelection());
  }

  bool _rollOpening() {
    _out.add(Rattle(null, _pacing.diceRattle));
    final d = DiceRoll.random(_rng);
    return _apply(GameMove(RollOpening(d.d1, d.d2)));
  }

  bool _roll() {
    _out.add(Rattle(_view.game.sideToMove, _pacing.diceRattle));
    final d = DiceRoll.random(_rng);
    return _apply(GameMove(RollDice(d.d1, d.d2)));
  }

  /// Commits the human's complete play, asking for teaching feedback first.
  bool _commitHuman() {
    _requestTurnFeedback();
    return _apply(const GameMove(CommitPlay()));
  }

  /// Runs automatic actions until the game waits for input: human
  /// autoplay per the settings, the bot's turn, the pass & play handoff,
  /// the match end.
  void _advance() {
    if (_disposed || _advancing) return;
    _advancing = true;
    try {
      // Each pass applies one action; ties in an auto-rolled opening are
      // the only repeat, so the bound is never reached in practice.
      for (var i = 0; i < 64 && _autoStep(); i++) {}
    } finally {
      _advancing = false;
    }
  }

  /// One automatic action; true if one was applied.
  bool _autoStep() {
    final v = _view, m = v.match, g = m.game;
    if (m.isOver) {
      _finish();
      return false;
    }
    if (g.phase == GamePhase.gameOver || v.paused || v.passAck != null) {
      return false;
    }
    final actor = _inputSide(g);
    if (actor != null && _setup.isBot(actor)) {
      _startBot();
      return false;
    }
    if (_setup.mode == MatchMode.passAndPlay &&
        actor != null &&
        actor != v.viewer) {
      if (v.handoff != actor) {
        _view = _view.copyWith(handoff: actor);
        _setSelection(UiSelection.none);
      }
      return false;
    }
    if (v.handoff != null || v.busy) return false;
    return _humanAutoplay(g);
  }

  bool _humanAutoplay(GameState g) {
    switch (g.phase) {
      case GamePhase.opening:
        return _settings.autoRoll && _rollOpening();
      case GamePhase.awaitingRoll:
        return _settings.autoRoll && !_canDouble(g) && _roll();
      case GamePhase.moving:
        final key =
            (_view.match.gameIndex, g.rollIndex, g.sideToMove, g.remainderTurn);
        if (_settings.autoplayForced && _forcedKey != key) {
          _forcedKey = key;
          final steps = StepPicker.forcedSteps(g);
          if (steps != null) {
            for (final s in steps) {
              if (!_apply(GameMove(StepAction(s)))) break;
              if (_view.game.phase != GamePhase.moving) break;
            }
            return true;
          }
        }
        if (g.node.isComplete && _settings.autoCommit) return _commitHuman();
        return false;
      case GamePhase.cubeOffered || GamePhase.gameOver:
        return false;
    }
  }

  /// Once the match is over: vs bot, record and go to the victory screen;
  /// pass & play records nothing; a draw shows a draw outcome.
  void _finish() {
    if (_view.outcome != null) return;
    _cancelBot();
    final m = _view.match;
    final last = m.history.last;
    final winner = m.winner;
    if (winner == null) {
      _view = _view.copyWith(outcome: MatchDrawn(last));
      return;
    }
    final mapped = appResultOf(last);
    final result = app.GameResult(
      winner: winner == Side.one ? 1 : 2,
      type: mapped?.type ?? app.GameResultType.single,
      cubeValue: last.cubeValue,
    );
    var coins = 0;
    Achievement? first;
    if (_setup.mode == MatchMode.vsBot) {
      final r = _env.recorder.recordVsBot(
        result: result,
        difficulty: _setup.difficulty,
        personality: _setup.personality,
      );
      coins = r.coinsEarned;
      first = r.unlocked.firstOrNull;
    }
    _view = _view.copyWith(
      outcome: GoVictory(
        result: result,
        difficulty: _setup.difficulty,
        variant: _setup.variant.app,
        mode: _setup.mode,
        coinsEarned: coins,
        achievement: first,
      ),
    );
  }
}

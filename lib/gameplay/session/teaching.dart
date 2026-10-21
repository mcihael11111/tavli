part of 'match_controller.dart';

// Teaching (`easyWithHelp`, design §3): an analysis of the human's current
// steps, each superseding the last, feeds highlight qualities; the
// complete play's equity loss becomes the end-of-turn feedback.

extension _Teaching on MatchController {
  bool get _teachingTurn {
    final g = _view.game;
    return _setup.teaching &&
        !_botRunning &&
        g.phase == GamePhase.moving &&
        !_setup.isBot(g.sideToMove!);
  }

  /// The qualities of the next steps, when the analysis is of the current
  /// steps.
  Map<Step, StepQuality>? _qualities() => _view.lastAnalysis?.nextStepQuality;

  /// Asks for an analysis of the current steps unless one is in hand.
  /// The reply is used only while the game is unchanged.
  void _requestAnalysis() {
    if (!_teachingTurn) {
      // Nothing to teach now: drop a stale request.
      if (_analysisPending != null) {
        _analysisPending = null;
        _bot.cancelLane(_teachLane);
      }
      return;
    }
    if (_view.lastAnalysis != null) return;
    final g = _view.game;
    if (identical(_analysisPending, g)) return;
    _analysisPending = g;
    unawaited(_bot
        .requestOn(
      _teachLane,
      (id, supersedes) => BotRequests.fromState(g,
          kind: BotRequestKind.analyze,
          level: _setup.level,
          id: id,
          seed: _seed(),
          supersedes: supersedes),
    )
        .then((r) {
      if (_disposed) return;
      if (r is! AnalysisReply) {
        // Failed or cancelled: a later call may ask again.
        if (identical(_analysisPending, g)) _analysisPending = null;
        return;
      }
      if (!identical(_view.game, g)) return;
      _view = _view.copyWith(lastAnalysis: r.analysis);
      final sel = _view.selection;
      final source = sel.source;
      if (source != null) {
        _setSelection(sel.copyWith(
            highlights: StepPicker.highlights(g, source,
                quality: r.analysis.nextStepQuality)));
      }
    }));
  }

  /// Before committing a complete play: asks how much it lost, for the
  /// end-of-turn feedback.
  void _requestTurnFeedback() {
    if (!_teachingTurn) return;
    final g = _view.game;
    if (!g.node.isComplete) return;
    // The analysis in hand is of this complete play: no new request.
    final known = _view.lastAnalysis?.playEquityLoss;
    if (known != null) {
      _notify(TeachingFeedback(known));
      return;
    }
    unawaited(_bot
        .requestOn(
      _teachEndLane,
      (id, supersedes) => BotRequests.fromState(g,
          kind: BotRequestKind.analyze,
          level: _setup.level,
          id: id,
          seed: _seed(),
          supersedes: supersedes),
    )
        .then((r) {
      if (_disposed || r is! AnalysisReply) return;
      final loss = r.analysis.playEquityLoss;
      if (loss == null) return;
      _notify(TeachingFeedback(loss));
    }));
  }
}

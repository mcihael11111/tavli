part of 'match_controller.dart';

// Intent guards, the board snapshot, scenario loading and disposal.

extension _Guards on MatchController {
  /// A new board subscriber: the board's orientation (pass & play), the
  /// last snapshot sent and the current selection, then every command.
  void _subscribe(MultiStreamController<BoardCommand> c) {
    if (_disposed) {
      c
        ..add(Sync(_boardGame))
        ..close();
      return;
    }
    if (_setup.mode == MatchMode.passAndPlay) c.add(FlipView(_view.viewer));
    c.add(Sync(_boardGame));
    if (_hasMarks(_view.selection)) c.add(ShowSelection(_view.selection));
    final sub = _out.stream.listen(c.add, onDone: c.close);
    c.onCancel = sub.cancel;
  }

  /// Who resigns: the human vs bot; in pass & play the viewer, who holds
  /// the device (also while a handoff is pending).
  Side get _resigner =>
      _setup.mode == MatchMode.vsBot ? MatchSetup.humanSide : _view.viewer;

  bool _canAct() =>
      !_disposed &&
      !_view.busy &&
      !_view.paused &&
      _view.handoff == null &&
      _view.passAck == null &&
      _view.outcome == null;

  /// The human may act in [phase]: it is that phase and a human's input.
  bool _humanPhase(GamePhase phase) {
    if (!_canAct() || _view.game.phase != phase) return false;
    final side = _inputSide(_view.game);
    return side != null && !_setup.isBot(side);
  }

  /// Runs an accepted intent, then the automatic follow-ups.
  bool _act(bool Function() intent) {
    final ok = intent();
    if (ok) _advance();
    return ok;
  }

  void _load(MatchState m) {
    _cancelBot();
    _forcedKey = null;
    _botFailures = 0;
    _botStuck = false;
    _view = _view.copyWith(match: m, lastAnalysis: null);
    _setSelection(_baseSelection(m.game));
    _sync(m.game);
    _advance();
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

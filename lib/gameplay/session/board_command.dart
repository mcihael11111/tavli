/// What the controller tells the board (design §2 data flow). The board
/// (plan Task 8) consumes these in order from `MatchController.commands`
/// and never reads controller state in `build()`.
library;

import 'package:tavli_core/tavli_core.dart';

import 'ui_selection.dart';

sealed class BoardCommand {
  const BoardCommand();
}

/// The authoritative game snapshot: position (after the steps taken),
/// dice and steps (used dice), cube. Sent first to every subscriber and
/// after every accepted action, following that action's animations; the
/// board settles to it once its queue reaches it (a no-op when the
/// animations already got there).
final class Sync extends BoardCommand {
  const Sync(this.game);
  final GameState game;

  @override
  String toString() => 'Sync(${game.phase.name}, ${game.sideToMove?.name})';
}

/// [side] played [steps] in order (with their hit, pin and bear-off
/// effects); with [undo], they are taken back, last first. A bot play is
/// sent one step at a time, `interMoveSettle` apart.
final class AnimateSteps extends BoardCommand {
  AnimateSteps(List<AppliedStep> steps, this.side, {this.undo = false})
      : steps = List.unmodifiable(steps);
  final List<AppliedStep> steps;
  final Side side;
  final bool undo;

  @override
  String toString() =>
      'AnimateSteps(${side.name}${undo ? ' undo' : ''}, $steps)';
}

/// Show [selection]: the selected checker, destination highlights (with
/// teaching qualities) and the active die.
final class ShowSelection extends BoardCommand {
  const ShowSelection(this.selection);
  final UiSelection selection;

  @override
  String toString() => 'ShowSelection($selection)';
}

/// Remove every selection mark and highlight.
final class ClearSelection extends BoardCommand {
  const ClearSelection();

  @override
  String toString() => 'ClearSelection()';
}

/// The dice tumble for [duration] before a roll lands ([DiceLanded]).
final class Rattle extends BoardCommand {
  const Rattle(this.side, this.duration);

  /// The side rolling; null for the opening roll.
  final Side? side;
  final Duration duration;

  @override
  String toString() => 'Rattle(${side?.name}, $duration)';
}

/// The dice landed. [opening]: the opening roll ([dice] is side one's die
/// then side two's). Otherwise [side] rolled [dice] (two values) and
/// [toPlay] holds what is to be played: `[d, d, d, d]` for doubles, a Gul
/// Bara cascade queue when [cascade].
final class DiceLanded extends BoardCommand {
  DiceLanded(this.side, List<int> dice,
      {List<int> toPlay = const [], this.cascade = false, this.opening = false})
      : dice = List.unmodifiable(dice),
        toPlay = List.unmodifiable(toPlay);
  final Side? side;
  final List<int> dice;
  final List<int> toPlay;
  final bool cascade;
  final bool opening;

  @override
  String toString() => 'DiceLanded(${side?.name}, $dice'
      '${opening ? ' opening' : ''}${cascade ? ' cascade $toPlay' : ''})';
}

/// The cube changed (offered, taken or dropped).
final class CubeChanged extends BoardCommand {
  const CubeChanged(this.cube);
  final CubeState cube;

  @override
  String toString() => 'CubeChanged($cube)';
}

/// Pass & play: draw the board from [viewer]'s side (the `ViewTransform`
/// flip). vs bot the viewer is always the human and this is never sent.
final class FlipView extends BoardCommand {
  const FlipView(this.viewer);
  final Side viewer;

  @override
  String toString() => 'FlipView(${viewer.name})';
}

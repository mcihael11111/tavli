import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../features/game/data/models/board_state.dart';
import '../features/game/data/models/move.dart';
import 'components/board_component.dart';
import 'components/checker_component.dart';
import 'components/dice_component.dart';
import 'components/highlight_component.dart';
export 'components/highlight_component.dart' show MoveQuality;

/// Main Flame game class for the Tavli board.
///
/// Renders the board, checkers, dice, and handles tap interactions.
/// Communicates with Flutter via callbacks.
class TavliGame extends FlameGame with TapCallbacks, HasCollisionDetection {
  BoardState _boardState;

  /// Callback when player taps a checker.
  final void Function(int pointIndex)? onCheckerTapped;

  /// Callback when player taps a destination highlight.
  final void Function(int toPoint)? onDestinationTapped;

  /// Callback when player taps the dice area to roll.
  final void Function()? onDiceRollRequested;

  late BoardComponent _boardComponent;
  final List<CheckerComponent> _checkers = [];
  final List<HighlightComponent> _highlights = [];
  DiceComponent? _diceComponent;

  /// Board set index (1, 2, or 3) for visual customization.
  int _boardSetIndex = 1;

  /// When true, the board is rendered from player 2's perspective
  /// (point indices are mirrored via 23 - index).
  final bool flipped;

  /// Checker set index (1, 2, or 3) for color customization.
  final int _checkerSetIndex;

  TavliGame({
    required BoardState boardState,
    this.onCheckerTapped,
    this.onDestinationTapped,
    this.onDiceRollRequested,
    int boardSet = 1,
    int checkerSet = 1,
    this.flipped = false,
  })  : _boardState = boardState,
        _boardSetIndex = boardSet,
        _checkerSetIndex = checkerSet;

  /// Map a logical point index to a visual point index.
  /// When flipped, mirrors the board so player 2 sees their home board
  /// in the same position player 1 normally does.
  int _visualPoint(int logicalPoint) {
    if (!flipped || logicalPoint < 0) return logicalPoint;
    return 23 - logicalPoint;
  }


  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _boardComponent = BoardComponent(
      gameSize: size,
    );
    _boardComponent.setBoardSet(_boardSetIndex);
    add(_boardComponent);

    _rebuildCheckers();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      _boardComponent.onResize(size);
      _rebuildCheckers();
    }
  }

  /// Update the board state from Flutter (via Riverpod).
  void updateBoardState(BoardState newState) {
    _boardState = newState;
    if (isLoaded) {
      _rebuildCheckers();
    }
  }

  /// Change the board set at runtime.
  void setBoardSet(int setIndex) {
    _boardSetIndex = setIndex;
    if (isLoaded) {
      _boardComponent.setBoardSet(setIndex);
    }
  }

  /// Show legal move highlights for a selected checker.
  /// [moveQualities] maps toPoint → MoveQuality for teaching mode.
  void showHighlights(List<Move> moves, {Map<int, MoveQuality>? moveQualities}) {
    _clearHighlights();
    for (final move in moves) {
      final quality = moveQualities?[move.toPoint];
      final visualIdx = _visualPoint(move.toPoint);
      final highlight = HighlightComponent(
        pointIndex: visualIdx,
        dieValue: move.dieUsed,
        isHit: move.isHit,
        boardLayout: _boardComponent.layout,
        quality: quality,
        onTap: () => onDestinationTapped?.call(move.toPoint), // logical index
      );
      _highlights.add(highlight);
      add(highlight);
    }
  }

  /// Clear all highlights.
  void clearHighlights() => _clearHighlights();

  /// Show dice with values.
  void showDice(int die1, int die2, List<int> remaining) {
    _diceComponent?.removeFromParent();
    _diceComponent = DiceComponent(
      die1: die1,
      die2: die2,
      remaining: remaining,
      boardLayout: _boardComponent.layout,
      onTap: () => onDiceRollRequested?.call(),
    );
    add(_diceComponent!);
  }

  /// Show roll prompt (no dice values yet).
  void showRollPrompt() {
    _diceComponent?.removeFromParent();
    _diceComponent = DiceComponent(
      die1: 0,
      die2: 0,
      remaining: const [],
      boardLayout: _boardComponent.layout,
      onTap: () => onDiceRollRequested?.call(),
    );
    add(_diceComponent!);
  }

  /// Hide dice display.
  void hideDice() {
    _diceComponent?.removeFromParent();
    _diceComponent = null;
  }

  // ── Private ────────────────────────────────────────────────

  void _clearHighlights() {
    for (final h in _highlights) {
      h.removeFromParent();
    }
    _highlights.clear();
  }

  void _rebuildCheckers() {
    // Remove old checkers.
    for (final c in _checkers) {
      c.removeFromParent();
    }
    _checkers.clear();

    final layout = _boardComponent.layout;

    // Place checkers on points.
    for (int i = 0; i < 24; i++) {
      final count = _boardState.points[i];
      if (count == 0) continue;

      final player = count > 0 ? 1 : 2;
      final absCount = count.abs();
      final visualIdx = _visualPoint(i);

      for (int j = 0; j < absCount; j++) {
        final checker = CheckerComponent(
          pointIndex: visualIdx,
          stackPosition: j,
          player: player,
          boardLayout: layout,
          onTap: () => onCheckerTapped?.call(i), // callback uses logical index
          checkerSet: _checkerSetIndex,
        );
        _checkers.add(checker);
        add(checker);
      }
    }

    // Place bar checkers.
    for (int j = 0; j < _boardState.bar1; j++) {
      final checker = CheckerComponent(
        pointIndex: -1,
        stackPosition: j,
        player: 1,
        boardLayout: layout,
        onTap: () => onCheckerTapped?.call(-1),
        checkerSet: _checkerSetIndex,
      );
      _checkers.add(checker);
      add(checker);
    }
    for (int j = 0; j < _boardState.bar2; j++) {
      final checker = CheckerComponent(
        pointIndex: -1,
        stackPosition: j,
        player: 2,
        boardLayout: layout,
        onTap: () => onCheckerTapped?.call(-1),
        checkerSet: _checkerSetIndex,
      );
      _checkers.add(checker);
      add(checker);
    }

    // Place borne-off indicators.
    for (int j = 0; j < _boardState.borneOff1; j++) {
      final checker = CheckerComponent(
        pointIndex: -2,
        stackPosition: j,
        player: 1,
        boardLayout: layout,
        checkerSet: _checkerSetIndex,
      );
      _checkers.add(checker);
      add(checker);
    }
    for (int j = 0; j < _boardState.borneOff2; j++) {
      final checker = CheckerComponent(
        pointIndex: -2,
        stackPosition: j,
        player: 2,
        boardLayout: layout,
        checkerSet: _checkerSetIndex,
      );
      _checkers.add(checker);
      add(checker);
    }
  }
}

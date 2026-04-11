import 'dart:async';

import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../features/game/data/models/board_state.dart';
import '../features/game/data/models/move.dart';
import 'components/board_component.dart';
import 'components/checker_component.dart';
import 'components/dice_component.dart';
import 'components/highlight_component.dart';
import 'sprite_manager.dart';
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
  final SpriteManager _spriteManager = SpriteManager();
  CheckerSprites? _checkerSprites;
  DiceSprites? _diceSprites;
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

  /// Dice set index (1, 2, or 3) for color customization.
  final int _diceSetIndex;

  TavliGame({
    required BoardState boardState,
    this.onCheckerTapped,
    this.onDestinationTapped,
    this.onDiceRollRequested,
    int boardSet = 1,
    int checkerSet = 1,
    int diceSet = 1,
    this.flipped = false,
  })  : _boardState = boardState,
        _boardSetIndex = boardSet,
        _checkerSetIndex = checkerSet,
        _diceSetIndex = diceSet;

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

    // Load sprite assets for the active sets.
    await _loadSprites();

    _rebuildCheckers();
  }

  /// Load all sprite assets for the current set indices.
  Future<void> _loadSprites() async {
    await _boardComponent.loadSprites(_spriteManager, _boardSetIndex);
    _checkerSprites = await _spriteManager.loadCheckerSprites(_checkerSetIndex);
    _diceSprites = await _spriteManager.loadDiceSprites(_diceSetIndex);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      _boardComponent.onResize(size);
      _rebuildCheckers();
    }
  }

  /// Whether a checker animation is currently playing.
  bool _animating = false;
  bool get isAnimating => _animating;

  /// Instantly sync the board state without animation.
  /// Used by the build() method for non-move state changes (undo, turn transitions).
  void syncBoardState(BoardState newState) {
    if (_animating) return; // don't interrupt an animation
    if (_boardState == newState) return; // no change
    _boardState = newState;
    if (isLoaded) {
      _rebuildCheckers();
    }
  }

  /// Update the board state with animation (for moves).
  /// Returns a Future that completes when all checker animations finish.
  Future<void> updateBoardState(BoardState newState) async {
    final oldState = _boardState;
    _boardState = newState;
    if (isLoaded) {
      await _diffAndAnimateCheckers(oldState, newState);
    }
  }

  /// Change the board set at runtime.
  void setBoardSet(int setIndex) {
    _boardSetIndex = setIndex;
    if (isLoaded) {
      _boardComponent.setBoardSet(setIndex);
      _boardComponent.loadSprites(_spriteManager, setIndex);
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
      diceSet: _diceSetIndex,
    )..sprites = _diceSprites;
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
      diceSet: _diceSetIndex,
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

  /// Diff old vs new board state and animate checkers that moved.
  /// Each updateBoardState call represents exactly one move (one checker changes position).
  Future<void> _diffAndAnimateCheckers(BoardState oldState, BoardState newState) async {
    // Early exit if nothing changed.
    if (oldState == newState) return;

    _animating = true;
    try {
    final layout = _boardComponent.layout;
    final animations = <Future<void>>[];

    // Build a snapshot of checker counts per location for old and new states.
    // Locations: points 0-23 (per player), bar (-1), borne-off (-2).
    for (final playerNum in [1, 2]) {
      final oldCounts = <int, int>{}; // location → count
      final newCounts = <int, int>{};

      // Points 0-23.
      for (int i = 0; i < 24; i++) {
        final oldVal = oldState.points[i];
        final newVal = newState.points[i];
        oldCounts[i] = playerNum == 1 ? (oldVal > 0 ? oldVal : 0) : (oldVal < 0 ? -oldVal : 0);
        newCounts[i] = playerNum == 1 ? (newVal > 0 ? newVal : 0) : (newVal < 0 ? -newVal : 0);
      }
      // Bar.
      oldCounts[-1] = playerNum == 1 ? oldState.bar1 : oldState.bar2;
      newCounts[-1] = playerNum == 1 ? newState.bar1 : newState.bar2;
      // Borne off.
      oldCounts[-2] = playerNum == 1 ? oldState.borneOff1 : oldState.borneOff2;
      newCounts[-2] = playerNum == 1 ? newState.borneOff1 : newState.borneOff2;

      // Find sources (lost checkers) and destinations (gained checkers).
      final sources = <int>[]; // point indices that lost checkers
      final destinations = <int>[]; // point indices that gained checkers

      for (final loc in {...oldCounts.keys, ...newCounts.keys}) {
        final oldC = oldCounts[loc] ?? 0;
        final newC = newCounts[loc] ?? 0;
        final diff = newC - oldC;
        if (diff < 0) {
          // Lost checkers at this location.
          for (int k = 0; k < -diff; k++) {
            sources.add(loc);
          }
        } else if (diff > 0) {
          // Gained checkers at this location.
          for (int k = 0; k < diff; k++) {
            destinations.add(loc);
          }
        }
      }

      // Pair sources with destinations and animate.
      final pairCount = sources.length < destinations.length ? sources.length : destinations.length;
      for (int k = 0; k < pairCount; k++) {
        final fromLoc = sources[k];
        final toLoc = destinations[k];

        // Find the top checker on the source location for this player.
        final checker = _findTopChecker(fromLoc, playerNum);
        if (checker == null) continue;

        // Compute new visual position.
        final visualTo = _visualPoint(toLoc);
        final newStackPos = newCounts[toLoc]! - 1; // top of the destination stack
        final targetPos = layout.checkerPosition(visualTo, newStackPos, playerNum);

        // Update the checker's logical state.
        checker.updateLogicalPosition(
          newPointIndex: visualTo,
          newStackPosition: newStackPos,
          newPlayer: playerNum,
        );

        // Update tap callback to use the new logical point.
        if (toLoc >= 0) {
          checker.onTap = () => onCheckerTapped?.call(toLoc);
        } else if (toLoc == -1) {
          checker.onTap = () => onCheckerTapped?.call(-1);
        } else {
          checker.onTap = null; // borne-off checkers aren't tappable
        }

        // Animate to new position.
        animations.add(checker.animateMoveTo(targetPos));
      }

      // Handle stack position changes for checkers that stayed on the same point
      // but shifted position (e.g., a checker below was removed).
      for (int i = 0; i < 24; i++) {
        final oldC = oldCounts[i] ?? 0;
        final newC = newCounts[i] ?? 0;
        if (oldC == newC && newC > 0) continue; // unchanged
        if (newC == 0) continue;

        // Reassign stack positions for remaining checkers on this point.
        final visualIdx = _visualPoint(i);
        final checkersOnPoint = _checkers
            .where((c) => c.pointIndex == visualIdx && c.player == playerNum)
            .toList();

        for (int j = 0; j < checkersOnPoint.length; j++) {
          final c = checkersOnPoint[j];
          if (c.stackPosition != j) {
            c.stackPosition = j;
            final newPos = layout.checkerPosition(visualIdx, j, playerNum);
            if (c.position.distanceTo(newPos) > 1) {
              animations.add(c.animateMoveTo(newPos, duration: 0.2));
            }
          }
        }
      }
    }

    if (animations.isNotEmpty) {
      await Future.wait(animations);
    }
    } finally {
      _animating = false;
    }
  }

  /// Find the topmost checker on a given logical point for a given player.
  CheckerComponent? _findTopChecker(int logicalPoint, int player) {
    final visualIdx = _visualPoint(logicalPoint);
    CheckerComponent? top;
    for (final c in _checkers) {
      if (c.pointIndex == visualIdx && c.player == player) {
        if (top == null || c.stackPosition > top.stackPosition) {
          top = c;
        }
      }
    }
    return top;
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
        )..sprites = _checkerSprites;
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
      )..sprites = _checkerSprites;
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
      )..sprites = _checkerSprites;
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
      )..sprites = _checkerSprites;
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
      )..sprites = _checkerSprites;
      _checkers.add(checker);
      add(checker);
    }
  }
}

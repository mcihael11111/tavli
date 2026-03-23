import 'package:flame/game.dart';

/// Computes positions for all board elements based on screen size.
///
/// The board is laid out in landscape with the bar dividing left/right halves.
/// Player 1 (bottom) bears off to the right, player 2 (top) bears off to the left.
class BoardLayout {
  final Vector2 gameSize;

  late final double boardWidth;
  late final double boardHeight;
  late final double boardLeft;
  late final double boardTop;
  late final double frameThickness;
  late final double barWidth;
  late final double pointWidth;
  late final double pointHeight;
  late final double checkerRadius;
  late final double bearOffWidth;

  BoardLayout(this.gameSize) {
    _compute();
  }

  void _compute() {
    // Board fills most of the screen with margins.
    final margin = gameSize.x * 0.02;
    boardWidth = gameSize.x - margin * 2;
    boardHeight = gameSize.y * 0.78;
    boardLeft = margin;
    boardTop = gameSize.y * 0.08;

    frameThickness = boardWidth * 0.025;
    barWidth = boardWidth * 0.04;
    bearOffWidth = boardWidth * 0.05;

    // Playing area: boardWidth - 2*frame - bar - 2*bearOff
    final playingWidth =
        boardWidth - frameThickness * 2 - barWidth - bearOffWidth * 2;
    pointWidth = playingWidth / 12;
    pointHeight = boardHeight * 0.40;

    checkerRadius = pointWidth * 0.45;
  }

  /// Get the screen position for a point's base (where checkers stack from).
  /// [pointIndex] is 0-23.
  /// [isTop] = true for points on the top half of the board (13-24 for P1 view).
  Vector2 pointBasePosition(int pointIndex) {
    final isTop = pointIndex >= 12; // Points 12-23 are on top
    final displayIndex = isTop ? (23 - pointIndex) : pointIndex;

    // Which half: 0-5 = right half, 6-11 = left half.
    final isRightHalf = displayIndex < 6;
    final indexInHalf = isRightHalf ? (5 - displayIndex) : (displayIndex - 6);

    double x;
    if (isRightHalf) {
      // Right of bar.
      x = boardLeft +
          frameThickness +
          6 * pointWidth +
          barWidth +
          indexInHalf * pointWidth +
          pointWidth / 2;
    } else {
      // Left of bar.
      x = boardLeft +
          frameThickness +
          bearOffWidth +
          (5 - indexInHalf) * pointWidth +
          pointWidth / 2;
    }

    final y = isTop ? boardTop + frameThickness : boardTop + boardHeight - frameThickness;

    return Vector2(x, y);
  }

  /// Get the position for a checker stacked at [stackPosition] on [pointIndex].
  Vector2 checkerPosition(int pointIndex, int stackPosition, int player) {
    // Bar position.
    if (pointIndex == -1) {
      return _barPosition(stackPosition, player);
    }
    // Borne off position.
    if (pointIndex == -2) {
      return _bearOffPosition(stackPosition, player);
    }

    final base = pointBasePosition(pointIndex);
    final isTop = pointIndex >= 12;

    // Stack direction: top points stack downward, bottom points stack upward.
    final stackOffset = checkerRadius * 2.0 * 0.85; // slight overlap
    const maxVisible = 5;
    final effectiveStack = stackPosition < maxVisible ? stackPosition : maxVisible;

    double y;
    if (isTop) {
      y = base.y + effectiveStack * stackOffset + checkerRadius;
    } else {
      y = base.y - effectiveStack * stackOffset - checkerRadius;
    }

    return Vector2(base.x, y);
  }

  Vector2 _barPosition(int stackPosition, int player) {
    final x = boardLeft + boardWidth / 2;
    final centerY = boardTop + boardHeight / 2;

    if (player == 1) {
      // P1 bar checkers below center.
      return Vector2(x, centerY + checkerRadius * 2 * (stackPosition + 1));
    } else {
      // P2 bar checkers above center.
      return Vector2(x, centerY - checkerRadius * 2 * (stackPosition + 1));
    }
  }

  Vector2 _bearOffPosition(int stackPosition, int player) {
    if (player == 1) {
      // P1 bears off to the right tray.
      final x = boardLeft + boardWidth - frameThickness - bearOffWidth / 2;
      final y = boardTop + boardHeight - frameThickness - stackPosition * checkerRadius * 0.4;
      return Vector2(x, y);
    } else {
      // P2 bears off to the left tray.
      final x = boardLeft + frameThickness + bearOffWidth / 2;
      final y = boardTop + frameThickness + stackPosition * checkerRadius * 0.4;
      return Vector2(x, y);
    }
  }

  /// Get the dice roll area center position.
  Vector2 get diceAreaCenter {
    return Vector2(
      boardLeft + boardWidth * 0.75,
      boardTop + boardHeight / 2,
    );
  }

  /// Get the point triangle polygon vertices for rendering.
  List<Vector2> pointTriangle(int pointIndex) {
    final base = pointBasePosition(pointIndex);
    final isTop = pointIndex >= 12;
    final halfWidth = pointWidth / 2;

    if (isTop) {
      // Triangle points downward from top.
      return [
        Vector2(base.x - halfWidth, base.y),
        Vector2(base.x + halfWidth, base.y),
        Vector2(base.x, base.y + pointHeight),
      ];
    } else {
      // Triangle points upward from bottom.
      return [
        Vector2(base.x - halfWidth, base.y),
        Vector2(base.x + halfWidth, base.y),
        Vector2(base.x, base.y - pointHeight),
      ];
    }
  }
}

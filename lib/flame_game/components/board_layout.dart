import 'package:flame/game.dart';

/// Computes positions for all board elements based on screen size.
///
/// The board is laid out in landscape with the bar dividing left/right halves.
/// Player 1 (bottom) bears off to the right, player 2 (top) bears off to the left.
///
/// When [useSpriteLayout] is true, proportions are calibrated to match the
/// designer's board sprite (set 1: Mahogany & Olive). These values may need
/// fine-tuning through visual testing.
class BoardLayout {
  final Vector2 gameSize;
  final bool useSpriteLayout;

  late final double boardWidth;
  late final double boardHeight;
  late final double boardLeft;
  late final double boardTop;
  late final double frameThickness;
  /// Vertical inset from the top board edge to the top-row triangle base.
  /// Typically larger than [frameThickness] on sprite layouts because the
  /// sprite has both a wooden frame AND an inset lip before the playing felt.
  late final double trianglePadTop;
  /// Vertical inset from the bottom board edge to the bottom-row triangle base.
  /// Kept symmetric with [trianglePadTop] in practice; separated so the sprite
  /// can be recalibrated independently if the art changes.
  late final double trianglePadBottom;
  late final double barWidth;
  late final double pointWidth;
  late final double pointHeight;
  late final double checkerRadius;
  late final double bearOffWidth;
  /// Fraction of checker diameter that consecutive stacked checkers are offset by.
  /// Lower = more overlap. 1.0 = flush, no overlap.
  late final double stackOverlapFactor;
  /// Small vertical nudge applied to the stack anchor so the first checker's
  /// visible edge sits on the painted triangle base (accounts for the sprite's
  /// base shadow). Positive = pushes stack toward triangle tip.
  late final double stackAnchorNudge;

  BoardLayout(this.gameSize, {this.useSpriteLayout = false}) {
    _compute();
  }

  void _compute() {
    // Board fills most of the screen with margins.
    final margin = gameSize.x * 0.02;
    boardWidth = gameSize.x - margin * 2;
    boardHeight = gameSize.y * 0.78;
    boardLeft = margin;
    boardTop = gameSize.y * 0.08;

    if (useSpriteLayout) {
      // Calibrated against the designer's board sprite (set 1: Mahogany &
      // Olive). Measured from the exported PNG: frame ≈ 4.4%, bar ≈ 4%,
      // bear-off tray ≈ 5.2% of board width.
      //
      // Horizontal (frameThickness) and vertical (trianglePad*) insets are
      // NOT equal in the sprite. Horizontally the triangle edge sits at
      // frameThickness + bearOffWidth from the board edge. Vertically the
      // triangle base sits at trianglePadTop (~6% of board HEIGHT) from the
      // top edge — the sprite has both a wooden frame AND an inset felt lip
      // before the triangles begin.
      //
      // If the sprite is re-exported these values must be re-measured;
      // otherwise checkers and move-hint overlays will drift off the painted
      // triangles again.
      frameThickness = boardWidth * 0.044;
      barWidth = boardWidth * 0.040;
      bearOffWidth = boardWidth * 0.052;
      trianglePadTop = boardHeight * 0.060;
      trianglePadBottom = boardHeight * 0.060;
      // 25% overlap — reads as a real stacked checker pile, not floating discs.
      stackOverlapFactor = 0.75;
      // Painted triangles on the sprite have a ~2 px base shadow; nudge the
      // stack so the first checker visually rests on the triangle's edge.
      stackAnchorNudge = 2.0;
    } else {
      frameThickness = boardWidth * 0.025;
      barWidth = boardWidth * 0.04;
      bearOffWidth = boardWidth * 0.05;
      // Procedural board draws triangles right at the frame inner edge, so
      // the vertical inset matches frameThickness exactly.
      trianglePadTop = frameThickness;
      trianglePadBottom = frameThickness;
      // Legacy defaults for the procedural fallback — preserves existing look.
      stackOverlapFactor = 0.85;
      stackAnchorNudge = 0.0;
    }

    // Playing area: boardWidth - 2*frame - bar - 2*bearOff
    final playingWidth =
        boardWidth - frameThickness * 2 - barWidth - bearOffWidth * 2;
    pointWidth = playingWidth / 12;

    // Triangle length. Sprite mode: measured from the exported PNG at ~30%
    // of board height — the sprite's painted triangles do NOT extend as far
    // as the procedural ones. Using 0.40 made move-hint overlay triangles
    // visibly longer than the painted triangles underneath.
    pointHeight = boardHeight * (useSpriteLayout ? 0.315 : 0.40);

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
          bearOffWidth +
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

    // Vertical inset uses trianglePadTop/Bottom (not frameThickness) because
    // the sprite layout has a larger vertical inset than horizontal.
    final y = isTop
        ? boardTop + trianglePadTop
        : boardTop + boardHeight - trianglePadBottom;

    return Vector2(x, y);
  }

  /// Get the position for a checker stacked at [stackPosition] on [pointIndex].
  Vector2 checkerPosition(int pointIndex, int stackPosition, int player, {int? totalOnPoint}) {
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
    final normalOffset = checkerRadius * 2.0 * stackOverlapFactor;
    const maxVisible = 7;

    // Compress stacking when more than maxVisible checkers on a point.
    final total = totalOnPoint ?? (stackPosition + 1);
    final double stackOffset;
    if (total <= maxVisible) {
      stackOffset = normalOffset;
    } else {
      // Fit all checkers in the space of maxVisible.
      stackOffset = normalOffset * maxVisible / total;
    }

    // Per-row anchor nudge (see stackAnchorNudge doc).
    final anchorShift = isTop ? stackAnchorNudge : -stackAnchorNudge;

    double y;
    if (isTop) {
      y = base.y + stackPosition * stackOffset + checkerRadius + anchorShift;
    } else {
      y = base.y - stackPosition * stackOffset - checkerRadius + anchorShift;
    }

    return Vector2(base.x, y);
  }

  Vector2 _barPosition(int stackPosition, int player) {
    final x = boardLeft + boardWidth / 2;
    final centerY = boardTop + boardHeight / 2;

    // Initial clearance: one full diameter, so the center diamond/hinge inlay
    // stays visible. Subsequent checkers stack at the same overlap factor as
    // point stacks so a 4-checker bar pile looks consistent with a point pile.
    final initialClearance = checkerRadius * 2;
    final stackStep = checkerRadius * 2.0 * stackOverlapFactor;

    if (player == 1) {
      // P1 bar checkers below center.
      return Vector2(x, centerY + initialClearance + stackPosition * stackStep);
    } else {
      // P2 bar checkers above center.
      return Vector2(x, centerY - initialClearance - stackPosition * stackStep);
    }
  }

  Vector2 _bearOffPosition(int stackPosition, int player) {
    if (player == 1) {
      // P1 bears off to the right tray. Y anchors to the bottom triangle line
      // so borne-off checkers line up with the row they came from.
      final x = boardLeft + boardWidth - frameThickness - bearOffWidth / 2;
      final y = boardTop + boardHeight - trianglePadBottom - stackPosition * checkerRadius * 0.4;
      return Vector2(x, y);
    } else {
      // P2 bears off to the left tray.
      final x = boardLeft + frameThickness + bearOffWidth / 2;
      final y = boardTop + trianglePadTop + stackPosition * checkerRadius * 0.4;
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

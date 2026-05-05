import 'package:flame/game.dart';

/// Computes positions for all board elements based on screen size.
///
/// Three rendering modes:
/// - Procedural ([useSpriteLayout]=false, [useBakedBearOff]=false): canvas
///   primitives draw the board, frame, and bear-off trays at runtime.
/// - Plain sprite ([useSpriteLayout]=true): designer-provided PNG of just the
///   playing surface; bear-off trays still rendered procedurally on the side.
/// - Baked bear-off ([useBakedBearOff]=true): designer-provided PNG that
///   includes the playing surface AND a top + bottom bear-off strip in one
///   image. Used by the 2026 art update — see 2102 × 2374 board PNGs.
///
/// In baked mode the image is fit-to-screen with aspect preserved (BoxFit
/// .contain semantics) and centered. Triangle / bar / bear-off positions are
/// derived from the embedded board region inside the image, not the screen.
class BoardLayout {
  final Vector2 gameSize;
  final bool useSpriteLayout;
  final bool useBakedBearOff;

  /// Full rendered image rect (board + bear-off strips when baked).
  late final double imageWidth;
  late final double imageHeight;
  late final double imageLeft;
  late final double imageTop;

  /// Playing region rect (the inner board portion of the image — without the
  /// bear-off strips). Equal to image rect for non-baked modes.
  late final double boardWidth;
  late final double boardHeight;
  late final double boardLeft;
  late final double boardTop;

  late final double frameThickness;
  /// Vertical inset from the top board edge to the top-row triangle base.
  late final double trianglePadTop;
  /// Vertical inset from the bottom board edge to the bottom-row triangle base.
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

  /// Height of the pre-board frame region (between image edge and the playing
  /// surface). Includes both the red bear-off tray AND the wood frame around
  /// it. Used for vertical layout math.
  late final double bearOffStripHeight;

  /// Vertical center of the top red bear-off tray, in screen coords.
  /// This is the *visible* red region — narrower than [bearOffStripHeight].
  late final double topTrayCenterY;
  /// Vertical center of the bottom red bear-off tray.
  late final double bottomTrayCenterY;
  /// Visible height of one red bear-off tray (excludes surrounding wood frame).
  late final double trayInnerHeight;

  /// Y of the painted triangle base for top-row points (12-23). In baked mode
  /// this is measured directly from the PNG so checkers anchor to actual
  /// paint, not derived from boardHeight × inset (which drifted 2-3 px).
  late final double topTriangleBaseY;
  /// Y of the painted triangle base for bottom-row points (0-11).
  late final double bottomTriangleBaseY;
  /// Y midpoint between the two painted triangle bases — the visual centre
  /// of the bar gap. Used to anchor the bar pile in baked mode.
  late final double barCenterY;

  /// Fraction of a checker PNG's bounding box that is the actual visible disc
  /// (the rest is transparent padding for the baked drop shadow). Render code
  /// scales the sprite by 1/this so the visible disc fills the desired logical
  /// diameter. Measured against the 2026 art set: visible disc = 222/400 px.
  static const double checkerVisibleRatio = 0.555;

  /// Same idea for dice. Visible die face = 136/400 px in the 2026 art set.
  static const double diceVisibleRatio = 0.34;

  /// Minimum tap target radius in logical pixels. Bumped above the 22 pt
  /// (44 pt diameter) Material floor → 26 pt (52 pt diameter) after user
  /// reported rage-clicks on cramped phone widths. Applied via a hitbox
  /// larger than the visible disc when the natural checker is smaller.
  static const double minTapRadius = 26.0;

  // ─── Baked-bearoff PNG calibration (set 1, 2, 3 share template) ───
  // Source PNG: 2102 × 2374 px. Layout reference points (measured 2026-04-23
  // by sampling the red strip with PIL):
  //   - Top wood frame above red tray: y 0..42 px
  //   - Top RED bear-off tray: y 43..180 px (138 px tall)
  //   - Top wood frame below red tray: y 181..212 px
  //   - Board region: y 213..2161 px (1949 px tall)
  //   - Bottom wood frame above red tray: y 2162..2201 px
  //   - Bottom RED bear-off tray: y 2202..2339 px (138 px tall)
  //   - Bottom wood frame: y 2340..2373 px
  // Within the board region, calibration matches the original sprite art:
  //   - Frame inner edge: 65/2102 = 3.1%
  //   - Center bar: 66/2102 = 3.1%
  //   - Top/bottom frame inset to first triangle: 55/1949 = 2.82%
  //   - Triangle height: ~625/1949 = 32%
  // If the source PNG is re-exported these values must be re-measured.
  static const double _bakedAspect = 2102.0 / 2374.0;
  static const double _bakedTopStripFrac = 213.0 / 2374.0;
  static const double _bakedBoardFrac = 1949.0 / 2374.0;
  // Red tray (the visible red rectangle the player's bear-off checkers sit in).
  static const double _bakedTopTrayCenterFrac = (43.0 + 180.0) / 2 / 2374.0;
  static const double _bakedBottomTrayCenterFrac = (2202.0 + 2339.0) / 2 / 2374.0;
  static const double _bakedTrayHeightFrac = 138.0 / 2374.0;
  // Triangle paint coordinates re-measured 2026-04-23 by sampling the actual
  // PNG (PIL row-by-row triangle-pixel scan). Earlier code derived these from
  // boardHeight + a 2.8% inset, which drifted 2-3 px off the painted base and
  // ~10 px short of the actual triangle height. Anchor checkers directly to
  // the measured paint to eliminate the per-stack drift the player saw.
  static const double _bakedTopBaseFrac = 268.0 / 2374.0;
  static const double _bakedBottomBaseFrac = 2103.0 / 2374.0;
  static const double _bakedTriangleHeightFrac = (933.0 - 258.0) / 2374.0;
  // X-position anchors measured from PNG paint (NOT derived from
  // frame/bar/12*pw arithmetic, which was off near the bar and asymmetric
  // frame). Leftmost = bottom-row point 11 centre; rightmost = point 0
  // centre; in-half spacing = average within-half centre-to-centre.
  static const double _bakedLeftmostCenterFrac = 161.5 / 2102.0;
  static const double _bakedRightmostCenterFrac = 1974.5 / 2102.0;
  // Painted spacing differs between halves — designer hand-rendered each row.
  // Left-half avg = 154 px, right-half avg = 162 px (excluding bar-edge
  // outliers from the y=2092 sweep). Treating both as 153 made inner-right
  // points (especially point 5) drift right by up to 45 px (QA 2026-04-23).
  static const double _bakedInHalfSpacingLeftFrac = 154.0 / 2102.0;
  static const double _bakedInHalfSpacingRightFrac = 158.0 / 2102.0;
  /// Used for disc sizing and stack offset — pick the smaller of the two
  /// half-spacings so disc width never exceeds either painted column.
  static const double _bakedInHalfSpacingFrac = _bakedInHalfSpacingLeftFrac;

  BoardLayout(
    this.gameSize, {
    this.useSpriteLayout = false,
    this.useBakedBearOff = false,
  }) {
    _compute();
  }

  void _compute() {
    if (useBakedBearOff) {
      _computeBaked();
    } else {
      _computeLegacy();
    }

    // Playing area: boardWidth - 2*frame - bar - 2*bearOff
    final playingWidth =
        boardWidth - frameThickness * 2 - barWidth - bearOffWidth * 2;
    // Baked mode uses the painted in-half spacing (the bar gap is wider than
    // 12 even slots imply, so dividing playingWidth/12 under-estimates).
    pointWidth = useBakedBearOff
        ? imageWidth * _bakedInHalfSpacingFrac
        : playingWidth / 12;

    // Triangle length. Baked: derived from measured paint (top tip 933 −
    // top base 258 = 675 px on a 2374-tall image). Sprite: 32%. Procedural: 40%.
    if (useBakedBearOff) {
      pointHeight = imageHeight * _bakedTriangleHeightFrac;
    } else {
      pointHeight = boardHeight * (useSpriteLayout ? 0.32 : 0.40);
    }

    // 0.46 instead of 0.50: leaves a small horizontal margin so a stack of
    // checkers never visually touches the next triangle's column under
    // sub-pixel rounding (was a source of "overlap" reports).
    checkerRadius = pointWidth * 0.46;
  }

  /// Baked-bearoff layout: fit the full PNG to the screen with aspect kept,
  /// then derive the inner board region from fixed fractions.
  void _computeBaked() {
    final screenAspect = gameSize.x / gameSize.y;
    if (screenAspect < _bakedAspect) {
      // Screen narrower than image (portrait phone) — fit width.
      imageWidth = gameSize.x;
      imageHeight = imageWidth / _bakedAspect;
    } else {
      // Screen wider than image (landscape phone, tablet) — fit height.
      imageHeight = gameSize.y;
      imageWidth = imageHeight * _bakedAspect;
    }
    imageLeft = (gameSize.x - imageWidth) / 2;
    imageTop = (gameSize.y - imageHeight) / 2;

    bearOffStripHeight = imageHeight * _bakedTopStripFrac;
    topTrayCenterY = imageTop + imageHeight * _bakedTopTrayCenterFrac;
    bottomTrayCenterY = imageTop + imageHeight * _bakedBottomTrayCenterFrac;
    trayInnerHeight = imageHeight * _bakedTrayHeightFrac;
    boardLeft = imageLeft;
    boardWidth = imageWidth;
    boardTop = imageTop + bearOffStripHeight;
    boardHeight = imageHeight * _bakedBoardFrac;

    // Anchor checkers directly to the measured paint coordinates, not to
    // derived insets — that's what eliminates the 2-3 px drift the player
    // saw and the 10 px short-stack anchored at boardHeight × 0.32.
    topTriangleBaseY = imageTop + imageHeight * _bakedTopBaseFrac;
    bottomTriangleBaseY = imageTop + imageHeight * _bakedBottomBaseFrac;
    barCenterY = (topTriangleBaseY + bottomTriangleBaseY) / 2;

    frameThickness = boardWidth * 0.031;
    barWidth = boardWidth * 0.031;
    bearOffWidth = 0;
    // trianglePad/stackAnchorNudge kept for API compat; baked mode uses the
    // measured triangleBase Y values directly in pointBasePosition.
    trianglePadTop = topTriangleBaseY - boardTop;
    trianglePadBottom = (boardTop + boardHeight) - bottomTriangleBaseY;
    stackOverlapFactor = 0.75;
    stackAnchorNudge = 0.0; // measured base already includes any base shadow
  }

  /// Legacy layout: full-screen board with 2% margin; either procedural or
  /// plain sprite (no baked bear-off).
  void _computeLegacy() {
    final margin = gameSize.x * 0.02;
    imageLeft = margin;
    imageTop = gameSize.y * 0.08;
    imageWidth = gameSize.x - margin * 2;
    imageHeight = gameSize.y * 0.78;
    boardLeft = imageLeft;
    boardTop = imageTop;
    boardWidth = imageWidth;
    boardHeight = imageHeight;
    bearOffStripHeight = 0;
    topTrayCenterY = imageTop;
    bottomTrayCenterY = imageTop + imageHeight;
    trayInnerHeight = 0;

    if (useSpriteLayout) {
      frameThickness = boardWidth * 0.031;
      barWidth = boardWidth * 0.031;
      bearOffWidth = boardWidth * 0.005;
      trianglePadTop = boardHeight * 0.028;
      trianglePadBottom = boardHeight * 0.028;
      stackOverlapFactor = 0.75;
      stackAnchorNudge = 2.0;
    } else {
      frameThickness = boardWidth * 0.025;
      barWidth = boardWidth * 0.04;
      bearOffWidth = boardWidth * 0.05;
      trianglePadTop = frameThickness;
      trianglePadBottom = frameThickness;
      stackOverlapFactor = 0.85;
      stackAnchorNudge = 0.0;
    }

    // Legacy modes derive triangle bases from boardTop/Height + pad, which
    // is the same indirection the baked path used to do. Keep that shape
    // for back-compat and fill the new measured fields from it.
    topTriangleBaseY = boardTop + trianglePadTop;
    bottomTriangleBaseY = boardTop + boardHeight - trianglePadBottom;
    barCenterY = boardTop + boardHeight / 2;
  }

  /// Get the screen position for a point's base (where checkers stack from).
  /// [pointIndex] is 0-23.
  Vector2 pointBasePosition(int pointIndex) {
    final isTop = pointIndex >= 12;
    final displayIndex = isTop ? (23 - pointIndex) : pointIndex;

    // Which half: 0-5 = right half, 6-11 = left half.
    final isRightHalf = displayIndex < 6;

    double x;
    if (useBakedBearOff) {
      // Anchor X positions to measured PNG paint, not to derived
      // frame+bar+12·pointWidth arithmetic. The painted bar is wider than
      // 3.1% and the left/right frames are asymmetric, both of which made
      // the math drift up to 47 px at the inner-half-edge points.
      // Per-half spacing because the artist's row painting isn't symmetric.
      if (isRightHalf) {
        final spacing = imageWidth * _bakedInHalfSpacingRightFrac;
        // displayIndex 0 = rightmost (anchored), 5 = leftmost in right half.
        x = imageLeft +
            imageWidth * _bakedRightmostCenterFrac -
            displayIndex * spacing;
      } else {
        final spacing = imageWidth * _bakedInHalfSpacingLeftFrac;
        // displayIndex 11 = leftmost (anchored), 6 = rightmost in left half.
        x = imageLeft +
            imageWidth * _bakedLeftmostCenterFrac +
            (11 - displayIndex) * spacing;
      }
    } else {
      final indexInHalf = isRightHalf ? (5 - displayIndex) : (displayIndex - 6);
      if (isRightHalf) {
        x = boardLeft +
            frameThickness +
            bearOffWidth +
            6 * pointWidth +
            barWidth +
            indexInHalf * pointWidth +
            pointWidth / 2;
      } else {
        x = boardLeft +
            frameThickness +
            bearOffWidth +
            (5 - indexInHalf) * pointWidth +
            pointWidth / 2;
      }
    }

    // Use the measured triangle-base Y values directly. In baked mode these
    // were sampled from the PNG paint, so checkers anchor exactly on the
    // painted triangle base instead of derived-via-pad math.
    final y = isTop ? topTriangleBaseY : bottomTriangleBaseY;

    return Vector2(x, y);
  }

  /// Get the position for a checker stacked at [stackPosition] on [pointIndex].
  Vector2 checkerPosition(int pointIndex, int stackPosition, int player, {int? totalOnPoint}) {
    if (pointIndex == -1) return _barPosition(stackPosition, player);
    if (pointIndex == -2) return _bearOffPosition(stackPosition, player);

    final base = pointBasePosition(pointIndex);
    final isTop = pointIndex >= 12;

    final normalOffset = checkerRadius * 2.0 * stackOverlapFactor;
    const maxVisible = 7;

    final total = totalOnPoint ?? (stackPosition + 1);
    final double stackOffset;
    if (total <= maxVisible) {
      stackOffset = normalOffset;
    } else {
      stackOffset = normalOffset * maxVisible / total;
    }

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
    // barCenterY is the painted-paint midpoint between the top and bottom
    // triangle bases, NOT boardTop + boardHeight/2 — those differed by
    // ~5 px in the baked PNG (the bar's brass hinge sits visually higher
    // than the geometric centre of the board region).
    final initialClearance = checkerRadius * 2;
    final stackStep = checkerRadius * 2.0 * stackOverlapFactor;

    if (player == 1) {
      return Vector2(x, barCenterY + initialClearance + stackPosition * stackStep);
    } else {
      return Vector2(x, barCenterY - initialClearance - stackPosition * stackStep);
    }
  }

  Vector2 _bearOffPosition(int stackPosition, int player) {
    if (useBakedBearOff) return _bakedBearOffPosition(stackPosition, player);

    if (player == 1) {
      // P1 bears off to the right tray.
      final x = boardLeft + boardWidth - frameThickness - bearOffWidth / 2;
      final y = boardTop + boardHeight - trianglePadBottom -
          stackPosition * checkerRadius * 0.4;
      return Vector2(x, y);
    } else {
      final x = boardLeft + frameThickness + bearOffWidth / 2;
      final y = boardTop + trianglePadTop +
          stackPosition * checkerRadius * 0.4;
      return Vector2(x, y);
    }
  }

  /// Bear-off positions for baked-image mode. Checkers stack inside the RED
  /// tray (P1: bottom tray, P2: top tray), rendered as side-on vertical slivers
  /// using the `_vertical` checker sprites — i.e. how a real bear-off pile
  /// looks: pieces standing on edge in a row across the tray.
  ///
  /// Stack grows outward from the tray center so 15 borne-off checkers read
  /// cleanly across the strip. Each sliver is roughly trayInnerHeight / 2.6
  /// wide so 15 fit with a small gap on either end on standard phone widths.
  Vector2 _bakedBearOffPosition(int stackPosition, int player) {
    final cx = imageLeft + imageWidth / 2;
    final sliverWidth = trayInnerHeight * (77.0 / 202.0); // sprite aspect
    // 15-pile total width = ~15 * sliverWidth * 0.85 — fits across the tray.
    final stackStep = sliverWidth * 0.85;
    final dx = (stackPosition - 7) * stackStep;
    final cy = player == 1 ? bottomTrayCenterY : topTrayCenterY;
    return Vector2(cx + dx, cy);
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
      return [
        Vector2(base.x - halfWidth, base.y),
        Vector2(base.x + halfWidth, base.y),
        Vector2(base.x, base.y + pointHeight),
      ];
    } else {
      return [
        Vector2(base.x - halfWidth, base.y),
        Vector2(base.x + halfWidth, base.y),
        Vector2(base.x, base.y - pointHeight),
      ];
    }
  }
}

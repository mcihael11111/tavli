import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/flame_game/components/board_layout.dart';

/// Locks in the geometry invariants that make the board sprite, checker
/// stacks, and move-hint overlays visually aligned. If these break, the
/// misalignment regression the player reported on 2026-04-16 is coming back.
void main() {
  // A representative portrait phone viewport (Pixel 7 class).
  final gameSize = Vector2(412, 915);

  group('BoardLayout — sprite mode calibration', () {
    final layout = BoardLayout(gameSize, useSpriteLayout: true);

    test('sprite constants match calibrated values', () {
      // Measured from set1_board.png (2106 × 1954 px).
      expect(layout.frameThickness, closeTo(layout.boardWidth * 0.031, 0.01));
      expect(layout.barWidth, closeTo(layout.boardWidth * 0.031, 0.01));
      expect(layout.bearOffWidth, closeTo(layout.boardWidth * 0.005, 0.01));
      expect(layout.trianglePadTop, closeTo(layout.boardHeight * 0.028, 0.01));
      expect(layout.trianglePadBottom, closeTo(layout.boardHeight * 0.028, 0.01));
      expect(layout.stackOverlapFactor, 0.75);
      expect(layout.stackAnchorNudge, 2.0);
      expect(layout.pointHeight, closeTo(layout.boardHeight * 0.32, 0.01));
    });

    test('top/bottom rows mirror horizontally', () {
      // Point 1 (bottom) and point 24 (top-right mirror) share an x column.
      final bot = layout.pointBasePosition(0);
      final top = layout.pointBasePosition(23);
      expect(bot.x, closeTo(top.x, 0.01), reason: 'bottom-right ≠ top-right');

      // Point 6 and point 19 share an x column (left edge of right-half).
      final bot6 = layout.pointBasePosition(5);
      final top19 = layout.pointBasePosition(18);
      expect(bot6.x, closeTo(top19.x, 0.01));
    });

    test('top/bottom row anchors are vertically symmetric', () {
      final top = layout.pointBasePosition(12); // first top-row point
      final bot = layout.pointBasePosition(11); // mirrored bottom point
      final topDist = top.y - layout.boardTop;
      final botDist = (layout.boardTop + layout.boardHeight) - bot.y;
      expect(topDist, closeTo(botDist, 0.5), reason: 'rows not equidistant from edges');
    });

    test('triangle tips leave room in the center for dice', () {
      final topBase = layout.pointBasePosition(12);
      final topTipY = topBase.y + layout.pointHeight;
      final botBase = layout.pointBasePosition(0);
      final botTipY = botBase.y - layout.pointHeight;
      final centerGap = botTipY - topTipY;
      expect(centerGap, greaterThan(80),
          reason: 'opposing triangle tips crowd dice area');
    });

    test('5-stack fits inside the triangle vertically', () {
      // Checker 4 (top of a 5-stack) on a bottom-row point must be above tip.
      final topChecker = layout.checkerPosition(0, 4, 1, totalOnPoint: 5);
      final base = layout.pointBasePosition(0);
      final tipY = base.y - layout.pointHeight;
      expect(topChecker.y, greaterThan(tipY),
          reason: '5-stack spills past triangle tip');
    });

    test('15-stack compresses to fit even with extreme pile-up', () {
      final topChecker = layout.checkerPosition(0, 14, 1, totalOnPoint: 15);
      final base = layout.pointBasePosition(0);
      final tipY = base.y - layout.pointHeight;
      expect(topChecker.y, greaterThan(tipY),
          reason: '15-stack spills past triangle tip even after compression');
    });

    test('bar first-checker leaves diamond inlay visible', () {
      final bar1 = layout.checkerPosition(-1, 0, 1);
      final centerY = layout.boardTop + layout.boardHeight / 2;
      final clearance = (bar1.y - centerY).abs();
      expect(clearance, greaterThanOrEqualTo(layout.checkerRadius * 2 - 0.01),
          reason: 'first bar checker covers the center diamond');
    });

    test('bar stacking uses the same overlap as point stacks', () {
      final c0 = layout.checkerPosition(-1, 0, 1);
      final c1 = layout.checkerPosition(-1, 1, 1);
      final step = (c1.y - c0.y).abs();
      final expected = layout.checkerRadius * 2 * layout.stackOverlapFactor;
      expect(step, closeTo(expected, 0.01));
    });

    test('bear-off tray comfortably holds all 15 checkers', () {
      final last = layout.checkerPosition(-2, 14, 1);
      // Must still be within the board vertically.
      expect(last.y, greaterThan(layout.boardTop));
      expect(last.y, lessThan(layout.boardTop + layout.boardHeight));
    });

    test('pointTriangle vertices are consistent with base', () {
      for (final idx in [0, 5, 11, 12, 18, 23]) {
        final base = layout.pointBasePosition(idx);
        final verts = layout.pointTriangle(idx);
        expect(verts.length, 3);
        // Base midpoint of the triangle is the base position.
        final baseMidX = (verts[0].x + verts[1].x) / 2;
        expect(baseMidX, closeTo(base.x, 0.01));
        expect(verts[0].y, closeTo(base.y, 0.01));
        // Tip is halfWidth inward of base midpoint AND pointHeight away.
        final tipY = verts[2].y;
        expect((tipY - base.y).abs(), closeTo(layout.pointHeight, 0.01));
      }
    });
  });

  group('BoardLayout — baked bear-off mode', () {
    // Landscape phone viewport, close to a 16:9 phone in landscape.
    final landscape = Vector2(896, 414);
    // Portrait phone viewport.
    final portrait = Vector2(412, 915);

    test('portrait screen fits width (100 % vpw) and centers vertically', () {
      final l = BoardLayout(portrait, useBakedBearOff: true);
      expect(l.imageWidth, portrait.x);
      // Baked PNG aspect is 2102 / 2374 ≈ 0.8854.
      expect(l.imageHeight, closeTo(portrait.x / 0.8854, 0.5));
      expect(l.imageLeft, 0);
      expect(l.imageTop, closeTo((portrait.y - l.imageHeight) / 2, 0.5));
    });

    test('landscape screen fits height (image taller than wide)', () {
      final l = BoardLayout(landscape, useBakedBearOff: true);
      expect(l.imageHeight, landscape.y);
      expect(l.imageWidth, closeTo(landscape.y * 0.8854, 0.5));
      expect(l.imageTop, 0);
      expect(l.imageLeft, closeTo((landscape.x - l.imageWidth) / 2, 0.5));
    });

    test('board playing region sits below top bear-off strip', () {
      final l = BoardLayout(portrait, useBakedBearOff: true);
      expect(l.boardTop, greaterThan(l.imageTop));
      expect(l.bearOffStripHeight, greaterThan(0));
      expect(l.boardTop, closeTo(l.imageTop + l.bearOffStripHeight, 0.01));
      expect(l.boardHeight, closeTo(l.imageHeight * 0.821, 1.0));
    });

    test('bear-off checkers land inside the strip regions', () {
      final l = BoardLayout(portrait, useBakedBearOff: true);
      // P1 bears off to bottom strip.
      final p1 = l.checkerPosition(-2, 0, 1);
      expect(p1.y, greaterThan(l.boardTop + l.boardHeight));
      expect(p1.y, lessThan(l.imageTop + l.imageHeight));
      // P2 bears off to top strip.
      final p2 = l.checkerPosition(-2, 0, 2);
      expect(p2.y, greaterThan(l.imageTop));
      expect(p2.y, lessThan(l.boardTop));
    });

    test('baked mode has no side bear-off tray', () {
      final l = BoardLayout(portrait, useBakedBearOff: true);
      expect(l.bearOffWidth, 0);
    });
  });

  group('BoardLayout — visible-disc + tap-target invariants', () {
    // Reasonable phone widths: 360 = small Android, 412 = mid Android.
    final viewports = [
      Vector2(360, 800),
      Vector2(412, 915),
      Vector2(896, 414),
    ];

    test('checker visible disc is at least 80% of triangle base width', () {
      // The visible disc diameter equals checkerRadius * 2 (the logical
      // bounding box). It must read as snug-in-the-triangle, not floating.
      for (final v in viewports) {
        final l = BoardLayout(v, useBakedBearOff: true);
        final discDiameter = l.checkerRadius * 2;
        final fraction = discDiameter / l.pointWidth;
        expect(fraction, greaterThanOrEqualTo(0.80),
            reason: 'on viewport $v disc/point=$fraction');
        expect(fraction, lessThanOrEqualTo(1.05),
            reason: 'disc spills past triangle base on $v');
      }
    });

    test('tap-target hitbox respects 44pt Material a11y floor', () {
      // Hitbox = max(checkerRadius, BoardLayout.minTapRadius).
      for (final v in viewports) {
        final l = BoardLayout(v, useBakedBearOff: true);
        final hit = l.checkerRadius < BoardLayout.minTapRadius
            ? BoardLayout.minTapRadius
            : l.checkerRadius;
        expect(hit * 2, greaterThanOrEqualTo(44),
            reason: 'tap diameter <44pt on viewport $v');
      }
    });

    test('visible-ratio constants match the 2026 art set', () {
      // Pinned by image inspection: 222/400 for checkers, 136/400 for dice.
      expect(BoardLayout.checkerVisibleRatio, closeTo(222 / 400, 0.005));
      expect(BoardLayout.diceVisibleRatio, closeTo(136 / 400, 0.005));
    });
  });

  group('BoardLayout — procedural mode (no sprite)', () {
    final layout = BoardLayout(gameSize, useSpriteLayout: false);

    test('procedural uses legacy constants', () {
      expect(layout.frameThickness, closeTo(layout.boardWidth * 0.025, 0.01));
      expect(layout.barWidth, closeTo(layout.boardWidth * 0.04, 0.01));
      expect(layout.bearOffWidth, closeTo(layout.boardWidth * 0.05, 0.01));
      expect(layout.stackOverlapFactor, 0.85);
      expect(layout.stackAnchorNudge, 0.0);
      // Procedural triangles stay at 40% of board height.
      expect(layout.pointHeight, closeTo(layout.boardHeight * 0.40, 0.01));
    });

    test('trianglePad equals frameThickness in procedural mode', () {
      expect(layout.trianglePadTop, layout.frameThickness);
      expect(layout.trianglePadBottom, layout.frameThickness);
    });
  });
}

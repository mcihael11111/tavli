import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/gameplay/board/board_layout.dart';
import 'package:tavli/gameplay/board/board_region.dart';

/// Ported from the legacy `test/unit/board_layout_test.dart` (baked mode)
/// plus the new pip/hit-region APIs (design §4.1, §4.3).
void main() {
  const sliverAspect = 47 / 172; // the on-edge checker's visible content
  BoardLayout layoutFor(Size s) => BoardLayout(s, sliverAspect: sliverAspect);

  const portrait = Size(412, 915);
  const landscape = Size(896, 414);
  const viewports = [Size(360, 800), portrait, landscape, Size(1024, 1366)];

  group('fit (legacy baked mode)', () {
    test('portrait fits width and centres vertically', () {
      final l = layoutFor(portrait);
      expect(l.imageRect.width, portrait.width);
      expect(l.imageRect.height, closeTo(portrait.width / 0.8854, 0.5));
      expect(l.imageRect.left, 0);
      expect(l.imageRect.top,
          closeTo((portrait.height - l.imageRect.height) / 2, 0.5));
    });

    test('landscape fits height', () {
      final l = layoutFor(landscape);
      expect(l.imageRect.height, landscape.height);
      expect(l.imageRect.width, closeTo(landscape.height * 0.8854, 0.5));
      expect(l.imageRect.top, 0);
      expect(l.imageRect.left,
          closeTo((landscape.width - l.imageRect.width) / 2, 0.5));
    });

    test('playing region sits between the tray strips', () {
      final l = layoutFor(portrait);
      expect(l.boardRect.top, greaterThan(l.imageRect.top));
      expect(l.boardRect.height, closeTo(l.imageRect.height * 0.821, 1.0));
      expect(l.trayRect(ViewEdge.top).bottom, lessThan(l.boardRect.top));
      expect(l.trayRect(ViewEdge.bottom).top, greaterThan(l.boardRect.bottom));
    });
  });

  group('points', () {
    final l = layoutFor(portrait);
    final w = l.imageRect.width, h = l.imageRect.height;

    test('anchors match the measured paint fractions', () {
      expect(l.pointBase(0).dx, closeTo(w * 1974.5 / 2102, 0.01));
      expect(l.pointBase(11).dx, closeTo(w * 161.5 / 2102, 0.01));
      expect(l.pointBase(5).dx, closeTo(w * (1974.5 - 5 * 158) / 2102, 0.01));
      expect(l.pointBase(6).dx, closeTo(w * (161.5 + 5 * 154) / 2102, 0.01));
      expect(
          l.pointBase(0).dy, closeTo(l.imageRect.top + h * 2103 / 2374, .01));
      expect(
          l.pointBase(12).dy, closeTo(l.imageRect.top + h * 268 / 2374, .01));
      expect(l.pointHeight, closeTo(h * 675 / 2374, 0.01));
      expect(l.checkerRadius, closeTo(w * 154 / 2102 * 0.46, 0.01));
    });

    test('top and bottom rows mirror horizontally', () {
      for (var vp = 0; vp < 12; vp++) {
        expect(l.pointBase(vp).dx, closeTo(l.pointBase(23 - vp).dx, 0.01));
      }
    });

    test('triangle vertices are consistent with the base', () {
      for (final vp in [0, 5, 11, 12, 18, 23]) {
        final base = l.pointBase(vp);
        final t = l.pointTriangle(vp);
        expect((t[0].dx + t[1].dx) / 2, closeTo(base.dx, 0.01));
        expect(t[0].dy, closeTo(base.dy, 0.01));
        expect((t[2].dy - base.dy).abs(), closeTo(l.pointHeight, 0.01));
      }
    });

    test('tips leave the dice area clear', () {
      final topTip = l.pointTriangle(12)[2].dy;
      final botTip = l.pointTriangle(0)[2].dy;
      expect(botTip - topTip, greaterThan(l.diceRect.height));
      for (var vp = 0; vp < 24; vp++) {
        expect(l.diceRect.contains(l.pointTriangle(vp)[2]), isFalse,
            reason: 'tip of $vp under the dice');
      }
      for (var n = 1; n <= 4; n++) {
        for (var i = 0; i < n; i++) {
          final c = l.diceCenter(i, n);
          expect(l.diceRect.contains(c.translate(l.dieSize / 2, l.dieSize / 2)),
              isTrue);
          expect(
              l.diceRect.contains(c.translate(-l.dieSize / 2, -l.dieSize / 2)),
              isTrue);
        }
      }
    });
  });

  group('stacks', () {
    final l = layoutFor(portrait);

    test('a 5-stack stays inside the triangle', () {
      for (final vp in [0, 12]) {
        final tip = l.pointTriangle(vp)[2].dy;
        final top = l.checkerCenter(vp, 4, 5);
        expect(vp < 12 ? top.dy > tip : top.dy < tip, isTrue);
      }
    });

    test('a 15-stack stays in its half of the column, clear of the dice', () {
      for (final v in viewports) {
        final m = layoutFor(v);
        for (var vp = 0; vp < 24; vp++) {
          final c = m.checkerCenter(vp, 14, 15);
          final far = vp < 12 ? c.dy - m.checkerRadius : c.dy + m.checkerRadius;
          expect(vp < 12 ? far > m.barCenterY : far < m.barCenterY, isTrue,
              reason: '15-stack on $vp crosses the centre on $v');
          final disc = Rect.fromCircle(center: c, radius: m.checkerRadius);
          expect(disc.overlaps(m.diceRect), isFalse,
              reason: '15-stack on $vp under the dice on $v');
        }
      }
    });

    test('the first checker sits on the base', () {
      expect(l.checkerCenter(0, 0, 1).dy,
          closeTo(l.pointBase(0).dy - l.checkerRadius, 0.01));
      expect(l.checkerCenter(23, 0, 1).dy,
          closeTo(l.pointBase(23).dy + l.checkerRadius, 0.01));
    });

    test('compresses only above 7, keeping the 7-pile span', () {
      for (var n = 1; n <= 7; n++) {
        expect(l.stackOffset(n), l.stackStep);
      }
      expect(l.stackStep, closeTo(l.checkerRadius * 2 * 0.75, 1e-9));
      final span7 = l.checkerCenter(0, 6, 7).dy;
      for (var n = 8; n <= 15; n++) {
        expect(l.stackOffset(n), lessThan(l.stackOffset(n - 1)));
        expect(l.checkerCenter(0, n - 1, n).dy, closeTo(span7, 1e-9));
      }
    });

    test('disc fills the column without touching neighbours', () {
      for (final v in viewports) {
        final m = layoutFor(v);
        final f = m.checkerRadius * 2 / m.pointWidth;
        expect(f, inInclusiveRange(0.80, 1.05), reason: 'on $v');
        for (var vp = 0; vp < 23; vp++) {
          if (vp == 11) continue; // rows differ
          final dx = (m.pointBase(vp).dx - m.pointBase(vp + 1).dx).abs();
          expect(dx, greaterThanOrEqualTo(m.checkerRadius * 2),
              reason: 'columns $vp/${vp + 1} on $v');
        }
      }
    });
  });

  group('bar, tray, cube', () {
    final l = layoutFor(portrait);

    test('bar pile clears the centre and steps like a stack', () {
      for (final e in ViewEdge.values) {
        final c0 = l.barSlot(e, 0, 2), c1 = l.barSlot(e, 1, 2);
        expect((c0.dy - l.barCenterY).abs(),
            greaterThanOrEqualTo(l.checkerRadius * 2 - 0.01));
        expect((c1.dy - c0.dy).abs(), closeTo(l.stackStep, 0.01));
        // The cube between the piles does not touch the first checker.
        expect((c0.dy - l.cubeSpot.dy).abs(),
            greaterThanOrEqualTo(l.checkerRadius + l.dieSize / 2));
      }
      expect(l.barSlot(ViewEdge.bottom, 0, 1).dy, greaterThan(l.barCenterY));
      expect(l.barSlot(ViewEdge.top, 0, 1).dy, lessThan(l.barCenterY));
    });

    test('a full bar pile stays on the board side of its edge', () {
      final b = l.barSlot(ViewEdge.bottom, 14, 15);
      expect(b.dy + l.checkerRadius, lessThan(l.boardRect.bottom));
      final t = l.barSlot(ViewEdge.top, 14, 15);
      expect(t.dy - l.checkerRadius, greaterThan(l.boardRect.top));
    });

    test('slivers keep the asset aspect and 15 fit in the tray', () {
      for (final v in viewports) {
        final m = layoutFor(v);
        for (final e in ViewEdge.values) {
          final tray = m.trayRect(e);
          Rect? prev;
          for (var i = 0; i < 15; i++) {
            final s = m.traySlot(e, i);
            expect(s.width / s.height, closeTo(sliverAspect, 1e-9));
            expect(tray.contains(s.topLeft) && tray.contains(s.bottomRight),
                isTrue,
                reason: 'sliver $i outside the ${e.name} tray on $v');
            if (prev != null) expect(s.left, greaterThanOrEqualTo(prev.right));
            prev = s;
          }
        }
      }
    });
  });

  group('columnAt', () {
    for (final v in viewports) {
      test('covers every full column incl. tips on $v', () {
        final l = layoutFor(v);
        for (var vp = 0; vp < 24; vp++) {
          final r = l.columnRect(vp);
          final want = PointRegion(vp);
          for (var i = 0; i <= 10; i++) {
            for (var j = 0; j <= 10; j++) {
              final p = Offset(r.left + (r.width - 1e-6) * i / 10,
                  r.top + (r.height - 1e-6) * j / 10);
              if (l.diceRect.contains(p) ||
                  l.barRect(ViewEdge.top).contains(p) ||
                  l.barRect(ViewEdge.bottom).contains(p)) {
                continue; // tested before the columns
              }
              expect(l.columnAt(p), want, reason: 'vp $vp at $p');
            }
          }
          // Triangle corners (base corners a hair inside: neighbouring
          // left-half triangles touch at the column boundary) and the tip.
          final t = l.pointTriangle(vp);
          final inset = l.pointWidth * 0.01;
          for (final corner in [
            t[0].translate(inset, 0),
            t[1].translate(-inset, 0),
            t[2]
          ]) {
            // The inner base corners of view points 5/6/17/18 may lie in
            // the widened bar band; tips never do.
            final inBar = l.barRect(ViewEdge.top).contains(corner) ||
                l.barRect(ViewEdge.bottom).contains(corner);
            if (inBar && corner != t[2]) continue;
            expect(l.columnAt(corner), want, reason: 'triangle of $vp');
          }
          for (var i = 0; i < 15; i++) {
            expect(l.columnAt(l.checkerCenter(vp, i, 15)), want);
          }
        }
      });
    }

    test('columns do not overlap; the bar band spares stack centres', () {
      for (final v in viewports) {
        final l = layoutFor(v);
        final rects = [for (var vp = 0; vp < 24; vp++) l.columnRect(vp)];
        for (var a = 0; a < rects.length; a++) {
          for (var b = a + 1; b < rects.length; b++) {
            final o = rects[a].intersect(rects[b]);
            expect(o.width <= 1e-9 || o.height <= 1e-9, isTrue,
                reason: 'columns $a and $b overlap on $v');
          }
        }
        for (var vp = 0; vp < 24; vp++) {
          for (var i = 0; i < 15; i++) {
            expect(l.columnAt(l.checkerCenter(vp, i, 15)), PointRegion(vp),
                reason: 'stack centre of $vp under the bar band on $v');
          }
        }
      }
    });

    test('bar band is at least a checker diameter (48 px given room)', () {
      for (final v in viewports) {
        final l = layoutFor(v);
        for (final e in ViewEdge.values) {
          final w = l.barRect(e).width;
          expect(w, greaterThanOrEqualTo(l.checkerRadius * 2 - 1e-9));
          if (v.width >= 1024) {
            expect(w, greaterThanOrEqualTo(BoardLayout.minBarHitWidth));
          }
        }
      }
    });

    test('taps across a bar checker\'s whole disc hit the bar', () {
      for (final v in viewports) {
        final l = layoutFor(v);
        final r = l.checkerRadius * 0.999;
        for (final e in ViewEdge.values) {
          for (final (i, n) in [(0, 1), (2, 3), (6, 7), (14, 15)]) {
            final c = l.barSlot(e, i, n);
            for (var a = -10; a <= 10; a++) {
              for (var b = -10; b <= 10; b++) {
                final p = Offset(c.dx + r * a / 10, c.dy + r * b / 10);
                if ((p - c).distance > r) continue;
                expect(l.columnAt(p), BarRegion(e),
                    reason: 'bar slot $i/$n ${e.name} at $p on $v');
              }
            }
          }
        }
      }
    });

    test('bar, trays, dice and outside', () {
      final l = layoutFor(portrait);
      expect(l.columnAt(l.barSlot(ViewEdge.bottom, 0, 1)),
          const BarRegion(ViewEdge.bottom));
      expect(l.columnAt(l.barSlot(ViewEdge.top, 3, 4)),
          const BarRegion(ViewEdge.top));
      for (final e in ViewEdge.values) {
        expect(l.columnAt(l.traySlot(e, 0).center), TrayRegion(e));
        expect(l.columnAt(l.traySlot(e, 14).center), TrayRegion(e));
      }
      expect(l.columnAt(l.diceCenter(0, 2)), const DiceRegion());
      expect(l.columnAt(Offset(l.imageRect.left, l.imageRect.top - 1)), isNull);
    });
  });
}

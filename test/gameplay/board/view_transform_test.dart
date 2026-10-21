import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/gameplay/board/board_region.dart';
import 'package:tavli/gameplay/board/view_transform.dart';
import 'package:tavli_core/tavli_core.dart';

void main() {
  final transforms = [
    for (final d in Direction.values)
      for (final v in Side.values) ViewTransform(direction: d, viewer: v),
  ];

  group('round trips, all directions × flips × sides', () {
    for (final t in transforms) {
      for (final side in Side.values) {
        test('$t ${side.name}', () {
          final seen = <int>{};
          for (var pip = 1; pip <= 24; pip++) {
            final vp = t.viewPoint(side, pip);
            expect(vp, inInclusiveRange(0, 23));
            expect(t.pipAt(side, vp), pip);
            seen.add(vp);
            // Same physical point for the opponent (matrix §1).
            expect(t.viewPoint(side.opponent, t.geometry.toOpponent(pip)), vp);
          }
          expect(seen, hasLength(24), reason: 'viewPoint is a bijection');
          for (var pip = 0; pip <= 25; pip++) {
            expect(t.pipOf(side, t.locate(side, pip)), pip);
          }
        });
      }
    }
  });

  group('the viewer is drawn as the legacy player 1', () {
    for (final t in transforms) {
      test('$t: home bottom-right, 24 top-right, bottom bar and tray', () {
        final me = t.viewer;
        for (var pip = 1; pip <= 6; pip++) {
          expect(t.viewPoint(me, pip), pip - 1);
        }
        expect(t.viewPoint(me, 24), 23);
        expect(t.locate(me, 25), const BarRegion(ViewEdge.bottom));
        expect(t.locate(me, 0), const TrayRegion(ViewEdge.bottom));
        expect(t.locate(me.opponent, 25), const BarRegion(ViewEdge.top));
        expect(t.locate(me.opponent, 0), const TrayRegion(ViewEdge.top));
        expect(t.edgeOf(me), ViewEdge.bottom);
        expect(t.sideAt(ViewEdge.top), me.opponent);
        expect(t.flipped, me == Side.two);
      });
    }
  });

  test('opposing: legacy hitting layout (matrix §1) when unflipped', () {
    const t = ViewTransform(direction: Direction.opposing);
    for (var idx = 0; idx < 24; idx++) {
      expect(t.pipAt(Side.one, idx), idx + 1);
      expect(t.pipAt(Side.two, idx), 24 - idx);
    }
    // Opponent's home is top-right.
    expect([for (var p = 1; p <= 6; p++) t.viewPoint(Side.two, p)],
        [23, 22, 21, 20, 19, 18]);
  });

  test('same: opponent starts bottom-left, homes top-left', () {
    const t = ViewTransform(direction: Direction.same);
    expect(t.viewPoint(Side.two, 24), 11);
    expect([for (var p = 1; p <= 6; p++) t.viewPoint(Side.two, p)],
        [12, 13, 14, 15, 16, 17]);
  });

  test('flip mirrors the sides', () {
    for (final d in Direction.values) {
      final a = ViewTransform(direction: d);
      final b = a.withViewer(Side.two);
      for (var pip = 1; pip <= 24; pip++) {
        expect(b.viewPoint(Side.two, pip), a.viewPoint(Side.one, pip));
        expect(b.viewPoint(Side.one, pip), a.viewPoint(Side.two, pip));
      }
    }
  });

  test('dice and the opponent bar/tray carry no pip', () {
    const t = ViewTransform(direction: Direction.opposing);
    expect(t.pipOf(Side.one, const DiceRegion()), isNull);
    expect(t.pipOf(Side.one, const BarRegion(ViewEdge.top)), isNull);
    expect(t.pipOf(Side.one, const TrayRegion(ViewEdge.top)), isNull);
    expect(() => t.viewPoint(Side.one, 0), throwsRangeError);
    expect(() => t.viewPoint(Side.one, 25), throwsRangeError);
    expect(() => t.pipAt(Side.one, 24), throwsRangeError);
  });
}

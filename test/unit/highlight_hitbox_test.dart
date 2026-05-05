import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/flame_game/components/board_layout.dart';
import 'package:tavli/flame_game/components/highlight_component.dart';

/// Locks in the rectangular tap-zone behaviour. Before this, the tap test
/// used a strict triangle path and the tip region was effectively
/// unhittable on phones (< 5 px wide on a 412-px viewport).
void main() {
  group('HighlightComponent — rectangular hit zone', () {
    final layout = BoardLayout(Vector2(412, 915), useBakedBearOff: true);

    Future<HighlightComponent> loadHighlight(int pointIndex) async {
      final h = HighlightComponent(
        pointIndex: pointIndex,
        dieValue: 3,
        boardLayout: layout,
      );
      await h.onLoad();
      return h;
    }

    test('tap at the bbox centre hits', () async {
      final h = await loadHighlight(0);
      final centre = h.position + h.size / 2;
      expect(h.containsPoint(centre), isTrue);
    });

    test('tap near the triangle TIP (previously a dead zone) hits', () async {
      // Bottom-row triangle (point 0): tip is at the top of the bbox.
      final h = await loadHighlight(0);
      // 5 px below the very top of the bbox — well inside the rect, but
      // ~4 px wide on the triangle path → would have failed the old test.
      final nearTip = Vector2(h.position.x + h.size.x / 2, h.position.y + 5);
      expect(h.containsPoint(nearTip), isTrue);
    });

    test('tap just outside the bbox misses', () async {
      final h = await loadHighlight(0);
      final outside = Vector2(h.position.x + h.size.x + 2, h.position.y + 10);
      expect(h.containsPoint(outside), isFalse);
    });

    test('top-row tip is also tappable', () async {
      // Top-row triangle (point 12): tip is at the bottom of the bbox.
      final h = await loadHighlight(12);
      final nearTip = Vector2(
        h.position.x + h.size.x / 2,
        h.position.y + h.size.y - 5,
      );
      expect(h.containsPoint(nearTip), isTrue);
    });

    test('adjacent points stay unambiguous (no lateral overflow)', () async {
      // Bottom-row points 0 (rightmost) and 1 (next to its left). The two
      // bboxes overlap is whichever one is to the left's right-edge minus
      // the other's left-edge. With pad=4 px on each side the maximum
      // expected overlap is 8 px; anything more would let a single tap
      // fire two highlights and break disambiguation.
      final h0 = await loadHighlight(0);
      final h1 = await loadHighlight(1);
      final left = h0.position.x < h1.position.x ? h0 : h1;
      final right = h0.position.x < h1.position.x ? h1 : h0;
      final leftRight = left.position.x + left.size.x;
      final rightLeft = right.position.x;
      final overlap = leftRight - rightLeft;
      expect(overlap, lessThanOrEqualTo(9.0),
          reason: 'adjacent highlight bboxes overlap by $overlap px');
    });
  });
}

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/flame_game/components/board_layout.dart';
import 'package:tavli/flame_game/components/checker_component.dart';

/// Smoke tests for the tap-selection visual API (Spec §6.1).
///
/// The full visual (scale + ring fade-in over 80ms) is covered by manual QA
/// — these tests assert the behavioral contract that wiring code in
/// `game_screen.dart` relies on.
void main() {
  group('CheckerComponent.setSelected', () {
    late CheckerComponent checker;

    setUp(() {
      // BoardLayout is needed for the constructor; a minimal layout suffices
      // because we never render in this test.
      final layout = BoardLayout(Vector2(800, 600));
      checker = CheckerComponent(
        pointIndex: 0,
        stackPosition: 0,
        player: 1,
        boardLayout: layout,
      );
    });

    test('flips isSelected synchronously', () {
      expect(checker.isSelected, isFalse);
      checker.setSelected(true);
      expect(checker.isSelected, isTrue);
      checker.setSelected(false);
      expect(checker.isSelected, isFalse);
    });

    test('is idempotent on the same value', () {
      checker.setSelected(true);
      // Calling again is a no-op — should not throw or re-trigger the tween
      // in a way that disrupts an already-settled selection.
      checker.setSelected(true);
      expect(checker.isSelected, isTrue);
    });
  });
}

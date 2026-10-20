import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/gameplay/services/game_haptics.dart';

void main() {
  test('fires exactly one haptic per event', () {
    final fired = <HapticKind>[];
    final h = GameHaptics(enabled: () => true, sink: fired.add);
    for (final e in GameHapticEvent.values) {
      fired.clear();
      h.fire(e);
      expect(fired, hasLength(1), reason: '$e');
    }
  });

  test('fires nothing when disabled', () {
    final fired = <HapticKind>[];
    final h = GameHaptics(enabled: () => false, sink: fired.add);
    for (final e in GameHapticEvent.values) {
      h.fire(e);
    }
    expect(fired, isEmpty);
  });

  test('reads the setting at fire time', () {
    var on = false;
    final fired = <HapticKind>[];
    final h = GameHaptics(enabled: () => on, sink: fired.add);
    h.fire(GameHapticEvent.place);
    on = true;
    h.fire(GameHapticEvent.place);
    expect(fired, [HapticKind.light]);
  });

  testWidgets('default sink makes exactly one platform call per event',
      (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final h = GameHaptics(enabled: () => true);
    for (final e in GameHapticEvent.values) {
      calls.clear();
      h.fire(e);
      await tester.pump();
      expect(calls.where((c) => c.method == 'HapticFeedback.vibrate'),
          hasLength(1),
          reason: '$e');
    }
  });
}

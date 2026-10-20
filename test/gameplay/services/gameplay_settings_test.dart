import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tavli/gameplay/services/gameplay_settings.dart';
import 'package:tavli/shared/services/settings_service.dart';

void main() {
  Future<GameplaySettings> fresh(
      [Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    return GameplaySettings(SettingsService.withPrefs(prefs));
  }

  test('defaults', () async {
    final s = await fresh();
    expect(s.animSpeed, AnimSpeed.normal);
    expect(s.haptics, isTrue);
    expect(s.autoplayForced, isTrue);
    expect(s.autoPass, isTrue);
    expect(s.autoRoll, isFalse);
    expect(s.moveConfirmation, isFalse);
    expect(s.autoCommit, isTrue);
    expect(s.showPipCount, isFalse);
    expect(s.sfxVolume, 1.0);
  });

  test('persists through the existing service keys', () async {
    final s = await fresh();
    s
      ..animSpeed = AnimSpeed.fast
      ..haptics = false
      ..autoplayForced = false
      ..autoPass = false
      ..autoRoll = true;
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('tavli_anim_speed'), 'fast');
    expect(prefs.getBool('tavli_haptics'), isFalse);
    expect(prefs.getBool('tavli_autoplay_forced'), isFalse);
    expect(prefs.getBool('tavli_auto_pass'), isFalse);
    expect(prefs.getBool('tavli_auto_roll'), isTrue);

    final reread = GameplaySettings(SettingsService.withPrefs(prefs));
    expect(reread.animSpeed, AnimSpeed.fast);
    expect(reread.haptics, isFalse);
    expect(reread.autoplayForced, isFalse);
    expect(reread.autoPass, isFalse);
    expect(reread.autoRoll, isTrue);
  });

  test('reads existing keys: move confirmation, pip count, sfx volume',
      () async {
    final s = await fresh({
      'tavli_move_confirm': true,
      'tavli_pip_count': true,
      'tavli_sfx_vol': 0.25,
    });
    expect(s.moveConfirmation, isTrue);
    expect(s.autoCommit, isFalse);
    expect(s.showPipCount, isTrue);
    expect(s.sfxVolume, 0.25);
  });

  test('unknown stored speed falls back to normal', () async {
    final s = await fresh({'tavli_anim_speed': 'warp'});
    expect(s.animSpeed, AnimSpeed.normal);
  });

  testWidgets('reduced motion via MediaQuery zeroes the duration factor',
      (tester) async {
    final s = await fresh({'tavli_anim_speed': 'slow'});
    late double normal, reduced;
    late bool flag;
    await tester.pumpWidget(Builder(builder: (c) {
      normal = s.durationFactor(c);
      return MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(builder: (c2) {
          flag = GameplaySettings.reducedMotion(c2);
          reduced = s.durationFactor(c2);
          return const SizedBox();
        }),
      );
    }));
    expect(normal, AnimSpeed.slow.durationFactor);
    expect(flag, isTrue);
    expect(reduced, 0);
  });
}

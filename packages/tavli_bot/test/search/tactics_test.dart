import 'dart:math';

import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/search_support.dart';
import '../support/tactics.dart';

SearchResult _search(Tactic t, LevelProfile profile) => choosePlay(
      position: t.position,
      side: Side.one,
      dice: t.dice,
      cascade: false,
      context: TurnContext(),
      rules: t.variant.rules,
      profile: profile,
      rng: Random(1),
      // Large, so 2-ply always finishes and the answer does not depend on
      // the machine (the budget itself is tested in search_test).
      budget: const Duration(seconds: 60),
    );

void main() {
  final expert = LevelProfile.of(BotLevel.expert);

  test('the suite has at least 4 tactics per family', () {
    expect(hittingTactics.length, greaterThanOrEqualTo(4));
    expect(pinningTactics.length, greaterThanOrEqualTo(4));
    expect(runningTactics.length, greaterThanOrEqualTo(4));
  });

  for (final (family, suite) in [
    ('hitting', hittingTactics),
    ('pinning', pinningTactics),
    ('running', runningTactics),
  ]) {
    group('Expert finds the $family tactics', () {
      for (final t in suite) {
        test(t.name, () {
          final r = _search(t, expert);
          expect(t.expected(r.play.finalPosition), isTrue,
              reason: '${t.why}\nchose ${r.play.steps} (${r.stats})');
          expect(r.stats.depthReached, 2);
        });
      }
    });
  }

  // Plan Task 5 test 6. The 0-ply evaluator charges a blot only a small
  // risk term, so it takes the extra point; 1-ply sees the anchor's
  // shots (and the cost of being hit against a five-point board).
  group('1-ply beats 0-ply where 0-ply is misled', () {
    for (final name in [
      'clear from the back (3-2)',
      'clear from the back (5-3)'
    ]) {
      test(name, () {
        final t = hittingTactics.firstWhere((t) => t.name == name);
        final zero = _search(t, zeroPly), one = _search(t, onePly);
        expect(t.expected(zero.play.finalPosition), isFalse,
            reason: '0-ply chose ${zero.play.steps}');
        expect(t.expected(one.play.finalPosition), isTrue,
            reason: '1-ply chose ${one.play.steps}');
      });
    }
  });
}

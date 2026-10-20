@Tags(['legacy-bench'])
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/ai/engine/ai_player.dart';
import 'package:tavli/features/game/data/models/dice_roll.dart';
import 'package:tavli/features/game/domain/engine/game_engine.dart';
import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart' hide DiceRoll;

import '../differential/portes_legacy.dart';

/// SP2 legacy floor (design §1.4, plan Task 11): the new Easy beats the
/// legacy app bot at Easy in >= 50 % of 400 Portes games (200 mirrored
/// pairs, cube off, seed 1). The new Easy runs with its desktop-gate
/// budget (7 ms), as in the strength gates.
///
/// Run: flutter test --run-skipped --tags legacy-bench test/bench
void main() {
  test('new Easy vs legacy Easy: >= 50 % over 400 Portes games', () {
    const pairs = 200;
    final games = [
      for (var p = 0; p < pairs; p++)
        ...playPair(
          variant: Variant.portes,
          a: () => BotPlayer.level(BotLevel.easy,
              budget: const Duration(milliseconds: 7)),
          b: () => LegacyEasyPlayer(),
          seed: 1,
          pair: p,
        ),
    ];
    final s = PairingSummary.of(games);
    // ignore: avoid_print
    print('new Easy vs legacy Easy (Portes): $s');
    expect(s.games, 2 * pairs);
    expect(s.unfinished, 0);
    expect(s.winRate, greaterThanOrEqualTo(0.5), reason: '$s');
  });
}

/// The legacy `AiPlayer` at Easy as a tournament player: the position
/// is mapped to a legacy board ([toLegacy]), the legacy bot picks a
/// turn, and the core steps to its final board come from the play tree.
final class LegacyEasyPlayer implements TournamentPlayer {
  static const _engine = GameEngine();

  @override
  DecisionStats? get last => null;

  @override
  List<Step> choose(GameState s, int seed) {
    final side = s.sideToMove!;
    final board = toLegacy(s.position, side);
    final turn = AiPlayer(rng: Random(seed)).selectTurn(board,
        DiceRoll(die1: s.dice[0], die2: s.dice[1]), DifficultyLevel.easy);
    final target =
        toCore(turn == null ? board : _engine.applyMoves(board, turn.moves));
    final steps = s.tree.pathTo(target);
    if (steps == null) {
      throw StateError('legacy play to $target is not a core play');
    }
    return steps;
  }
}

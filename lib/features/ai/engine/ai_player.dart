import 'dart:math';

import '../../game/data/models/board_state.dart';
import '../../game/data/models/dice_roll.dart';
import '../../game/data/models/turn.dart';
import '../../game/domain/engine/board_evaluator.dart';
import '../../game/domain/engine/game_engine.dart';
import '../../game/domain/engine/move_generator.dart';
import '../../game/domain/engine/variants/game_variant.dart';
import '../../game/domain/engine/variants/plakoto_evaluator.dart';
import '../../game/domain/engine/variants/fevga_evaluator.dart';
import '../difficulty/difficulty_level.dart';

/// AI player that selects moves based on difficulty level.
///
/// Supports all three Tavli variants with variant-specific evaluators.
class AiPlayer {
  final GameEngine _engine;
  final MoveGenerator _generator;
  final BoardEvaluator _evaluator;
  final PlakotoEvaluator _plakotoEvaluator;
  final FevgaEvaluator _fevgaEvaluator;
  final Random _rng;

  AiPlayer({
    GameEngine? engine,
    MoveGenerator? generator,
    BoardEvaluator? evaluator,
    Random? rng,
  })  : _engine = engine ?? const GameEngine(),
        _generator = generator ?? const MoveGenerator(),
        _evaluator = evaluator ?? const BoardEvaluator(),
        _plakotoEvaluator = const PlakotoEvaluator(),
        _fevgaEvaluator = const FevgaEvaluator(),
        _rng = rng ?? Random();

  /// Evaluate a position using the correct variant evaluator.
  double _evaluateForVariant(BoardState state, int player, GameVariant variant) {
    return switch (variant) {
      GameVariant.portes => _evaluator.evaluate(state, player),
      GameVariant.plakoto => _plakotoEvaluator.evaluate(state, player),
      GameVariant.fevga => _fevgaEvaluator.evaluate(state, player),
    };
  }

  /// Select the best turn for the AI at the given difficulty.
  ///
  /// Returns null if no legal moves exist.
  Turn? selectTurn(
    BoardState state,
    DiceRoll roll,
    DifficultyLevel difficulty, {
    GameVariant variant = GameVariant.portes,
  }) {
    final turns = _generator.generateAllLegalTurns(state, roll);
    if (turns.isEmpty) return null;
    if (turns.length == 1) return turns.first;

    // Evaluate each turn's resulting position.
    final scored = <_ScoredTurn>[];
    for (final turn in turns) {
      final resultBoard = _engine.applyMoves(state, turn.moves);
      final equity = _evaluateAtDepth(
        resultBoard,
        state.activePlayer,
        difficulty.searchDepth,
        variant: variant,
      );
      scored.add(_ScoredTurn(turn, equity));
    }

    // Sort by equity (best first for the active player).
    scored.sort((a, b) => b.equity.compareTo(a.equity));

    // Apply difficulty-based selection.
    return _selectByDifficulty(scored, difficulty);
  }

  /// Evaluate position at the given search depth.
  double _evaluateAtDepth(
    BoardState state,
    int player,
    int depth, {
    GameVariant variant = GameVariant.portes,
  }) {
    if (depth <= 0) {
      return _evaluateForVariant(state, player, variant);
    }

    // N-ply: consider opponent's best response.
    final opponent = player == 1 ? 2 : 1;

    // Average over all possible dice rolls (21 distinct).
    double totalEquity = 0;
    int rollCount = 0;

    for (int d1 = 1; d1 <= 6; d1++) {
      for (int d2 = d1; d2 <= 6; d2++) {
        final roll = DiceRoll(die1: d1, die2: d2);
        final weight = d1 == d2 ? 1 : 2; // non-doubles appear twice as often

        // Find opponent's best response.
        final oppState = state.copyWith(activePlayer: opponent);
        final oppTurns = _generator.generateAllLegalTurns(oppState, roll);

        double bestOppEquity = double.negativeInfinity;
        if (oppTurns.isEmpty) {
          // Opponent can't move — evaluate current position.
          bestOppEquity = -_evaluateForVariant(state, opponent, variant);
        } else {
          for (final oppTurn in oppTurns) {
            final resultBoard = _engine.applyMoves(oppState, oppTurn.moves);
            final equity = depth > 1
                ? _evaluateAtDepth(resultBoard, player, depth - 1, variant: variant)
                : _evaluateForVariant(resultBoard, player, variant);
            if (equity > bestOppEquity) bestOppEquity = equity;
          }
          // Opponent picks the move worst for us (best for them).
          bestOppEquity = -bestOppEquity;
        }

        totalEquity += bestOppEquity * weight;
        rollCount += weight;
      }
    }

    return totalEquity / rollCount;
  }

  /// Select a turn based on difficulty noise and top-move filtering.
  Turn _selectByDifficulty(List<_ScoredTurn> scored, DifficultyLevel difficulty) {
    final noise = difficulty.noiseFactor;
    final topFraction = difficulty.topMoveFraction;

    // Add noise to scores.
    final noised = scored.map((s) {
      final noisyEquity = s.equity + (_rng.nextDouble() - 0.5) * 2 * noise;
      return _ScoredTurn(s.turn, noisyEquity);
    }).toList();

    // Sort again with noise applied.
    noised.sort((a, b) => b.equity.compareTo(a.equity));

    // Take top fraction.
    final topCount = (noised.length * topFraction).ceil().clamp(1, noised.length);
    final candidates = noised.sublist(0, topCount);

    // Weighted random from candidates (higher equity = more likely).
    return _weightedRandom(candidates);
  }

  /// Weighted random selection — better moves more likely.
  Turn _weightedRandom(List<_ScoredTurn> candidates) {
    if (candidates.length == 1) return candidates.first.turn;

    // Shift scores so minimum is 0, then use as weights.
    final minEquity = candidates.last.equity;
    final weights = candidates
        .map((c) => (c.equity - minEquity) + 0.01) // small epsilon
        .toList();
    final totalWeight = weights.reduce((a, b) => a + b);

    var roll = _rng.nextDouble() * totalWeight;
    for (int i = 0; i < candidates.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return candidates[i].turn;
    }

    return candidates.last.turn;
  }

  /// Whether the AI should offer a double at the current position.
  ///
  /// Uses a simple equity threshold: double if position equity > 0.15
  /// (i.e. the AI believes it's winning by a meaningful margin).
  /// At lower difficulties, the AI is less aggressive with doubling.
  bool shouldOfferDouble(BoardState state, DifficultyLevel difficulty) {
    final player = state.activePlayer;
    final equity = _evaluator.evaluate(state, player);

    // Threshold varies by difficulty — harder AI doubles more aggressively.
    final threshold = switch (difficulty) {
      DifficultyLevel.easy => 0.40,
      DifficultyLevel.easyWithHelp => 0.40,
      DifficultyLevel.medium => 0.25,
      DifficultyLevel.hard => 0.15,
      DifficultyLevel.pappous => 0.10,
    };

    // Add some randomness so it's not robotic.
    final noise = (_rng.nextDouble() - 0.5) * difficulty.noiseFactor;
    return (equity + noise) > threshold;
  }

  /// Whether the AI should accept a double offered by the opponent.
  ///
  /// Uses the standard 25% "take point" heuristic: accept if win probability
  /// is roughly >= 25% (equity >= -0.50 on our scale).
  bool shouldAcceptDouble(BoardState state, DifficultyLevel difficulty) {
    final player = state.activePlayer == 1 ? 2 : 1; // AI is the non-active player
    final equity = _evaluator.evaluate(state, player);

    // Drop threshold: if position is worse than this, decline.
    final dropThreshold = switch (difficulty) {
      DifficultyLevel.easy => -0.60, // easy AI accepts more liberally
      DifficultyLevel.easyWithHelp => -0.60,
      DifficultyLevel.medium => -0.50,
      DifficultyLevel.hard => -0.45,
      DifficultyLevel.pappous => -0.40, // pappous drops more aggressively
    };

    final noise = (_rng.nextDouble() - 0.5) * difficulty.noiseFactor;
    return (equity + noise) > dropThreshold;
  }

  /// Evaluate the quality of a player's move for teaching.
  /// Returns the equity loss compared to the best move.
  double evaluateMoveLoss(
    BoardState stateBefore,
    BoardState stateAfter,
    DiceRoll roll,
    int player,
  ) {
    final turns = _generator.generateAllLegalTurns(stateBefore, roll);
    if (turns.isEmpty) return 0;

    double bestEquity = double.negativeInfinity;
    for (final turn in turns) {
      final resultBoard = _engine.applyMoves(stateBefore, turn.moves);
      final equity = _evaluator.evaluate(resultBoard, player);
      if (equity > bestEquity) bestEquity = equity;
    }

    final actualEquity = _evaluator.evaluate(stateAfter, player);
    return (bestEquity - actualEquity).clamp(0, 2.0);
  }

  /// Public position evaluation for teaching mode UI.
  double evaluatePosition(BoardState state, int player, {
    GameVariant variant = GameVariant.portes,
  }) {
    return _evaluateForVariant(state, player, variant);
  }
}

class _ScoredTurn {
  final Turn turn;
  final double equity;

  const _ScoredTurn(this.turn, this.equity);
}

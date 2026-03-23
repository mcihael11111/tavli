import '../../../data/models/board_state.dart';

/// Board evaluator tuned for Fevga (running variant).
///
/// Key differences from Portes:
/// - No hitting at all — pure race with blocking
/// - Single checker blocks, so blocking is more impactful
/// - Max 5-prime limit means strategic placement matters
/// - Advancement from starting point is critical (all 15 start together)
class FevgaEvaluator {
  const FevgaEvaluator();

  /// Evaluate from [player]'s perspective. Higher = better.
  double evaluate(BoardState state, int player) {
    final opp = player == 1 ? 2 : 1;
    double score = 0;

    // ── Pip count advantage (most important in a race game) ──
    final myPips = state.pipCount(player);
    final oppPips = state.pipCount(opp);
    score += (oppPips - myPips) * 0.004;

    // ── Borne off advantage ──────────────────────────────────
    score += state.borneOffCount(player) * 0.07;
    score -= state.borneOffCount(opp) * 0.07;

    // ── Blocking value (single checker blocks in Fevga) ──────
    int myBlocks = 0;
    int oppBlocks = 0;
    for (int i = 0; i < 24; i++) {
      if (state.checkerCount(i, player) >= 1) myBlocks++;
      if (state.checkerCount(i, opp) >= 1) oppBlocks++;
    }
    score += myBlocks * 0.02;
    score -= oppBlocks * 0.015;

    // ── Consecutive blocks (primes — very powerful) ──────────
    score += _longestBlock(state, player) * 0.08;
    score -= _longestBlock(state, opp) * 0.06;

    // ── Spread bonus — getting off the starting point ────────
    final startPoint = player == 1 ? 0 : 12;
    final onStart = state.checkerCount(startPoint, player);
    if (onStart > 10) {
      score -= 0.1; // Too many still on start.
    } else if (onStart > 5) {
      score -= 0.05;
    }

    // ── Home board presence ──────────────────────────────────
    int homeCount = 0;
    if (player == 1) {
      for (int i = 18; i <= 23; i++) {
        if (state.points[i] > 0) homeCount += state.points[i];
      }
    } else {
      for (int i = 6; i <= 11; i++) {
        if (state.points[i] < 0) homeCount += -state.points[i];
      }
    }
    score += homeCount * 0.01;

    return score.clamp(-1.0, 1.0);
  }

  /// Longest consecutive block sequence.
  int _longestBlock(BoardState state, int player) {
    int longest = 0;
    int current = 0;
    for (int i = 0; i < 24; i++) {
      if (state.checkerCount(i, player) >= 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
    return longest;
  }
}

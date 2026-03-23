import '../../../data/models/board_state.dart';

/// Board evaluator tuned for Plakoto (pinning variant).
///
/// Key differences from Portes:
/// - Pins are extremely valuable (opponent can't move)
/// - No blots concept (single checkers can be pinned, not hit)
/// - Mama detection is critical
/// - Advancement matters more (all start on one point)
class PlakotoEvaluator {
  const PlakotoEvaluator();

  /// Evaluate from [player]'s perspective. Higher = better.
  double evaluate(BoardState state, int player) {
    final opp = player == 1 ? 2 : 1;
    double score = 0;

    // ── Pip count advantage ──────────────────────────────────
    final myPips = state.pipCount(player);
    final oppPips = state.pipCount(opp);
    score += (oppPips - myPips) * 0.003;

    // ── Borne off advantage ──────────────────────────────────
    score += state.borneOffCount(player) * 0.07;
    score -= state.borneOffCount(opp) * 0.07;

    // ── Pins — very valuable in Plakoto ──────────────────────
    for (final entry in state.pins.entries) {
      if (entry.value == opp) {
        // We pinned an opponent checker — very good.
        score += 0.15;
      } else if (entry.value == player) {
        // Our checker is pinned — very bad.
        score -= 0.15;
      }
    }

    // ── Mama threat ──────────────────────────────────────────
    // If opponent is pinned on their starting point, massive bonus.
    if (player == 1 && state.pins[23] == 2) {
      score += 0.4; // Mama against P2.
    } else if (player == 2 && state.pins[0] == 1) {
      score += 0.4; // Mama against P1.
    }
    // If WE are mama'd, massive penalty.
    if (player == 1 && state.pins[0] == 1) {
      score -= 0.5;
    } else if (player == 2 && state.pins[23] == 2) {
      score -= 0.5;
    }

    // ── Spread / advancement ─────────────────────────────────
    // Having checkers spread out is better than piled on start.
    int spreadCount = 0;
    for (int i = 0; i < 24; i++) {
      if (state.checkerCount(i, player) > 0) spreadCount++;
    }
    score += spreadCount * 0.02;

    // ── Points made (blocking) ───────────────────────────────
    int pointsMade = 0;
    for (int i = 0; i < 24; i++) {
      if (state.checkerCount(i, player) >= 2) pointsMade++;
    }
    score += pointsMade * 0.03;

    return score.clamp(-1.0, 1.0);
  }
}

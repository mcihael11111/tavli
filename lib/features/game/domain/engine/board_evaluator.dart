import '../../data/models/board_state.dart';

/// Evaluates board positions for AI move selection.
///
/// Uses a heuristic-based evaluation. Tuned weights based on
/// backgammon principles: primes are very strong, blots are dangerous,
/// anchors in opponent's home board provide safety.
class BoardEvaluator {
  const BoardEvaluator();

  /// Evaluate the position from [player]'s perspective.
  /// Returns a value where higher = better for [player].
  /// Range is roughly -1.0 to 1.0.
  double evaluate(BoardState state, int player) {
    final opp = player == 1 ? 2 : 1;
    double score = 0;

    // ── Pip count advantage ──────────────────────────────────
    final myPips = state.pipCount(player);
    final oppPips = state.pipCount(opp);
    score += (oppPips - myPips) * 0.002;

    // ── Borne off advantage ──────────────────────────────────
    score += state.borneOffCount(player) * 0.06;
    score -= state.borneOffCount(opp) * 0.06;

    // ── Bar penalty ──────────────────────────────────────────
    score -= state.barCount(player) * 0.18;
    score += state.barCount(opp) * 0.18;

    // ── Home board strength ──────────────────────────────────
    score += _homeStrength(state, player) * 0.12;
    score -= _homeStrength(state, opp) * 0.12;

    // ── Blots exposed ────────────────────────────────────────
    score -= _countBlots(state, player) * 0.10;
    score += _countBlots(state, opp) * 0.10;

    // ── Points made (blocking) ───────────────────────────────
    score += _pointsMade(state, player) * 0.035;

    // ── Connectivity (prime potential) ───────────────────────
    score += _longestPrime(state, player) * 0.08;
    score -= _longestPrime(state, opp) * 0.04;

    // ── Anchor in opponent's home board ──────────────────────
    score += _anchorBonus(state, player) * 0.04;

    // ── Race position (when all contact is broken) ───────────
    if (_isRace(state)) {
      // In a race, pip count matters much more.
      score += (oppPips - myPips) * 0.004;
    }

    return score.clamp(-1.0, 1.0);
  }

  /// Count how many points in [player]'s home board have 2+ checkers.
  double _homeStrength(BoardState state, int player) {
    int count = 0;
    if (player == 1) {
      for (int i = 0; i <= 5; i++) {
        if (state.points[i] >= 2) count++;
      }
    } else {
      for (int i = 18; i <= 23; i++) {
        if (state.points[i] <= -2) count++;
      }
    }
    return count.toDouble();
  }

  /// Count blots (single checkers exposed to being hit).
  int _countBlots(BoardState state, int player) {
    int count = 0;
    for (int i = 0; i < 24; i++) {
      if (player == 1 && state.points[i] == 1) count++;
      if (player == 2 && state.points[i] == -1) count++;
    }
    return count;
  }

  /// Count total points made (2+ checkers) across the board.
  int _pointsMade(BoardState state, int player) {
    int count = 0;
    for (int i = 0; i < 24; i++) {
      if (player == 1 && state.points[i] >= 2) count++;
      if (player == 2 && state.points[i] <= -2) count++;
    }
    return count;
  }

  /// Longest consecutive prime (sequence of made points).
  int _longestPrime(BoardState state, int player) {
    int longest = 0;
    int current = 0;
    for (int i = 0; i < 24; i++) {
      final hasMade = player == 1
          ? state.points[i] >= 2
          : state.points[i] <= -2;
      if (hasMade) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
    return longest;
  }

  /// Bonus for having an anchor (made point) in opponent's home board.
  double _anchorBonus(BoardState state, int player) {
    if (player == 1) {
      // P1's anchor would be in P2's home (18-23).
      for (int i = 18; i <= 23; i++) {
        if (state.points[i] >= 2) return 1.0;
      }
    } else {
      // P2's anchor in P1's home (0-5).
      for (int i = 0; i <= 5; i++) {
        if (state.points[i] <= -2) return 1.0;
      }
    }
    return 0.0;
  }

  /// Detect if the position is a pure race (no contact between players).
  bool _isRace(BoardState state) {
    if (state.bar1 > 0 || state.bar2 > 0) return false;

    // Find the furthest-back checker for each player.
    int p1Last = -1;
    int p2First = 24;
    for (int i = 23; i >= 0; i--) {
      if (state.points[i] > 0 && p1Last == -1) p1Last = i;
      if (state.points[i] < 0 && i < p2First) p2First = i;
    }

    // If P1's last checker is past all of P2's checkers, it's a race.
    return p1Last < p2First;
  }
}

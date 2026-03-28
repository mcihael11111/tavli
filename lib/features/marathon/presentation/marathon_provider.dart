import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/data/models/game_result.dart';
import '../../../core/constants/tradition.dart';
import '../domain/marathon_state.dart';

/// Provider managing marathon match state.
class MarathonNotifier extends StateNotifier<MarathonState?> {
  MarathonNotifier() : super(null);

  /// Start a new marathon for the given tradition.
  void startMarathon(Tradition tradition, {int targetScore = 5}) {
    state = MarathonState.forTradition(tradition, targetScore: targetScore);
  }

  /// Record the result of the current game and advance.
  void recordGameResult(GameResult result) {
    if (state == null) return;
    state = state!.recordResult(result);
  }

  /// Whether a marathon is currently active.
  bool get isActive => state != null && !state!.isComplete;

  /// End the marathon (abandon).
  void endMarathon() {
    state = null;
  }
}

/// Global marathon state provider.
final marathonProvider =
    StateNotifierProvider<MarathonNotifier, MarathonState?>((ref) {
  return MarathonNotifier();
});

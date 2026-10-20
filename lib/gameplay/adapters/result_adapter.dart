/// Core `GameResult` -> app `GameResult` (design §3, game end).
library;

import 'package:tavli/features/game/data/models/game_result.dart' as app;
import 'package:tavli_core/tavli_core.dart' as core;

/// The app result for [r], or null for a draw (the app model has no draw;
/// the caller shows a draw without recording a win for either side).
///
/// - Winner: `Side.one` -> 1, `Side.two` -> 2. The cube value is carried.
/// - `single`, `gammon` and `triple` map to single, gammon and backgammon.
/// - `mother` (2 points, no cube) maps to gammon, which scores 2.
/// - `checkersRemaining`, `resign` and `timeout` map by the points before
///   the cube: 1 or less single, 2 gammon, 3 or more backgammon. The app
///   model's `points` is type x cube, so a checkers-remaining win of more
///   than 3 scores 3 there; callers needing the exact score use `r.points`.
app.GameResult? appResultOf(core.GameResult r) {
  final winner = r.winner;
  if (winner == null) return null;
  final type = switch (r.kind) {
    core.ResultKind.single => app.GameResultType.single,
    core.ResultKind.gammon => app.GameResultType.gammon,
    core.ResultKind.triple => app.GameResultType.backgammon,
    core.ResultKind.mother => app.GameResultType.gammon,
    core.ResultKind.draw => throw StateError('a draw has a winner: $r'),
    core.ResultKind.checkersRemaining ||
    core.ResultKind.resign ||
    core.ResultKind.timeout =>
      _byBasePoints(r.points ~/ r.cubeValue),
  };
  return app.GameResult(
    winner: winner == core.Side.one ? 1 : 2,
    type: type,
    cubeValue: r.cubeValue,
  );
}

app.GameResultType _byBasePoints(int base) => switch (base) {
      <= 1 => app.GameResultType.single,
      2 => app.GameResultType.gammon,
      _ => app.GameResultType.backgammon,
    };

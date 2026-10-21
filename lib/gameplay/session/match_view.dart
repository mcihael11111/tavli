/// The controller's state, read by the chrome through `select` (design §3).
library;

import 'package:flutter/foundation.dart';
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/game/data/models/game_result.dart' as app;
import 'package:tavli/features/game/domain/engine/variants/game_variant.dart';
import 'package:tavli/features/profile/data/achievements.dart';
import 'package:tavli_bot/tavli_bot.dart' show TurnAnalysis;
import 'package:tavli_core/tavli_core.dart';

import 'match_setup.dart';
import 'ui_selection.dart';

/// A toast-style message for the chrome; each new one has a new
/// [MatchView.noticeSeq].
sealed class MatchNotice {
  const MatchNotice();
}

/// [side] could not move with [dice] (G9).
final class TurnPassedNotice extends MatchNotice {
  const TurnPassedNotice(this.side, this.dice);
  final Side side;
  final List<int> dice;
}

/// Gul Bara: [to] now plays the cascade remainder [dice] (D16-B).
final class RemainderNotice extends MatchNotice {
  const RemainderNotice(this.to, this.dice);
  final Side to;
  final List<int> dice;
}

/// [by] answered a double: took it or dropped.
final class CubeAnswerNotice extends MatchNotice {
  const CubeAnswerNotice(this.by, {required this.took});
  final Side by;
  final bool took;
}

/// How a taught play rates (design §3 teaching thresholds).
enum PlayVerdict { good, inaccuracy, mistake }

/// Teaching: the end-of-turn feedback on the human's play.
final class TeachingFeedback extends MatchNotice {
  const TeachingFeedback(this.equityLoss);

  /// Best minus chosen play equity (≥ 0).
  final double equityLoss;

  /// > 0.04 a mistake, > 0.015 an inaccuracy (today's thresholds).
  PlayVerdict get verdict => equityLoss > 0.04
      ? PlayVerdict.mistake
      : equityLoss > 0.015
          ? PlayVerdict.inaccuracy
          : PlayVerdict.good;
}

/// How the match ended, for the screen to act on once.
sealed class MatchOutcome {
  const MatchOutcome();
}

/// Navigate to `/victory` with [extras]. Recording (vs bot only) is already
/// done, so [extras] carries `recorded: true` and the victory screen must
/// not record again.
final class GoVictory extends MatchOutcome {
  const GoVictory({
    required this.result,
    required this.difficulty,
    required this.variant,
    required this.mode,
    this.coinsEarned = 0,
    this.achievement,
  });

  final app.GameResult result;
  final DifficultyLevel difficulty;
  final GameVariant variant;
  final MatchMode mode;

  /// Coins awarded by the recording (win reward plus achievement rewards).
  final int coinsEarned;

  /// The first achievement the recording unlocked, for the toast.
  final Achievement? achievement;

  /// The `/victory` route extras.
  Map<String, Object?> get extras => {
        'result': result,
        'difficulty': difficulty,
        'variant': variant,
        'mode': mode == MatchMode.vsBot ? 'bot' : 'passPlay',
        'recorded': true,
        'coinsEarned': coinsEarned,
        if (achievement != null) 'achievement': achievement,
      };
}

/// The match ended in a draw (both mothers pinned, D9): the app result
/// model has no draw, so the screen shows a draw outcome itself and
/// nothing is recorded.
final class MatchDrawn extends MatchOutcome {
  const MatchDrawn(this.result);
  final GameResult result;
}

const Object _keep = Object();

@immutable
final class MatchView {
  const MatchView({
    required this.match,
    required this.selection,
    required this.viewer,
    this.busy = false,
    this.paused = false,
    this.lastAnalysis,
    this.handoff,
    this.passAck,
    this.notice,
    this.noticeSeq = 0,
    this.outcome,
  });

  final MatchState match;
  final UiSelection selection;

  /// The side the board is drawn from: the human vs bot; in pass & play
  /// the side holding the device.
  final Side viewer;

  /// The bot is thinking or acting; human intents are ignored.
  final bool busy;

  /// The pause menu is open: the bot loop waits at its next await.
  final bool paused;

  /// Teaching: the latest analysis of the current steps.
  final TurnAnalysis? lastAnalysis;

  /// Pass & play: the device must be handed to this side
  /// (`acknowledgeHandoff`).
  final Side? handoff;

  /// Auto-pass off: this side's passed turn waits for `acknowledgePass`.
  final Side? passAck;

  final MatchNotice? notice;
  final int noticeSeq;

  /// Set once when the match is over.
  final MatchOutcome? outcome;

  GameState get game => match.game;

  /// The side whose double awaits an answer, if any.
  Side? get pendingDouble => game.cube.offeredBy;

  /// A complete play waits for Confirm (`moveConfirmation` on).
  bool get awaitingConfirm =>
      game.phase == GamePhase.moving && !busy && game.node.isComplete;

  /// A game of a longer match is over; `nextGame` starts the next one.
  bool get betweenGames => game.phase == GamePhase.gameOver && !match.isOver;

  MatchView copyWith({
    MatchState? match,
    UiSelection? selection,
    Side? viewer,
    bool? busy,
    bool? paused,
    Object? lastAnalysis = _keep,
    Object? handoff = _keep,
    Object? passAck = _keep,
    MatchNotice? notice,
    MatchOutcome? outcome,
  }) =>
      MatchView(
        match: match ?? this.match,
        selection: selection ?? this.selection,
        viewer: viewer ?? this.viewer,
        busy: busy ?? this.busy,
        paused: paused ?? this.paused,
        lastAnalysis: identical(lastAnalysis, _keep)
            ? this.lastAnalysis
            : lastAnalysis as TurnAnalysis?,
        handoff: identical(handoff, _keep) ? this.handoff : handoff as Side?,
        passAck: identical(passAck, _keep) ? this.passAck : passAck as Side?,
        notice: notice ?? this.notice,
        noticeSeq: notice == null ? noticeSeq : noticeSeq + 1,
        outcome: outcome ?? this.outcome,
      );
}

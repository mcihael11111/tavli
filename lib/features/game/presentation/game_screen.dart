import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/providers/accessibility_providers.dart';
import '../../../flame_game/tavli_game.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/copy_service.dart';
import '../../../shared/services/settings_service.dart';
import '../../ai/personality/bot_personality.dart';
import 'package:flutter/semantics.dart';
import '../data/models/board_state.dart';
import '../data/models/game_state.dart';
import '../../ai/difficulty/difficulty_level.dart';
import '../../ai/engine/ai_player.dart';
import '../../ai/mikhail/dialogue_event.dart';
import '../../ai/mikhail/dialogue_system.dart';
import '../../ai/pacing/turn_pacing.dart';
import '../domain/engine/variants/game_variant.dart';
import 'providers/game_provider.dart';

/// Main game screen: hosts the Flame board + Flutter UI overlay.
class GameScreen extends ConsumerStatefulWidget {
  final DifficultyLevel difficulty;
  final GameVariant variant;

  const GameScreen({
    super.key,
    required this.difficulty,
    this.variant = GameVariant.portes,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late TavliGame _game;
  late AiPlayer _aiPlayer;
  late DialogueSystem _dialogue;
  late AudioService _audio;
  late TurnPacing _pacing;
  bool _aiThinking = false;
  bool _navigatingToVictory = false;
  bool _animationInProgress = false;
  bool _showOpeningResult = false;

  /// When non-null, [_handleAiTurn] blocks at its await checkpoints until
  /// this completer resolves. Set when the pause menu opens so an in-flight
  /// AI turn doesn't silently advance behind the modal.
  Completer<void>? _pauseLock;

  Future<void> _awaitResume() async {
    final lock = _pauseLock;
    if (lock != null && !lock.isCompleted) {
      await lock.future;
    }
  }

  /// Fixed reserved height for the action area (ROLL button / move controls).
  /// Keeping this constant prevents the board from jumping when the button
  /// content changes between ROLL, undo/complete, and empty.
  static const double _actionAreaHeight = 72;

  BotPersonality get _personality => SettingsService.instance.botPersonality;

  @override
  void initState() {
    super.initState();
    _aiPlayer = AiPlayer();
    _dialogue = DialogueSystem();
    _audio = AudioService();
    _pacing = TurnPacing.forBot(widget.difficulty, _personality);

    final boardSet = SettingsService.instance.boardSet;
    final checkerSet = SettingsService.instance.checkerSet;
    final diceSet = SettingsService.instance.diceSet;

    _game = TavliGame(
      boardState: BoardState.initial(),
      onCheckerTapped: _onCheckerTapped,
      onDestinationTapped: _onDestinationTapped,
      onDiceRollRequested: _onDiceRoll,
      boardSet: boardSet,
      checkerSet: checkerSet,
      diceSet: diceSet,
    );
    _game.setDiceRattleDuration(_pacing.diceRattle);

    // Allow landscape for gameplay.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).newGame(
        difficulty: widget.difficulty,
        variant: widget.variant,
      );
      _dialogue.trigger(DialogueEvent.gameStart, widget.difficulty, personality: _personality);
      _announce('Game starting. Tap to roll for first move.');
      if (mounted) setState(() {});

      // Drive all state-transition side-effects from listenManual, which
      // fires exactly once per state change. build() is for rendering only
      // — mutating state from build triggers rebuild loops under stress.
      ref.listenManual(gameProvider, (previous, next) {
        final phaseChanged = previous?.phase != next.phase;

        // Game over.
        if (next.phase == GamePhase.gameOver && !_navigatingToVictory) {
          if (next.result?.winner == 1) {
            _audio.playSfx(SfxType.gameWin);
            HapticFeedback.heavyImpact();
            _dialogue.trigger(DialogueEvent.playerWin, widget.difficulty, personality: _personality);
            _announce('You win!');
          } else {
            _audio.playSfx(SfxType.gameLose);
            _announce('You lose. ${_personality.displayName} wins.');
          }
          _navigateToVictory(next);
          return;
        }

        // Turn complete → advance. Guard on phase transition so we don't
        // re-advance if an unrelated field on the same phase changes.
        if (phaseChanged && next.phase == GamePhase.turnComplete) {
          Future.microtask(() {
            if (!mounted) return;
            ref.read(gameProvider.notifier).nextTurn();
          });
          return;
        }

        // AI's turn to roll.
        if (phaseChanged &&
            next.phase == GamePhase.playerTurnStart &&
            next.isAiTurn &&
            !_aiThinking) {
          Future.microtask(() {
            if (mounted) _handleAiTurn();
          });
          return;
        }

        // Opening roll: performOpeningRoll transitions straight to
        // movingCheckers with dice already rolled. If the AI won the toss
        // we need to kick off its turn here, since the playerTurnStart
        // branch above never fires in the opening flow. _handleAiTurn
        // no-ops its rollDice() call when phase is movingCheckers, so it
        // jumps straight to selecting a turn with the existing dice.
        if (phaseChanged &&
            next.phase == GamePhase.movingCheckers &&
            next.isAiTurn &&
            !_aiThinking) {
          Future.microtask(() {
            if (mounted) _handleAiTurn();
          });
          return;
        }

        // Player offered double → AI decides.
        if (phaseChanged &&
            next.phase == GamePhase.doubleOffered &&
            next.doubleOfferedBy == 1 &&
            !_aiThinking) {
          Future.microtask(() {
            if (mounted) _handleAiDoubleResponse();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  /// Announce to screen readers.
  void _announce(String message) {
    SemanticsService.sendAnnouncement(View.of(context), message, TextDirection.ltr);
  }

  void _onCheckerTapped(int pointIndex) {
    if (_animationInProgress) return;
    final gs = ref.read(gameProvider);
    if (!gs.isPlayerTurn) return;
    if (gs.phase != GamePhase.movingCheckers) return;

    // Tap selected checker again → deselect.
    if (gs.selectedPoint == pointIndex) {
      ref.read(gameProvider.notifier).clearSelection();
      return;
    }

    HapticFeedback.selectionClick();
    ref.read(gameProvider.notifier).selectChecker(pointIndex);

    // Check if any moves are available after selection.
    final afterSelect = ref.read(gameProvider);
    if (afterSelect.availableMovesForSelected.isEmpty) {
      _audio.playSfx(SfxType.checkerPlace);
      _announce('No moves available from point ${pointIndex + 1}');
    } else {
      _audio.playSfx(SfxType.checkerPickup);
      _announce('Checker selected on point ${pointIndex + 1}');
    }
  }

  Future<void> _onDestinationTapped(int toPoint) async {
    if (_animationInProgress) return;
    final gs = ref.read(gameProvider);
    if (!gs.isPlayerTurn) return;

    // Teaching mode: grab the quality of the chosen destination BEFORE the
    // move is applied — after makeMove() the highlight state is cleared.
    MoveQuality? chosenQuality;
    if (widget.difficulty.isTeaching) {
      final qualities = _computeMoveQualities();
      chosenQuality = qualities?[toPoint];
    }

    // Determine SFX before the move is applied.
    final move = gs.availableMovesForSelected
        .where((m) => m.toPoint == toPoint)
        .firstOrNull;
    SfxType? landingSfx;
    if (move != null) {
      if (move.isHit) {
        landingSfx = SfxType.checkerHit;
        _announce('Hit! Opponent checker sent to bar.');
      } else if (move.isBearOff) {
        landingSfx = SfxType.checkerBearOff;
        _announce('Checker borne off.');
      } else if (move.isBarEntry) {
        landingSfx = SfxType.checkerBarEntry;
        _announce('Entered from bar to point ${toPoint + 1}.');
      } else {
        landingSfx = SfxType.checkerPlace;
        _announce('Moved to point ${toPoint + 1}.');
      }
    }

    // Block taps for the duration of the animation. An earlier revision
    // unblocked immediately after committing state to feel snappier, but a
    // QA pass found that opened a stale-state race: the player could tap a
    // checker mid-animation while game_provider's selectChecker() ran against
    // the *new* board, but the visible state was still the old one. Result
    // was occasional illegal-looking moves on rapid double taps.
    //
    // The animation is now 130 ms (down from 220 ms) so the perceived block
    // is short while still giving the renderer time to commit the new state
    // before the next tap is accepted.
    _animationInProgress = true;
    ref.read(gameProvider.notifier).makeMove(toPoint);

    try {
      await _game.updateBoardState(ref.read(gameProvider).board);
      if (landingSfx != null) {
        _audio.playSfx(landingSfx);
        HapticFeedback.lightImpact();
      }
    } finally {
      _animationInProgress = false;
    }

    // Teaching mode — immediate per-move signal.
    // Haptic intensity tracks move quality so the learner gets feedback
    // each move. Before QA H11 the only visible per-move signal was haptic;
    // a player who made a poor opening move followed by legal follow-ups
    // could finish the turn with an "overall OK" summary that hid the
    // opening mistake. We now also surface a short SnackBar on the spot
    // for poor moves — short enough not to stack on 4-move doubles.
    if (chosenQuality != null && chosenQuality == MoveQuality.poor) {
      HapticFeedback.heavyImpact();
      _announce('That move may have been a mistake.');
      if (widget.difficulty.isTeaching && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TavliCopy.teachingBadMove),
            duration: const Duration(milliseconds: 900),
            behavior: SnackBarBehavior.floating,
            backgroundColor: TavliColors.surface,
          ),
        );
      }
    }

    // End-of-turn teaching summary (Easy+Help).
    if (widget.difficulty.isTeaching) {
      _checkTeachingFeedback();
    }
  }

  void _onDiceRoll() {
    final gs = ref.read(gameProvider);

    // Opening roll ceremony.
    if (gs.phase == GamePhase.waitingForFirstRoll) {
      _audio.playSfx(SfxType.diceRoll);
      HapticFeedback.mediumImpact();
      ref.read(gameProvider.notifier).performOpeningRoll();
      final after = ref.read(gameProvider);
      final p = after.openingRollPlayer ?? 0;
      final o = after.openingRollOpponent ?? 0;
      final botName = _personality.displayName;
      final who = p > o ? 'You go' : '$botName goes';
      _announce('You rolled $p, $botName rolled $o. $who first.');
      // Show result briefly before dismissing overlay.
      setState(() => _showOpeningResult = true);
      // Trimmed from 1500ms — the opening overlay was the worst lag the
      // player saw before their first move. 700ms is enough to read the result.
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _showOpeningResult = false);
      });
      return;
    }

    if (gs.phase != GamePhase.playerTurnStart) return;
    if (!gs.isPlayerTurn) return;
    _audio.playSfx(SfxType.diceRoll);
    HapticFeedback.mediumImpact();
    ref.read(gameProvider.notifier).rollDice();

    final afterRoll = ref.read(gameProvider);

    // Check if player has no legal moves after rolling.
    if (afterRoll.phase == GamePhase.turnComplete) {
      _announce('No legal moves. Your turn is skipped.');
      // Visual feedback — previously the dialogue bar masked this; now we
      // surface a transient SnackBar so sighted players know why the turn
      // passes to the AI without action.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TavliCopy.noLegalMovesSkipped),
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (afterRoll.currentRoll != null) {
      _announce('You rolled ${afterRoll.currentRoll!.die1} and ${afterRoll.currentRoll!.die2}.');
      if (afterRoll.currentRoll!.isDoubles) {
        _dialogue.trigger(DialogueEvent.playerRollDoubles, widget.difficulty, personality: _personality);
        if (mounted) setState(() {});
        _audio.playSfx(SfxType.diceDoublesChime);
        HapticFeedback.heavyImpact();
      }
    }
  }

  /// Teaching mode: evaluate the player's last move and give feedback.
  ///
  /// After the dialogue bar was removed, the old `_dialogue.trigger(...)`
  /// calls produced no visible feedback — teaching mode was effectively
  /// broken for sighted players. We now surface the verdict via a transient
  /// SnackBar (consistent with the turn-skip feedback pattern) AND keep the
  /// dialogue triggers so the victory screen still has persona context.
  void _checkTeachingFeedback() {
    final gs = ref.read(gameProvider);
    if (gs.currentTurnMoves.isEmpty) return;
    if (gs.remainingDice.isNotEmpty) return; // wait until turn is fully played

    // Pre-turn baseline. currentTurnMoves is non-empty (checked above), so the
    // undoStack MUST hold at least the pre-turn snapshot — if it doesn't we
    // have no meaningful baseline (opening roll or state lost) and must skip
    // rather than silently compare board to itself (QA H12).
    if (gs.undoStack.isEmpty) return;
    final boardBefore = gs.undoStack.first;
    final equityLoss = _aiPlayer.evaluateMoveLoss(
      boardBefore, gs.board,
      gs.currentRoll!,
      1, // player
      variant: widget.variant,
    );

    final String message;
    final Color bg;
    if (equityLoss > 0.04) {
      _dialogue.trigger(DialogueEvent.teachingMistakeExplain, widget.difficulty, personality: _personality);
      message = TavliCopy.teachingMistake;
      bg = TavliColors.error;
      _announce(message);
    } else if (equityLoss > 0.015) {
      _dialogue.trigger(DialogueEvent.playerBadMove, widget.difficulty, personality: _personality);
      message = TavliCopy.teachingBadMove;
      bg = TavliColors.surface;
      _announce(message);
    } else {
      _dialogue.trigger(DialogueEvent.playerGoodMove, widget.difficulty, personality: _personality);
      message = TavliCopy.teachingGoodMove;
      bg = TavliColors.success;
      _announce(message);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1800),
          behavior: SnackBarBehavior.floating,
          backgroundColor: bg,
        ),
      );
      setState(() {});
    }
  }

  /// Teaching mode: compute move quality for each available move.
  Map<int, MoveQuality>? _computeMoveQualities() {
    if (!widget.difficulty.isTeaching) return null;

    final gs = ref.read(gameProvider);
    if (gs.availableMovesForSelected.isEmpty) return null;

    if (gs.availableMovesForSelected.length <= 1) {
      return {gs.availableMovesForSelected.first.toPoint: MoveQuality.best};
    }

    // Evaluate each destination using variant-aware evaluator.
    final qualities = <int, MoveQuality>{};
    final moves = gs.availableMovesForSelected;
    final scores = <int, double>{};

    for (final move in moves) {
      final after = ref.read(gameProvider.notifier).peekApplyMove(move);
      if (after != null) {
        scores[move.toPoint] = _aiPlayer.evaluatePosition(after, 1, variant: widget.variant);
      }
    }

    if (scores.isEmpty) return null;

    final bestScore = scores.values.reduce((a, b) => a > b ? a : b);
    for (final entry in scores.entries) {
      final diff = bestScore - entry.value;
      if (diff <= 0.01) {
        qualities[entry.key] = MoveQuality.best;
      } else if (diff <= 0.03) {
        qualities[entry.key] = MoveQuality.good;
      } else if (diff <= 0.08) {
        qualities[entry.key] = MoveQuality.acceptable;
      } else {
        qualities[entry.key] = MoveQuality.poor;
      }
    }

    return qualities;
  }

  void _navigateToVictory(GameState gs) {
    if (_navigatingToVictory) return;
    if (gs.result == null) return;
    _navigatingToVictory = true;

    // Small delay so the player sees the final board state.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      context.go('/victory', extra: {
        'result': gs.result,
        'difficulty': widget.difficulty,
      });
    });
  }

  Future<void> _handleAiTurn() async {
    if (_aiThinking) return;
    _aiThinking = true;
    if (mounted) setState(() {});

    // Exception safety: if any awaited call throws (AI bug, bad state, etc.)
    // we must clear _aiThinking or the game is stuck in "bot is thinking"
    // forever. Existing inline resets stay for the legitimate early-return
    // paths; the finally block only kicks in when code actually throws.
    try {
    // Brief "thinking" beat — enough to register intent, short enough to
    // keep pace snappy. Now driven by TurnPacing so it varies per bot.
    await Future.delayed(_pacing.thinkingBeat);
    await _awaitResume();
    if (!mounted) { _aiThinking = false; return; }

    final notifier = ref.read(gameProvider.notifier);

    // AI considers doubling before rolling (if enabled for this difficulty).
    if (widget.difficulty.usesDoublingCube) {
      final gs = ref.read(gameProvider);
      if (_aiPlayer.shouldOfferDouble(gs.board, widget.difficulty, variant: widget.variant) &&
          gs.board.cubeOwner != 1) {
        // AI offers double — wait for player response via UI.
        notifier.aiOfferDouble();
        _aiThinking = false;
        if (mounted) setState(() {});
        return;
      }
    }

    // AI rolls.
    _audio.playSfx(SfxType.diceRoll);
    notifier.rollDice();
    // Short breather so the player sees the dice before movement starts.
    await Future.delayed(_pacing.dicePostRollBreather);
    await _awaitResume();
    if (!mounted) { _aiThinking = false; return; }

    final afterRoll = ref.read(gameProvider);

    if (afterRoll.currentRoll == null || afterRoll.phase == GamePhase.turnComplete) {
      // No legal moves — announce and advance.
      _announce('${_personality.displayName} has no legal moves. Turn skipped.');
      _dialogue.trigger(DialogueEvent.mikhailRollBad, widget.difficulty, personality: _personality);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TavliCopy.opponentNoMovesSkipped(_personality.displayName),
            ),
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {});
      }
      if (afterRoll.phase == GamePhase.turnComplete) {
        notifier.nextTurn();
      }
      _aiThinking = false;
      return;
    }

    // Dialogue for doubles.
    if (afterRoll.currentRoll!.isDoubles) {
      _dialogue.trigger(DialogueEvent.mikhailRollDoubles, widget.difficulty, personality: _personality);
      if (mounted) setState(() {});
    }

    // Use AI to pick best turn, then apply moves through the notifier.
    final aiTurn = _aiPlayer.selectTurn(
      afterRoll.board,
      afterRoll.currentRoll!,
      widget.difficulty,
      variant: widget.variant,
    );

    if (aiTurn != null) {
      for (final move in aiTurn.moves) {
        // Gap between successive AI moves — just long enough to be legible.
        await Future.delayed(_pacing.interMoveSettle);
        await _awaitResume();
        if (!mounted) { _aiThinking = false; return; }

        // Apply via notifier — selectChecker + makeMove.
        notifier.selectChecker(move.fromPoint);
        notifier.makeMove(move.toPoint);

        // Animate the checker sliding to its new position.
        final currentBoard = ref.read(gameProvider).board;
        await _game.updateBoardState(currentBoard);
        if (!mounted) { _aiThinking = false; return; }

        // Play landing SFX after animation completes.
        if (move.isHit) {
          _audio.playSfx(SfxType.checkerHit);
          _dialogue.trigger(DialogueEvent.mikhailHit, widget.difficulty, personality: _personality);
          if (mounted) setState(() {});
        } else if (move.isBearOff) {
          _audio.playSfx(SfxType.checkerBearOff);
        } else {
          _audio.playSfx(SfxType.checkerPlace);
        }

        final current = ref.read(gameProvider);
        if (current.phase == GamePhase.gameOver) {
          _dialogue.trigger(DialogueEvent.mikhailWin, widget.difficulty, personality: _personality);
          if (mounted) setState(() {});
          _navigateToVictory(current);
          _aiThinking = false;
          if (mounted) setState(() {});
          return;
        }
      }
    }

    // Tiny settle beat before handing control back to the player.
    await Future.delayed(_pacing.finalSettle);
    if (!mounted) { _aiThinking = false; return; }

    final afterMoves = ref.read(gameProvider);
    if (afterMoves.phase == GamePhase.gameOver) {
      _navigateToVictory(afterMoves);
    } else if (afterMoves.phase != GamePhase.playerTurnStart) {
      notifier.nextTurn();
    }

    _aiThinking = false;
    if (mounted) setState(() {});
    } catch (e, stack) {
      // Failsafe: guarantee the "thinking" flag clears so the player can act.
      // Log to stderr; a real build pipes this through reportError/Crashlytics.
      debugPrint('AI turn failed: $e\n$stack');
    } finally {
      if (_aiThinking) {
        _aiThinking = false;
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _handleAiDoubleResponse() async {
    if (_aiThinking) return;
    _aiThinking = true;
    if (mounted) setState(() {});

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) { _aiThinking = false; return; }

    final gs = ref.read(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    if (_aiPlayer.shouldAcceptDouble(gs.board, widget.difficulty, variant: widget.variant)) {
      _dialogue.trigger(DialogueEvent.aiWinning, widget.difficulty, personality: _personality);
      notifier.acceptDouble();
    } else {
      notifier.declineDouble();
    }

    _aiThinking = false;
    if (mounted) setState(() {});
  }

  void _playerAcceptsDouble() {
    ref.read(gameProvider.notifier).acceptDouble();
    // AI turn resumes automatically via listenManual in initState.
  }

  void _playerDeclinesDouble() {
    ref.read(gameProvider.notifier).declineDouble();
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameProvider);

    // Sync Flame visuals (highlights, dice).
    // Board state sync: always push state to Flame so undo, turn transitions,
    // and other non-animated state changes are reflected immediately.
    // The differ inside TavliGame handles animation vs instant based on context.
    if (_game.isLoaded) {
      if (!_animationInProgress && !_aiThinking) {
        _game.syncBoardState(gs.board);
      }

      if (gs.selectedPoint != null && gs.availableMovesForSelected.isNotEmpty) {
        _game.showHighlights(
          gs.availableMovesForSelected,
          moveQualities: _computeMoveQualities(),
        );
      } else {
        _game.clearHighlights();
      }

      if (gs.currentRoll != null) {
        _game.showDice(gs.currentRoll!.die1, gs.currentRoll!.die2, gs.remainingDice);
      } else {
        // Roll affordance during playerTurnStart is the Flutter ROLL button
        // below the board (see _buildRollButton). Do NOT also show the on-board
        // "TAP TO ROLL" pill — duplicate affordances confuse the player.
        _game.hideDice();
      }
    }

    // State-transition triggers (game-over, turn-complete → nextTurn,
    // AI turn, AI double response) are all driven by ref.listenManual in
    // initState. build() is rendering-only.

    final bgColor = (_aiThinking || gs.isAiTurn)
        ? TavliColors.botThinkingBg
        : TavliColors.primary;

    return AnimatedContainer(
      duration: ReducedMotion.duration(context, const Duration(milliseconds: 400)),
      color: bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(gs),
                  Expanded(
                    child: Stack(
                      children: [
                        Semantics(
                          label: 'Backgammon game board',
                          child: GameWidget(game: _game),
                        ),
                        if (_aiThinking)
                          Positioned(
                            top: 0, left: 0, right: 0,
                            child: _buildBotThinkingBanner(),
                          ),
                      ],
                    ),
                  ),
                  // Fixed-height action area prevents the board from shifting
                  // as the ROLL button / move-controls appear and disappear.
                  SizedBox(height: _actionAreaHeight, child: _buildActionArea(gs)),
                  _buildBottomBar(gs),
                ],
              ),
              // Opening roll overlay — stays visible briefly to show result.
              if (gs.phase == GamePhase.waitingForFirstRoll || _showOpeningResult)
                _buildOpeningRollOverlay(),
              // Doubling cube offer overlay.
              if (gs.phase == GamePhase.doubleOffered && gs.doubleOfferedBy == 2)
                _buildDoubleOfferOverlay(gs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotThinkingBanner() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: TavliSpacing.sm),
      color: TavliColors.botThinkingBanner,
      child: Center(
        child: Text(TavliCopy.botThinking,
          style: theme.textTheme.bodyLarge!.copyWith(
            color: TavliColors.light,
            fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.5,
          )),
      ),
    );
  }

  Widget _buildActionArea(GameState gs) {
    if (_aiThinking || gs.isAiTurn) return const SizedBox.shrink();

    // Ready to roll → big ROLL button.
    if (gs.phase == GamePhase.playerTurnStart && gs.isPlayerTurn) {
      return _buildRollButton();
    }

    // Moving checkers → undo + optional COMPLETE.
    if (gs.phase == GamePhase.movingCheckers && gs.isPlayerTurn) {
      return _buildMoveControls(gs);
    }

    return const SizedBox.shrink();
  }

  Widget _buildRollButton() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md, vertical: TavliSpacing.xs),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _onDiceRoll,
          style: ElevatedButton.styleFrom(
            backgroundColor: TavliColors.surface,
            foregroundColor: TavliColors.light,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TavliRadius.md),
            ),
          ),
          child: Text(TavliCopy.roll,
            style: theme.textTheme.bodyLarge!.copyWith(
              fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 2)),
        ),
      ),
    );
  }

  Widget _buildMoveControls(GameState gs) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md, vertical: TavliSpacing.xs),
      child: Row(
        children: [
          const Spacer(),
          // COMPLETE button for trivial bear-off.
          if (ref.read(gameProvider.notifier).isTrivialBearOff())
            Padding(
              padding: const EdgeInsets.only(right: TavliSpacing.xs),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _onCompleteBearOff,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TavliColors.completeButton,
                    foregroundColor: TavliColors.light,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TavliRadius.sm)),
                  ),
                  child: Text(TavliCopy.complete,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          // Large undo button.
          if (gs.currentTurnMoves.isNotEmpty)
            SizedBox(
              width: 48, height: 48,
              child: Semantics(
                label: 'Undo last move',
                button: true,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(gameProvider.notifier).undoMove();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TavliColors.surface,
                    foregroundColor: TavliColors.light,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TavliRadius.sm)),
                  ),
                  child: const Icon(Icons.undo, size: 24),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onCompleteBearOff() async {
    final notifier = ref.read(gameProvider.notifier);
    if (!notifier.isTrivialBearOff()) return;
    final moves = List.of(ref.read(gameProvider).legalTurns.first.moves);

    _animationInProgress = true;
    try {
      for (final move in moves) {
        notifier.selectChecker(move.fromPoint);
        notifier.makeMove(move.toPoint);
        await _game.updateBoardState(ref.read(gameProvider).board);
        if (!mounted) return;
        _audio.playSfx(move.isBearOff ? SfxType.checkerBearOff : SfxType.checkerPlace);
        HapticFeedback.lightImpact();
      }
    } finally {
      _animationInProgress = false;
    }
  }

  Widget _buildTopBar(GameState gs) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TavliColors.surfaceDark,
              border: Border.all(
                color: gs.isAiTurn ? TavliColors.surface : TavliColors.primary,
                width: 2,
              ),
            ),
            child: Center(child: Text(_personality.avatarInitial, style: theme.textTheme.bodyLarge!.copyWith(
              color: TavliColors.light, fontSize: 18, fontWeight: FontWeight.bold,
            ))),
          ),
          const SizedBox(width: TavliSpacing.xs),
          Text('${_personality.greekName} — ${widget.difficulty.greekName}',
            style: theme.textTheme.labelLarge!.copyWith(color: TavliColors.light)),
          const Spacer(),
          if (_aiThinking)
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(TavliColors.surface),
              ),
            ),
          const SizedBox(width: TavliSpacing.xs),
          if (widget.difficulty.usesDoublingCube) ...[
            _buildCubeIndicator(gs),
            const SizedBox(width: TavliSpacing.xs),
          ],
          Text('${TavliCopy.pips}: ${gs.board.pipCount(2)}',
            style: theme.textTheme.bodySmall!.copyWith(
              color: TavliColors.light)),
        ],
      ),
    );
  }

  Widget _buildCubeIndicator(GameState gs) {
    final theme = Theme.of(context);
    final cubeValue = gs.board.doublingCubeValue;
    final ownerText = gs.board.cubeOwner == null
        ? ''
        : gs.board.cubeOwner == 1
            ? ' (${TavliCopy.you})'
            : ' (${_personality.avatarInitial})';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: TavliColors.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(TavliRadius.xs),
        border: Border.all(color: TavliColors.surface.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${cubeValue}x$ownerText',
        style: theme.textTheme.labelSmall!.copyWith(
          color: TavliColors.surface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomBar(GameState gs) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TavliColors.surfaceDark,
              border: Border.all(
                color: gs.isPlayerTurn ? TavliColors.surface : TavliColors.primary,
                width: 2,
              ),
            ),
            child: Center(child: Text('P', style: theme.textTheme.bodyLarge!.copyWith(
              color: TavliColors.light, fontSize: 18, fontWeight: FontWeight.bold,
            ))),
          ),
          const SizedBox(width: TavliSpacing.xs),
          Text(TavliCopy.you, style: theme.textTheme.bodyMedium!.copyWith(
            color: TavliColors.light)),
          const SizedBox(width: TavliSpacing.xs),
          Text('${TavliCopy.pips}: ${gs.board.pipCount(1)}',
            style: theme.textTheme.bodySmall!.copyWith(
              color: TavliColors.light)),
          const Spacer(),
          if (gs.canPlayerDouble)
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => ref.read(gameProvider.notifier).offerDouble(),
                icon: const Icon(Icons.casino, size: 20),
                label: Text(TavliCopy.double_, style: theme.textTheme.bodyMedium),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TavliColors.surface,
                  foregroundColor: TavliColors.light,
                  minimumSize: const Size(44, 44),
                ),
              ),
            ),
          const SizedBox(width: TavliSpacing.xs),
          SizedBox(
            width: 44, height: 44,
            child: IconButton(
              onPressed: () => _showPauseMenu(context),
              tooltip: 'Pause menu',
              icon: const Icon(Icons.menu, color: TavliColors.light), iconSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// Confirmation dialog for destructive actions (resign / new game / exit).
  /// Returns true if the user confirmed.
  Future<bool> _confirmDestructive(String title, String body) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: TavliColors.primary,
        title: Text(
          title,
          style: theme.textTheme.titleLarge!.copyWith(
            color: TavliColors.light,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          body,
          style: theme.textTheme.bodyMedium!.copyWith(color: TavliColors.light),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              TavliCopy.cancel,
              style: theme.textTheme.bodyMedium!.copyWith(color: TavliColors.light),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TavliColors.error,
              foregroundColor: TavliColors.light,
            ),
            child: Text(title),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _showPauseMenu(BuildContext context) {
    final theme = Theme.of(context);
    // Freeze AI mid-turn: any active _handleAiTurn blocks at its next
    // _awaitResume() checkpoint until this completer resolves on dismiss.
    _pauseLock = Completer<void>();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: TavliColors.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TavliRadius.lg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(TavliSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(TavliCopy.pause, style: theme.textTheme.bodyLarge!.copyWith(
              color: TavliColors.light, fontSize: 21, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: TavliSpacing.md),
            _menuBtn(TavliCopy.resume, () => Navigator.pop(ctx)),
            // Mid-game customization shortcut (QA H7). Pause lock stays held
            // by _pauseLock Completer so the AI doesn't act while the player
            // is picking a new board. On return, the Flame game rebuilds
            // with the new set via its existing setBoardSet path.
            _menuBtn('Customize', () {
              Navigator.pop(ctx);
              context.push('/customization');
            }),
            _menuBtn(TavliCopy.resign, () async {
              Navigator.pop(ctx);
              if (await _confirmDestructive(TavliCopy.resign, TavliCopy.confirmResignBody)) {
                ref.read(gameProvider.notifier).resign(1);
              }
            }),
            _menuBtn(TavliCopy.newGame, () async {
              Navigator.pop(ctx);
              final gs = ref.read(gameProvider);
              if (gs.phase != GamePhase.gameOver &&
                  !await _confirmDestructive(TavliCopy.newGame, TavliCopy.confirmNewGameBody)) {
                return;
              }
              ref.read(gameProvider.notifier).newGame(
                difficulty: widget.difficulty,
                variant: widget.variant,
              );
              _dialogue.reset();
              _dialogue.trigger(DialogueEvent.gameStart, widget.difficulty, personality: _personality);
              _navigatingToVictory = false;
              if (mounted) setState(() {});
            }),
            _menuBtn(TavliCopy.exitToHome, () async {
              Navigator.pop(ctx);
              final gs = ref.read(gameProvider);
              final router = GoRouter.of(context);
              if (gs.phase != GamePhase.gameOver &&
                  !await _confirmDestructive(TavliCopy.exitToHome, TavliCopy.confirmExitBody)) {
                return;
              }
              if (mounted) router.go('/home');
            }),
          ],
        ),
      ),
    ).whenComplete(() {
      // Release AI from its pause checkpoint regardless of which button
      // closed the sheet (resume, resign, new game, exit, or swipe-down).
      final lock = _pauseLock;
      _pauseLock = null;
      if (lock != null && !lock.isCompleted) {
        lock.complete();
      }
    });
  }

  Widget _buildDoubleOfferOverlay(GameState gs) {
    final theme = Theme.of(context);
    final newValue = gs.board.doublingCubeValue * 2;
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: TavliSpacing.xxl),
          padding: const EdgeInsets.all(TavliSpacing.lg),
          decoration: BoxDecoration(
            color: TavliColors.surfaceDark,
            borderRadius: BorderRadius.circular(TavliRadius.lg),
            border: Border.all(color: TavliColors.surface.withValues(alpha: 0.5), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_personality.avatarInitial, style: theme.textTheme.bodyLarge!.copyWith(
                color: TavliColors.surface, fontSize: 27, fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: TavliSpacing.xs),
              Text(TavliCopy.offersDouble(_personality.displayName), style: theme.textTheme.bodyLarge!.copyWith(
                color: TavliColors.light, fontSize: 18, fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: TavliSpacing.xxs),
              Text(
                'Cube goes to ${newValue}x',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: TavliColors.light.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: TavliSpacing.xxs),
              Text(
                'If you decline, you lose ${gs.board.doublingCubeValue} point${gs.board.doublingCubeValue > 1 ? 's' : ''}.',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: TavliColors.error.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: TavliSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _playerDeclinesDouble,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TavliColors.error,
                        side: const BorderSide(color: TavliColors.error),
                        padding: const EdgeInsets.symmetric(vertical: TavliSpacing.sm),
                      ),
                      child: Text(TavliCopy.decline),
                    ),
                  ),
                  const SizedBox(width: TavliSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _playerAcceptsDouble,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TavliColors.surface,
                        foregroundColor: TavliColors.surfaceDark,
                        padding: const EdgeInsets.symmetric(vertical: TavliSpacing.sm),
                      ),
                      child: Text(TavliCopy.accept),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpeningRollResult(ThemeData theme) {
    final gs = ref.read(gameProvider);
    final p = gs.openingRollPlayer ?? 0;
    final o = gs.openingRollOpponent ?? 0;
    final botName = _personality.displayName;
    final youFirst = p > o;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('🎲', style: theme.textTheme.displayLarge!.copyWith(fontSize: 48)),
        const SizedBox(height: TavliSpacing.md),
        Text(
          'You: $p  vs  $botName: $o',
          style: theme.textTheme.headlineMedium!.copyWith(
            color: TavliColors.light,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: TavliSpacing.sm),
        Text(
          youFirst ? 'You go first!' : '$botName goes first',
          style: theme.textTheme.titleLarge!.copyWith(
            color: youFirst ? TavliColors.success : TavliColors.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildOpeningRollOverlay() {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _onDiceRoll,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: TavliSpacing.xxl),
            padding: const EdgeInsets.all(TavliSpacing.xl),
            decoration: BoxDecoration(
              color: TavliColors.surfaceDark,
              borderRadius: BorderRadius.circular(TavliRadius.lg),
              border: Border.all(color: TavliColors.surface.withValues(alpha: 0.4), width: 2),
            ),
            child: _showOpeningResult
                ? _buildOpeningRollResult(theme)
                : Semantics(
              label: 'Tap to roll dice and determine who goes first',
              button: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎲', style: theme.textTheme.displayLarge!.copyWith(
                    fontSize: 48)),
                  const SizedBox(height: TavliSpacing.md),
                  Text(
                    TavliCopy.rollForFirstMove,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: TavliColors.light,
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: TavliSpacing.xs),
                  Text(
                    TavliCopy.rollForFirstMoveSub,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: TavliColors.light.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: TavliSpacing.lg),
                  ElevatedButton(
                    onPressed: _onDiceRoll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TavliColors.surface,
                      foregroundColor: TavliColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.xxl, vertical: TavliSpacing.sm),
                    ),
                    child: Text(TavliCopy.rollButton, style: theme.textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuBtn(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TavliSpacing.xxs),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: TavliColors.primary,
            foregroundColor: TavliColors.light,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

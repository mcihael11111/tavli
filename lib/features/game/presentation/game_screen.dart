import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
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
  bool _aiThinking = false;
  bool _navigatingToVictory = false;

  BotPersonality get _personality => SettingsService.instance.botPersonality;

  @override
  void initState() {
    super.initState();
    _aiPlayer = AiPlayer();
    _dialogue = DialogueSystem();
    _audio = AudioService();

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
    final gs = ref.read(gameProvider);
    if (!gs.isPlayerTurn) return;
    if (gs.phase != GamePhase.movingCheckers) return;
    _audio.playSfx(SfxType.checkerPickup);
    HapticFeedback.selectionClick();
    ref.read(gameProvider.notifier).selectChecker(pointIndex);
    _announce('Checker selected on point ${pointIndex + 1}');
  }

  void _onDestinationTapped(int toPoint) {
    final gs = ref.read(gameProvider);
    if (!gs.isPlayerTurn) return;

    // Determine SFX before the move is applied.
    final move = gs.availableMovesForSelected
        .where((m) => m.toPoint == toPoint)
        .firstOrNull;
    if (move != null) {
      if (move.isHit) {
        _audio.playSfx(SfxType.checkerHit);
        HapticFeedback.heavyImpact();
        _announce('Hit! Opponent checker sent to bar.');
      } else if (move.isBearOff) {
        _audio.playSfx(SfxType.checkerBearOff);
        HapticFeedback.mediumImpact();
        _announce('Checker borne off.');
      } else if (move.isBarEntry) {
        _audio.playSfx(SfxType.checkerBarEntry);
        HapticFeedback.mediumImpact();
        _announce('Entered from bar to point ${toPoint + 1}.');
      } else {
        _audio.playSfx(SfxType.checkerPlace);
        HapticFeedback.lightImpact();
        _announce('Moved to point ${toPoint + 1}.');
      }
    }

    ref.read(gameProvider.notifier).makeMove(toPoint);

    // Post-move teaching feedback (Easy+Help).
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
      return;
    }

    if (gs.phase != GamePhase.playerTurnStart) return;
    if (!gs.isPlayerTurn) return;
    _audio.playSfx(SfxType.diceRoll);
    HapticFeedback.mediumImpact();
    ref.read(gameProvider.notifier).rollDice();

    final afterRoll = ref.read(gameProvider);
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
  void _checkTeachingFeedback() {
    final gs = ref.read(gameProvider);
    if (gs.currentTurnMoves.isEmpty) return;
    if (gs.remainingDice.isNotEmpty) return; // wait until turn is fully played

    // Compare player's board to the best possible board.
    final boardBefore = gs.undoStack.isNotEmpty ? gs.undoStack.first : gs.board;
    final equityLoss = _aiPlayer.evaluateMoveLoss(
      boardBefore, gs.board,
      gs.currentRoll!,
      1, // player
    );

    if (equityLoss > 0.06) {
      _dialogue.trigger(DialogueEvent.teachingMistakeExplain, widget.difficulty, personality: _personality);
    } else if (equityLoss > 0.02) {
      _dialogue.trigger(DialogueEvent.playerBadMove, widget.difficulty, personality: _personality);
    } else {
      _dialogue.trigger(DialogueEvent.playerGoodMove, widget.difficulty, personality: _personality);
    }
    if (mounted) setState(() {});
  }

  /// Teaching mode: compute move quality for each available move.
  Map<int, MoveQuality>? _computeMoveQualities() {
    if (!widget.difficulty.isTeaching) return null;

    final gs = ref.read(gameProvider);
    if (gs.availableMovesForSelected.isEmpty) return null;

    // Evaluate equity for each destination.
    final equities = <int, double>{};
    for (final move in gs.availableMovesForSelected) {
      final resultBoard = _aiPlayer.evaluateMoveLoss(
        gs.board, gs.board, // simplified — just rank by position after move
        gs.currentRoll!,
        1,
      );
      equities[move.toPoint] = resultBoard;
    }

    // For now use a simpler approach: rank all moves and classify.
    if (gs.availableMovesForSelected.length <= 1) {
      return {gs.availableMovesForSelected.first.toPoint: MoveQuality.best};
    }

    // Use the AI evaluator directly for proper ranking.
    final qualities = <int, MoveQuality>{};
    final moves = gs.availableMovesForSelected;
    final scores = <int, double>{};

    for (final move in moves) {
      final after = ref.read(gameProvider.notifier).peekApplyMove(move);
      if (after != null) {
        scores[move.toPoint] = _aiPlayer.evaluatePosition(after, 1);
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
    Future.delayed(const Duration(milliseconds: 800), () {
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

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) { _aiThinking = false; return; }

    final notifier = ref.read(gameProvider.notifier);

    // AI considers doubling before rolling (if enabled for this difficulty).
    if (widget.difficulty.usesDoublingCube) {
      final gs = ref.read(gameProvider);
      if (_aiPlayer.shouldOfferDouble(gs.board, widget.difficulty) &&
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
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) { _aiThinking = false; return; }

    final afterRoll = ref.read(gameProvider);

    if (afterRoll.currentRoll == null || afterRoll.phase == GamePhase.turnComplete) {
      // No legal moves — turn was auto-skipped.
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
    );

    if (aiTurn != null) {
      for (final move in aiTurn.moves) {
        await Future.delayed(const Duration(milliseconds: 350));
        if (!mounted) { _aiThinking = false; return; }

        if (move.isHit) {
          _audio.playSfx(SfxType.checkerHit);
          _dialogue.trigger(DialogueEvent.mikhailHit, widget.difficulty, personality: _personality);
          if (mounted) setState(() {});
        } else if (move.isBearOff) {
          _audio.playSfx(SfxType.checkerBearOff);
        } else {
          _audio.playSfx(SfxType.checkerPlace);
        }

        // Apply via notifier — selectChecker + makeMove.
        notifier.selectChecker(move.fromPoint);
        notifier.makeMove(move.toPoint);

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

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) { _aiThinking = false; return; }

    final afterMoves = ref.read(gameProvider);
    if (afterMoves.phase == GamePhase.gameOver) {
      _navigateToVictory(afterMoves);
    } else if (afterMoves.phase != GamePhase.playerTurnStart) {
      notifier.nextTurn();
    }

    _aiThinking = false;
    if (mounted) setState(() {});
  }

  Future<void> _handleAiDoubleResponse() async {
    if (_aiThinking) return;
    _aiThinking = true;
    if (mounted) setState(() {});

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) { _aiThinking = false; return; }

    final gs = ref.read(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    if (_aiPlayer.shouldAcceptDouble(gs.board, widget.difficulty)) {
      _dialogue.trigger(DialogueEvent.gameStart, widget.difficulty, personality: _personality); // placeholder
      notifier.acceptDouble();
    } else {
      notifier.declineDouble();
    }

    _aiThinking = false;
    if (mounted) setState(() {});
  }

  void _playerAcceptsDouble() {
    ref.read(gameProvider.notifier).acceptDouble();
    // Resume AI turn after player accepts.
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleAiTurn());
  }

  void _playerDeclinesDouble() {
    ref.read(gameProvider.notifier).declineDouble();
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameProvider);

    // Sync Flame.
    if (_game.isLoaded) {
      _game.updateBoardState(gs.board);

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
      } else if (gs.phase == GamePhase.playerTurnStart && gs.isPlayerTurn) {
        _game.showRollPrompt();
      } else {
        _game.hideDice();
      }
    }

    // Game over — navigate to victory.
    if (gs.phase == GamePhase.gameOver && !_navigatingToVictory) {
      if (gs.result?.winner == 1) {
        _audio.playSfx(SfxType.gameWin);
        HapticFeedback.heavyImpact();
        _dialogue.trigger(DialogueEvent.playerWin, widget.difficulty, personality: _personality);
        _announce('You win!');
      } else {
        _audio.playSfx(SfxType.gameLose);
        _announce('You lose. ${_personality.displayName} wins.');
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToVictory(gs));
    }

    // AI turn.
    if (gs.isAiTurn && gs.phase == GamePhase.playerTurnStart && !_aiThinking) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleAiTurn());
    }

    // Player turn complete → advance.
    if (gs.phase == GamePhase.turnComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(gameProvider.notifier).nextTurn();
      });
    }

    // Player offered double → AI decides.
    if (gs.phase == GamePhase.doubleOffered && gs.doubleOfferedBy == 1 && !_aiThinking) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleAiDoubleResponse());
    }

    final bgColor = (_aiThinking || gs.isAiTurn)
        ? TavliColors.botThinkingBg
        : TavliColors.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(gs),
                  if (_aiThinking) _buildBotThinkingBanner(),
                  Expanded(child: GameWidget(game: _game)),
                  _buildDialogueBar(),
                  _buildActionArea(gs),
                  _buildBottomBar(gs),
                ],
              ),
              // Opening roll overlay.
              if (gs.phase == GamePhase.waitingForFirstRoll)
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: TavliSpacing.sm),
      color: TavliColors.botThinkingBanner,
      child: Center(
        child: Text(TavliCopy.botThinking,
          style: const TextStyle(
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
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 2)),
        ),
      ),
    );
  }

  Widget _buildMoveControls(GameState gs) {
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          // Large undo button.
          if (gs.currentTurnMoves.isNotEmpty)
            SizedBox(
              width: 48, height: 48,
              child: ElevatedButton(
                onPressed: () => ref.read(gameProvider.notifier).undoMove(),
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
        ],
      ),
    );
  }

  void _onCompleteBearOff() {
    final notifier = ref.read(gameProvider.notifier);
    final moves = notifier.autoPlayForcedMoves();
    for (final move in moves) {
      if (move.isBearOff) {
        _audio.playSfx(SfxType.checkerBearOff);
      } else {
        _audio.playSfx(SfxType.checkerPlace);
      }
    }
    HapticFeedback.mediumImpact();
  }

  Widget _buildTopBar(GameState gs) {
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
            child: const Center(child: Text('Μ', style: TextStyle(
              color: TavliColors.light, fontSize: 18, fontWeight: FontWeight.bold,
            ))),
          ),
          const SizedBox(width: TavliSpacing.xs),
          Text('${_personality.greekName} — ${widget.difficulty.greekName}',
            style: const TextStyle(color: TavliColors.light, fontSize: 14, fontWeight: FontWeight.w500)),
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
          Text('Pips: ${gs.board.pipCount(2)}',
            style: TextStyle(color: TavliColors.light.withValues(alpha: 0.85), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCubeIndicator(GameState gs) {
    final cubeValue = gs.board.doublingCubeValue;
    final ownerText = gs.board.cubeOwner == null
        ? ''
        : gs.board.cubeOwner == 1
            ? ' (You)'
            : ' (Μ)';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: TavliColors.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(TavliRadius.xs),
        border: Border.all(color: TavliColors.surface.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${cubeValue}x$ownerText',
        style: const TextStyle(
          color: TavliColors.surface,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDialogueBar() {
    final line = _dialogue.currentLine;
    if (line == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md, vertical: TavliSpacing.xs),
      color: TavliColors.primary.withValues(alpha: 0.9),
      child: Row(
        children: [
          const Text('Μ ', style: TextStyle(fontSize: 14, color: TavliColors.surface, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(line,
              style: const TextStyle(color: TavliColors.light, fontSize: 14, fontStyle: FontStyle.italic),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(GameState gs) {
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
            child: const Center(child: Text('P', style: TextStyle(
              color: TavliColors.light, fontSize: 18, fontWeight: FontWeight.bold,
            ))),
          ),
          const SizedBox(width: TavliSpacing.xs),
          const Text('You', style: TextStyle(color: TavliColors.light, fontSize: 14)),
          const SizedBox(width: TavliSpacing.xs),
          Text('Pips: ${gs.board.pipCount(1)}',
            style: TextStyle(color: TavliColors.light.withValues(alpha: 0.85), fontSize: 12)),
          const Spacer(),
          if (gs.canPlayerDouble)
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => ref.read(gameProvider.notifier).offerDouble(),
                icon: const Icon(Icons.casino, size: 20),
                label: Text(TavliCopy.double_, style: const TextStyle(fontSize: 14)),
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
              icon: const Icon(Icons.menu, color: TavliColors.light), iconSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  void _showPauseMenu(BuildContext context) {
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
            Text(TavliCopy.pause, style: const TextStyle(
              color: TavliColors.light, fontSize: 21, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: TavliSpacing.md),
            _menuBtn(TavliCopy.resume, () => Navigator.pop(ctx)),
            _menuBtn(TavliCopy.resign, () {
              Navigator.pop(ctx);
              ref.read(gameProvider.notifier).resign(1);
            }),
            _menuBtn(TavliCopy.newGame, () {
              Navigator.pop(ctx);
              ref.read(gameProvider.notifier).newGame(
                difficulty: widget.difficulty,
                variant: widget.variant,
              );
              _dialogue.reset();
              _dialogue.trigger(DialogueEvent.gameStart, widget.difficulty, personality: _personality);
              _navigatingToVictory = false;
              setState(() {});
            }),
            _menuBtn(TavliCopy.exitToHome, () {
              Navigator.pop(ctx);
              context.go('/home');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDoubleOfferOverlay(GameState gs) {
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
              const Text('Μ', style: TextStyle(
                color: TavliColors.surface, fontSize: 27, fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: TavliSpacing.xs),
              Text(TavliCopy.offersDouble(_personality.displayName), style: const TextStyle(
                color: TavliColors.light, fontSize: 18, fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: TavliSpacing.xxs),
              Text(
                'Cube goes to ${newValue}x',
                style: TextStyle(
                  color: TavliColors.light.withValues(alpha: 0.7), fontSize: 14,
                ),
              ),
              const SizedBox(height: TavliSpacing.xxs),
              Text(
                'If you decline, you lose ${gs.board.doublingCubeValue} point${gs.board.doublingCubeValue > 1 ? 's' : ''}.',
                style: TextStyle(
                  color: TavliColors.error.withValues(alpha: 0.9), fontSize: 12,
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

  Widget _buildOpeningRollOverlay() {
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
            child: Semantics(
              label: 'Tap to roll dice and determine who goes first',
              button: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎲', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: TavliSpacing.md),
                  Text(
                    TavliCopy.rollForFirstMove,
                    style: const TextStyle(
                      color: TavliColors.light,
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: TavliSpacing.xs),
                  Text(
                    TavliCopy.rollForFirstMoveSub,
                    style: TextStyle(
                      color: TavliColors.light.withValues(alpha: 0.8),
                      fontSize: 14,
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
                    child: Text(TavliCopy.rollButton, style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
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

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../flame_game/tavli_game.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/settings_service.dart';
import 'package:flutter/semantics.dart';
import '../data/models/board_state.dart';
import '../data/models/game_state.dart';
import '../domain/engine/move_quality.dart';
import '../../ai/difficulty/difficulty_level.dart';
import '../../ai/engine/ai_player.dart';
import '../../ai/mikhail/dialogue_event.dart';
import '../../ai/mikhail/dialogue_system.dart';
import 'providers/game_provider.dart';

/// Main game screen: hosts the Flame board + Flutter UI overlay.
class GameScreen extends ConsumerStatefulWidget {
  final DifficultyLevel difficulty;

  const GameScreen({super.key, required this.difficulty});

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

  @override
  void initState() {
    super.initState();
    _aiPlayer = AiPlayer();
    _dialogue = DialogueSystem();
    _audio = AudioService();

    final boardSet = SettingsService.instance.boardSet;

    _game = TavliGame(
      boardState: BoardState.initial(),
      onCheckerTapped: _onCheckerTapped,
      onDestinationTapped: _onDestinationTapped,
      onDiceRollRequested: _onDiceRoll,
      boardSet: boardSet,
    );

    // Allow landscape for gameplay.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).newGame(difficulty: widget.difficulty);
      _dialogue.trigger(DialogueEvent.gameStart, widget.difficulty);
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
    SemanticsService.announce(message, TextDirection.ltr);
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
      final who = p > o ? 'You go' : 'Mikhail goes';
      _announce('You rolled $p, Mikhail rolled $o. $who first.');
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
        _dialogue.trigger(DialogueEvent.playerRollDoubles, widget.difficulty);
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
      _dialogue.trigger(DialogueEvent.teachingMistakeExplain, widget.difficulty);
    } else if (equityLoss > 0.02) {
      _dialogue.trigger(DialogueEvent.playerBadMove, widget.difficulty);
    } else {
      _dialogue.trigger(DialogueEvent.playerGoodMove, widget.difficulty);
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
      _dialogue.trigger(DialogueEvent.mikhailRollDoubles, widget.difficulty);
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
          _dialogue.trigger(DialogueEvent.mikhailHit, widget.difficulty);
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
          _dialogue.trigger(DialogueEvent.mikhailWin, widget.difficulty);
          if (mounted) setState(() {});
          _navigateToVictory(current);
          _aiThinking = false;
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
  }

  Future<void> _handleAiDoubleResponse() async {
    if (_aiThinking) return;
    _aiThinking = true;

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) { _aiThinking = false; return; }

    final gs = ref.read(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    if (_aiPlayer.shouldAcceptDouble(gs.board, widget.difficulty)) {
      _dialogue.trigger(DialogueEvent.gameStart, widget.difficulty); // placeholder
      notifier.acceptDouble();
    } else {
      notifier.declineDouble();
    }

    _aiThinking = false;
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
        _dialogue.trigger(DialogueEvent.playerWin, widget.difficulty);
        _announce('You win!');
      } else {
        _audio.playSfx(SfxType.gameLose);
        _announce('You lose. Mikhail wins.');
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

    return Scaffold(
      backgroundColor: TavliColors.kafeneioBrown,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(gs),
                Expanded(child: GameWidget(game: _game)),
                _buildDialogueBar(),
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
    );
  }

  Widget _buildTopBar(GameState gs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: TavliColors.kafeneioBrown,
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3D2614), // dark brown for contrast
              border: Border.all(
                color: gs.isAiTurn ? TavliColors.oliveGold : TavliColors.kafeneioBrown,
                width: 2,
              ),
            ),
            child: const Center(child: Text('Μ', style: TextStyle(
              color: TavliColors.parchment, fontSize: 18, fontWeight: FontWeight.bold,
            ))),
          ),
          const SizedBox(width: 8),
          Text('Μιχαήλ — ${widget.difficulty.greekName}',
            style: const TextStyle(color: TavliColors.parchment, fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          if (_aiThinking)
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(TavliColors.oliveGold),
              ),
            ),
          const SizedBox(width: 8),
          if (widget.difficulty.usesDoublingCube) ...[
            _buildCubeIndicator(gs),
            const SizedBox(width: 8),
          ],
          Text('Pips: ${gs.board.pipCount(2)}',
            style: TextStyle(color: TavliColors.parchment.withValues(alpha: 0.85), fontSize: 12)),
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
        color: TavliColors.oliveGold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TavliColors.oliveGold.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${cubeValue}x$ownerText',
        style: const TextStyle(
          color: TavliColors.oliveGold,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: TavliColors.kafeneioBrown.withValues(alpha: 0.9),
      child: Row(
        children: [
          const Text('Μ ', style: TextStyle(fontSize: 14, color: TavliColors.oliveGold, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(line,
              style: const TextStyle(color: TavliColors.parchment, fontSize: 13, fontStyle: FontStyle.italic),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(GameState gs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: TavliColors.kafeneioBrown,
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3D2614), // dark brown for contrast
              border: Border.all(
                color: gs.isPlayerTurn ? TavliColors.oliveGold : TavliColors.kafeneioBrown,
                width: 2,
              ),
            ),
            child: const Center(child: Text('P', style: TextStyle(
              color: TavliColors.parchment, fontSize: 18, fontWeight: FontWeight.bold,
            ))),
          ),
          const SizedBox(width: 8),
          const Text('You', style: TextStyle(color: TavliColors.parchment, fontSize: 14)),
          const SizedBox(width: 8),
          Text('Pips: ${gs.board.pipCount(1)}',
            style: TextStyle(color: TavliColors.parchment.withValues(alpha: 0.85), fontSize: 12)),
          const Spacer(),
          if (gs.canPlayerDouble)
            TextButton.icon(
              onPressed: () => ref.read(gameProvider.notifier).offerDouble(),
              icon: const Icon(Icons.casino, size: 16),
              label: const Text('Double', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: TavliColors.oliveGold,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
            ),
          if (gs.currentTurnMoves.isNotEmpty && gs.isPlayerTurn)
            IconButton(
              onPressed: () => ref.read(gameProvider.notifier).undoMove(),
              icon: const Icon(Icons.undo, color: TavliColors.parchment), iconSize: 20,
            ),
          IconButton(
            onPressed: () => _showPauseMenu(context),
            icon: const Icon(Icons.menu, color: TavliColors.parchment), iconSize: 20,
          ),
        ],
      ),
    );
  }

  void _showPauseMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TavliColors.kafeneioBrown,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('PAUSE', style: TextStyle(
              color: TavliColors.parchment, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 16),
            _menuBtn('Resume', () => Navigator.pop(ctx)),
            _menuBtn('Resign', () {
              Navigator.pop(ctx);
              ref.read(gameProvider.notifier).resign(1);
            }),
            _menuBtn('New Game', () {
              Navigator.pop(ctx);
              ref.read(gameProvider.notifier).newGame(difficulty: widget.difficulty);
              _dialogue.reset();
              _dialogue.trigger(DialogueEvent.gameStart, widget.difficulty);
              _navigatingToVictory = false;
              setState(() {});
            }),
            _menuBtn('Exit to Home', () {
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
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF3D2614),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TavliColors.oliveGold.withValues(alpha: 0.5), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Μ', style: TextStyle(
                color: TavliColors.oliveGold, fontSize: 28, fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 8),
              const Text('Mikhail offers a double!', style: TextStyle(
                color: TavliColors.parchment, fontSize: 18, fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 6),
              Text(
                'Cube goes to ${newValue}x',
                style: TextStyle(
                  color: TavliColors.parchment.withValues(alpha: 0.7), fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'If you decline, you lose ${gs.board.doublingCubeValue} point${gs.board.doublingCubeValue > 1 ? 's' : ''}.',
                style: TextStyle(
                  color: TavliColors.terracotta.withValues(alpha: 0.9), fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _playerDeclinesDouble,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TavliColors.terracotta,
                        side: const BorderSide(color: TavliColors.terracotta),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _playerAcceptsDouble,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TavliColors.oliveGold,
                        foregroundColor: const Color(0xFF3D2614),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Accept'),
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
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF3D2614),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TavliColors.oliveGold.withValues(alpha: 0.4), width: 2),
            ),
            child: Semantics(
              label: 'Tap to roll dice and determine who goes first',
              button: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎲', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  const Text(
                    'Roll for First Move',
                    style: TextStyle(
                      color: TavliColors.parchment,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Both players roll one die.\nHigher number goes first.',
                    style: TextStyle(
                      color: TavliColors.parchment.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _onDiceRoll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TavliColors.oliveGold,
                      foregroundColor: TavliColors.kafeneioBrown,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    ),
                    child: const Text('Roll!', style: TextStyle(
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: TavliColors.oliveGold,
            foregroundColor: TavliColors.kafeneioBrown,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

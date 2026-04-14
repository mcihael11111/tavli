import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../flame_game/tavli_game.dart';
import '../data/models/board_state.dart';
import '../data/models/game_state.dart';
import '../domain/engine/variants/game_variant.dart';
import 'providers/game_provider.dart';

/// Pass & Play — two human players on one device.
///
/// After each turn completes, shows a "Pass the device" interstitial
/// so the next player doesn't see the board before their turn.
class PassPlayScreen extends ConsumerStatefulWidget {
  final GameVariant variant;

  const PassPlayScreen({super.key, this.variant = GameVariant.portes});

  @override
  ConsumerState<PassPlayScreen> createState() => _PassPlayScreenState();
}

class _PassPlayScreenState extends ConsumerState<PassPlayScreen> {
  late TavliGame _game;
  bool _showPassScreen = false;
  int _nextPlayer = 1;

  @override
  void initState() {
    super.initState();
    _game = TavliGame(
      boardState: BoardState.initial(),
      onCheckerTapped: _onCheckerTapped,
      onDestinationTapped: _onDestinationTapped,
      onDiceRollRequested: _onDiceRoll,
    );

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).newGame(variant: widget.variant);
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

  void _onCheckerTapped(int pointIndex) {
    if (_showPassScreen) return;
    final gs = ref.read(gameProvider);
    if (gs.phase != GamePhase.movingCheckers) return;
    ref.read(gameProvider.notifier).selectChecker(pointIndex);
  }

  void _onDestinationTapped(int toPoint) {
    if (_showPassScreen) return;
    ref.read(gameProvider.notifier).makeMove(toPoint);
  }

  void _onDiceRoll() {
    if (_showPassScreen) return;
    final gs = ref.read(gameProvider);
    if (gs.phase != GamePhase.playerTurnStart) return;
    ref.read(gameProvider.notifier).rollDice();
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameProvider);

    // Sync Flame.
    if (_game.isLoaded) {
      _game.updateBoardState(gs.board);
      if (gs.selectedPoint != null && gs.availableMovesForSelected.isNotEmpty) {
        _game.showHighlights(gs.availableMovesForSelected);
      } else {
        _game.clearHighlights();
      }
      if (gs.currentRoll != null) {
        _game.showDice(gs.currentRoll!.die1, gs.currentRoll!.die2, gs.remainingDice);
      } else if (gs.phase == GamePhase.playerTurnStart) {
        _game.showRollPrompt();
      } else {
        _game.hideDice();
      }
    }

    // Turn complete → show pass screen.
    if (gs.phase == GamePhase.turnComplete && !_showPassScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _showPassScreen = true;
          _nextPlayer = gs.board.activePlayer;
        });
      });
    }

    // Game over.
    if (gs.phase == GamePhase.gameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/victory', extra: {
          'result': gs.result,
          'difficulty': null,
        });
      });
    }

    return Scaffold(
      backgroundColor: TavliColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildBar(gs, isTop: true),
                Expanded(child: GameWidget(game: _game)),
                _buildBar(gs, isTop: false),
              ],
            ),
            if (_showPassScreen) _buildPassInterstitial(),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(GameState gs, {required bool isTop}) {
    final theme = Theme.of(context);
    final player = isTop ? 2 : 1;
    final isActive = gs.board.activePlayer == player;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md, vertical: 6),
      color: TavliColors.primary,
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TavliColors.surfaceDark,
              border: Border.all(
                color: isActive ? TavliColors.surface : TavliColors.primary,
                width: 2,
              ),
            ),
            child: Center(child: Text(
              'P$player',
              style: theme.textTheme.labelMedium!.copyWith(
                color: TavliColors.light, fontWeight: FontWeight.bold,
              ),
            )),
          ),
          const SizedBox(width: TavliSpacing.xs),
          Text(
            'Player $player',
            style: theme.textTheme.bodyMedium!.copyWith(color: TavliColors.light),
          ),
          const Spacer(),
          Text(
            'Pips: ${gs.board.pipCount(player)}',
            style: theme.textTheme.bodySmall!.copyWith(
              color: TavliColors.light.withValues(alpha: 0.85),
            ),
          ),
          if (!isTop) ...[
            const SizedBox(width: TavliSpacing.xs),
            if (gs.currentTurnMoves.isNotEmpty)
              IconButton(
                onPressed: () => ref.read(gameProvider.notifier).undoMove(),
                icon: const Icon(Icons.undo, color: TavliColors.light),
                iconSize: 20,
              ),
            IconButton(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.close, color: TavliColors.light),
              iconSize: 20,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPassInterstitial() {
    final theme = Theme.of(context);
    return Container(
      color: TavliColors.primary,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_horiz, color: TavliColors.surface, size: 48),
            const SizedBox(height: TavliSpacing.md),
            Text(
              'Pass to Player $_nextPlayer',
              style: theme.textTheme.headlineLarge!.copyWith(
                color: TavliColors.light,
              ),
            ),
            const SizedBox(height: TavliSpacing.xs),
            Text(
              'Tap when ready',
              style: theme.textTheme.bodyLarge!.copyWith(
                color: TavliColors.disabledOnPrimary,
              ),
            ),
            const SizedBox(height: TavliSpacing.xl),
            ElevatedButton(
              onPressed: () {
                setState(() => _showPassScreen = false);
                ref.read(gameProvider.notifier).nextTurn();
                // Flip board so each player sees their home at the bottom.
                _game.setFlipped(_nextPlayer == 2);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TavliColors.surface,
                foregroundColor: TavliColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.xxl, vertical: TavliSpacing.md),
              ),
              child: Text("I'm Ready", style: theme.textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.w600,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

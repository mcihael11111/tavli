import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../flame_game/tavli_game.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/settings_service.dart';
import '../../game/data/models/board_state.dart';
import '../../game/data/models/game_state.dart';
import '../../social/chat/quick_chat.dart';
import '../data/firestore_multiplayer_service.dart';
import '../data/multiplayer_service_provider.dart';
import 'online_game_provider.dart';
import 'online_game_state.dart';
import 'turn_timer.dart';

/// Online multiplayer game screen.
///
/// Mirrors the AI GameScreen but uses OnlineGameNotifier for state
/// and syncs with Firestore for real-time opponent interaction.
class OnlineGameScreen extends ConsumerStatefulWidget {
  final String gameRoomId;
  final int localPlayerNumber;
  final String localPlayerUid;

  const OnlineGameScreen({
    super.key,
    required this.gameRoomId,
    required this.localPlayerNumber,
    required this.localPlayerUid,
  });

  @override
  ConsumerState<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends ConsumerState<OnlineGameScreen> {
  late TavliGame _game;
  late AudioService _audio;
  late OnlineGameParams _params;
  bool _navigatingToVictory = false;

  // Chat.
  StreamSubscription<List<ChatMessage>>? _chatSubscription;
  final List<ChatMessage> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _audio = AudioService();

    _params = OnlineGameParams(
      gameRoomId: widget.gameRoomId,
      localPlayerNumber: widget.localPlayerNumber,
      localPlayerUid: widget.localPlayerUid,
    );

    final boardSet = SettingsService.instance.boardSet;
    final checkerSet = SettingsService.instance.checkerSet;
    final diceSet = SettingsService.instance.diceSet;

    _game = TavliGame(
      boardState: _defaultBoard(),
      onCheckerTapped: _onCheckerTapped,
      onDestinationTapped: _onDestinationTapped,
      onDiceRollRequested: _onDiceRoll,
      boardSet: boardSet,
      checkerSet: checkerSet,
      diceSet: diceSet,
      flipped: widget.localPlayerNumber == 2,
    );

    // Allow landscape.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    // Start listening to chat.
    _startChatListener();
  }

  void _startChatListener() {
    final service = ref.read(multiplayerServiceProvider);
    _chatSubscription = service.watchChat(widget.gameRoomId).listen(
      (messages) {
        if (mounted) {
          setState(() {
            _chatHistory.clear();
            _chatHistory.addAll(messages);
          });
          // Show toast for new opponent messages.
          if (messages.isNotEmpty) {
            final last = messages.last;
            if (last.senderUid != widget.localPlayerUid) {
              _showChatToast(last);
            }
          }
        }
      },
      onError: (error) {
        debugPrint('Chat stream error: $error');
      },
    );
  }

  void _showChatToast(ChatMessage message) {
    if (message.messageIndex < 0 ||
        message.messageIndex >= QuickChatMessages.all.length) {
      return;
    }
    final chatMsg = QuickChatMessages.all[message.messageIndex];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${message.senderName}: ${chatMsg.text}'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 60, left: TavliSpacing.md, right: TavliSpacing.md),
      ),
    );
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _announce(String message) {
    SemanticsService.sendAnnouncement(View.of(context), message, TextDirection.ltr);
  }

  void _onCheckerTapped(int pointIndex) {
    final gs = ref.read(onlineGameProvider(_params));
    if (!gs.isMyTurn) return;
    if (gs.phase != GamePhase.movingCheckers) return;
    _audio.playSfx(SfxType.checkerPickup);
    HapticFeedback.selectionClick();
    ref.read(onlineGameProvider(_params).notifier).selectChecker(pointIndex);
  }

  void _onDestinationTapped(int toPoint) {
    final gs = ref.read(onlineGameProvider(_params));
    if (!gs.isMyTurn) return;

    final move = gs.availableMovesForSelected
        .where((m) => m.toPoint == toPoint)
        .firstOrNull;
    if (move != null) {
      if (move.isHit) {
        _audio.playSfx(SfxType.checkerHit);
        HapticFeedback.heavyImpact();
      } else if (move.isBearOff) {
        _audio.playSfx(SfxType.checkerBearOff);
        HapticFeedback.mediumImpact();
      } else {
        _audio.playSfx(SfxType.checkerPlace);
        HapticFeedback.lightImpact();
      }
    }

    ref.read(onlineGameProvider(_params).notifier).makeMove(toPoint);
  }

  void _onDiceRoll() {
    final gs = ref.read(onlineGameProvider(_params));
    if (!gs.isMyTurn) return;
    if (gs.phase != GamePhase.playerTurnStart) return;

    _audio.playSfx(SfxType.diceRoll);
    HapticFeedback.mediumImpact();
    ref.read(onlineGameProvider(_params).notifier).rollDice();
  }

  void _navigateToVictory(OnlineGameState gs) {
    if (_navigatingToVictory) return;
    if (gs.result == null) return;
    _navigatingToVictory = true;

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      context.go('/victory', extra: {
        'result': gs.result,
        'isOnline': true,
        'opponentName': gs.opponentName,
        'ratingDelta': gs.ratingDelta,
      });
    });
  }

  void _showChatPanel() {
    final notifier = ref.read(onlineGameProvider(_params).notifier);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => QuickChatPanel(
        onSend: (msg) {
          final index = QuickChatMessages.all.indexOf(msg);
          if (index >= 0) {
            notifier.sendChat(index, 'You');
          }
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(onlineGameProvider(_params));

    // Sync Flame board — use instant sync (not animated) in build() to avoid
    // concurrent animations when Firestore snapshots arrive rapidly.
    if (_game.isLoaded) {
      _game.syncBoardState(gs.board);

      if (gs.selectedPoint != null && gs.availableMovesForSelected.isNotEmpty) {
        _game.showHighlights(gs.availableMovesForSelected);
      } else {
        _game.clearHighlights();
      }

      if (gs.currentRoll != null) {
        _game.showDice(
            gs.currentRoll!.die1, gs.currentRoll!.die2, gs.remainingDice);
      } else if (gs.phase == GamePhase.playerTurnStart && gs.isMyTurn) {
        _game.showRollPrompt();
      } else {
        _game.hideDice();
      }
    }

    // Game over.
    if (gs.phase == GamePhase.gameOver && !_navigatingToVictory) {
      final didWin = gs.result?.winner == gs.localPlayerNumber;
      if (didWin) {
        _audio.playSfx(SfxType.gameWin);
        HapticFeedback.heavyImpact();
        _announce('You win!');
      } else {
        _audio.playSfx(SfxType.gameLose);
        _announce('You lose.');
      }
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _navigateToVictory(gs));
    }

    return Scaffold(
      backgroundColor: TavliColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(gs),
                Expanded(child: GameWidget(game: _game)),
                _buildBottomBar(gs),
              ],
            ),
            // Double offer overlay.
            if (gs.phase == GamePhase.doubleOffered &&
                gs.pendingDoubleFrom != gs.localPlayerKey)
              _buildDoubleOfferOverlay(gs),
            // Connection status.
            if (gs.connectionStatus != ConnectionStatus.connected)
              _buildConnectionBanner(gs),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(OnlineGameState gs) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md, vertical: 6),
      color: TavliColors.primary,
      child: Row(
        children: [
          // Opponent avatar.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TavliColors.surfaceDark,
              border: Border.all(
                color: gs.isOpponentTurn
                    ? TavliColors.surface
                    : TavliColors.primary,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                gs.opponentName.isNotEmpty
                    ? gs.opponentName[0].toUpperCase()
                    : 'O',
                style: theme.textTheme.headlineSmall!.copyWith(
                  color: TavliColors.light,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: TavliSpacing.xs),
          Text(
            gs.opponentName,
            style: theme.textTheme.titleSmall!.copyWith(
              color: TavliColors.light,
            ),
          ),
          const SizedBox(width: TavliSpacing.xxs),
          Text(
            '(${gs.opponentRating})',
            style: theme.textTheme.bodySmall!.copyWith(
              color: TavliColors.disabledOnPrimary,
            ),
          ),
          const Spacer(),
          // Turn timer (show when it's opponent's turn).
          if (gs.isOpponentTurn && gs.phase != GamePhase.gameOver)
            const TurnTimer(
              totalSeconds: 30,
            ),
          // Cube indicator.
          if (gs.doublingCube.value > 1) ...[
            const SizedBox(width: TavliSpacing.xs),
            _buildCubeIndicator(gs),
          ],
          const SizedBox(width: TavliSpacing.xs),
          // Opponent pip count.
          Text(
            'Pips: ${gs.board.pipCount(gs.localPlayerNumber == 1 ? 2 : 1)}',
            style: theme.textTheme.bodySmall!.copyWith(
              color: TavliColors.light.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCubeIndicator(OnlineGameState gs) {
    final theme = Theme.of(context);
    final ownerText = gs.doublingCube.owner == null
        ? ''
        : gs.doublingCube.owner == gs.localPlayerKey
            ? ' (You)'
            : ' (Opp)';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: TavliColors.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(TavliRadius.xs),
        border:
            Border.all(color: TavliColors.surface.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${gs.doublingCube.value}x$ownerText',
        style: theme.textTheme.labelSmall!.copyWith(
          color: TavliColors.surface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomBar(OnlineGameState gs) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md, vertical: 6),
      color: TavliColors.primary,
      child: Row(
        children: [
          // Player avatar.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TavliColors.surfaceDark,
              border: Border.all(
                color: gs.isMyTurn
                    ? TavliColors.surface
                    : TavliColors.primary,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                'P',
                style: theme.textTheme.headlineSmall!.copyWith(
                  color: TavliColors.light,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: TavliSpacing.xs),
          Text(
            'You',
            style: theme.textTheme.bodyMedium!.copyWith(color: TavliColors.light),
          ),
          const SizedBox(width: TavliSpacing.xs),
          Text(
            'Pips: ${gs.board.pipCount(gs.localPlayerNumber)}',
            style: theme.textTheme.bodySmall!.copyWith(
              color: TavliColors.light.withValues(alpha: 0.85),
            ),
          ),
          const Spacer(),
          // Double button.
          if (gs.canOfferDouble)
            TextButton.icon(
              onPressed: () =>
                  ref.read(onlineGameProvider(_params).notifier).offerDouble(),
              icon: const Icon(Icons.casino, size: 16),
              label: Text('Double', style: theme.textTheme.bodySmall),
              style: TextButton.styleFrom(
                foregroundColor: TavliColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.xs),
                minimumSize: const Size(0, 32),
              ),
            ),
          // Undo button.
          if (gs.currentTurnMoves.isNotEmpty && gs.isMyTurn)
            IconButton(
              onPressed: () =>
                  ref.read(onlineGameProvider(_params).notifier).undoMove(),
              icon:
                  const Icon(Icons.undo, color: TavliColors.light),
              iconSize: 20,
            ),
          // Chat button.
          IconButton(
            onPressed: _showChatPanel,
            icon: const Icon(Icons.chat_bubble_outline,
                color: TavliColors.light),
            iconSize: 20,
          ),
          // Menu button.
          IconButton(
            onPressed: () => _showPauseMenu(context),
            icon: const Icon(Icons.menu, color: TavliColors.light),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  void _showPauseMenu(BuildContext context) {
    final theme = Theme.of(context);
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
            Text(
              'MENU',
              style: theme.textTheme.headlineMedium!.copyWith(
                color: TavliColors.light,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: TavliSpacing.md),
            _menuBtn('Resume', () => Navigator.pop(ctx)),
            _menuBtn('Resign', () {
              Navigator.pop(ctx);
              _showResignConfirmation();
            }),
            _menuBtn('Exit to Lobby', () {
              Navigator.pop(ctx);
              context.go('/online-lobby');
            }),
          ],
        ),
      ),
    );
  }

  void _showResignConfirmation() {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Resign?'),
        content: const Text(
          'Are you sure you want to resign? This counts as a loss.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(onlineGameProvider(_params).notifier).resign();
            },
            child: const Text('Resign'),
          ),
        ],
      ),
    );
  }

  Widget _buildDoubleOfferOverlay(OnlineGameState gs) {
    final theme = Theme.of(context);
    final newValue = gs.doublingCube.value * 2;
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(TavliSpacing.lg),
          decoration: BoxDecoration(
            color: TavliColors.surfaceDark,
            borderRadius: BorderRadius.circular(TavliRadius.lg),
            border: Border.all(
              color: TavliColors.surface.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                gs.opponentName.isNotEmpty
                    ? gs.opponentName[0].toUpperCase()
                    : 'O',
                style: theme.textTheme.displaySmall!.copyWith(
                  color: TavliColors.surface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: TavliSpacing.xs),
              Text(
                '${gs.opponentName} offers a double!',
                style: theme.textTheme.headlineSmall!.copyWith(
                  color: TavliColors.light,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cube goes to ${newValue}x',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: TavliColors.disabledOnPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'If you decline, you lose ${gs.doublingCube.value} point${gs.doublingCube.value > 1 ? 's' : ''}.',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: TavliColors.error.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ref
                          .read(onlineGameProvider(_params).notifier)
                          .declineDouble(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TavliColors.error,
                        side: const BorderSide(color: TavliColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: TavliSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => ref
                          .read(onlineGameProvider(_params).notifier)
                          .acceptDouble(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TavliColors.surface,
                        foregroundColor: TavliColors.surfaceDark,
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

  Widget _buildConnectionBanner(OnlineGameState gs) {
    final theme = Theme.of(context);
    final text = switch (gs.connectionStatus) {
      ConnectionStatus.reconnecting => 'Reconnecting...',
      ConnectionStatus.opponentDisconnected => 'Opponent may have disconnected',
      ConnectionStatus.disconnected => 'Connection lost',
      ConnectionStatus.connected => '',
    };

    return Positioned(
      top: 60,
      left: TavliSpacing.md,
      right: TavliSpacing.md,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: gs.connectionStatus == ConnectionStatus.opponentDisconnected
              ? TavliColors.error
              : Colors.orange.shade800,
          borderRadius: BorderRadius.circular(TavliRadius.sm),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white, size: 18),
            const SizedBox(width: TavliSpacing.xs),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall!.copyWith(color: Colors.white, fontSize: 13),
              ),
            ),
            if (gs.connectionStatus ==
                ConnectionStatus.opponentDisconnected)
              TextButton(
                onPressed: () => ref
                    .read(onlineGameProvider(_params).notifier)
                    .claimAbandonment(),
                child: Text(
                  'Claim Win',
                  style: theme.textTheme.bodySmall!.copyWith(color: Colors.white),
                ),
              ),
          ],
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
            backgroundColor: TavliColors.surface,
            foregroundColor: TavliColors.primary,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  // Helper to create a default board for initial TavliGame construction.
  static BoardState _defaultBoard() => BoardState.initial();
}

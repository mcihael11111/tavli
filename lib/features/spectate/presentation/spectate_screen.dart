import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/content_module.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../multiplayer/data/game_room.dart';
import '../data/spectate_service.dart';

/// Screen for browsing active games and selecting one to spectate.
class SpectateListScreen extends StatefulWidget {
  const SpectateListScreen({super.key});

  @override
  State<SpectateListScreen> createState() => _SpectateListScreenState();
}

class _SpectateListScreenState extends State<SpectateListScreen> {
  final _service = SpectateService();
  List<GameRoom> _games = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    try {
      final games = await _service.getActiveGames();
      if (mounted) setState(() { _games = games; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Spectate'),
        actions: [
          IconButton(
            onPressed: () { setState(() => _loading = true); _loadGames(); },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _games.isEmpty
              ? _buildEmpty(theme)
              : _buildList(theme),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_off, size: 48, color: TavliColors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: TavliSpacing.sm),
          Text('No live games', style: theme.textTheme.headlineMedium),
          const SizedBox(height: TavliSpacing.xxs),
          Text(
            'Check back when players are online!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: TavliColors.light.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadGames,
      child: ListView.builder(
        padding: const EdgeInsets.all(TavliSpacing.md),
        itemCount: _games.length,
        itemBuilder: (context, index) {
          final game = _games[index];
          return _GameCard(
            game: game,
            onTap: () => _openSpectateView(game),
          );
        },
      ),
    );
  }

  void _openSpectateView(GameRoom game) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpectateGameScreen(gameRoomId: game.gameId),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameRoom game;
  final VoidCallback onTap;

  const _GameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p1 = game.player1;
    final p2 = game.player2;

    return Padding(
      padding: const EdgeInsets.only(bottom: TavliSpacing.xs),
      child: ContentModule(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p1.name} vs ${p2?.name ?? "Waiting..."}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: TavliSpacing.xxs),
                  Text(
                    'Rating: ${p1.rating} vs ${p2?.rating ?? "?"} · ${game.variant}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: TavliColors.light.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TavliSpacing.xs,
                vertical: TavliSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: TavliColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(TavliRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.visibility, size: 14, color: TavliColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: TavliColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// View-only screen for watching a live game.
class SpectateGameScreen extends StatefulWidget {
  final String gameRoomId;

  const SpectateGameScreen({super.key, required this.gameRoomId});

  @override
  State<SpectateGameScreen> createState() => _SpectateGameScreenState();
}

class _SpectateGameScreenState extends State<SpectateGameScreen> {
  final _service = SpectateService();
  StreamSubscription<GameRoom>? _subscription;
  GameRoom? _room;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _subscription = _service.watchGame(widget.gameRoomId).listen((room) {
      if (mounted) setState(() { _room = room; _loading = false; });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading || _room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Spectating...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final room = _room!;
    final isFinished = room.status == GameRoomStatus.finished ||
        room.status == GameRoomStatus.abandoned;

    return Scaffold(
      appBar: AppBar(
        title: Text('${room.player1.name} vs ${room.player2?.name ?? "?"}'),
        actions: [
          if (isFinished)
            Padding(
              padding: const EdgeInsets.only(right: TavliSpacing.md),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TavliSpacing.xs,
                    vertical: TavliSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: TavliColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(TavliRadius.sm),
                  ),
                  child: const Text(
                    'FINISHED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: TavliColors.warning,
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: TavliSpacing.md),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TavliSpacing.xs,
                    vertical: TavliSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: TavliColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(TavliRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: TavliColors.success,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: TavliColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Player info bar
          _buildPlayerBar(theme, room),

          // Board (simplified view)
          Expanded(child: _buildBoard(theme, room)),

          // Dice display
          if (room.diceRoll != null) _buildDice(theme, room.diceRoll!),

          // Status bar
          _buildStatusBar(theme, room),
        ],
      ),
    );
  }

  Widget _buildPlayerBar(ThemeData theme, GameRoom room) {
    final isP1Turn = room.currentTurn == 'player1';
    return Container(
      padding: const EdgeInsets.all(TavliSpacing.sm),
      color: TavliColors.surface,
      child: Row(
        children: [
          _playerChip(room.player1.name, room.player1.rating, isP1Turn, true),
          const Spacer(),
          if (room.doublingCube.value > 1)
            Container(
              padding: const EdgeInsets.all(TavliSpacing.xxs),
              decoration: BoxDecoration(
                color: TavliColors.warning,
                borderRadius: BorderRadius.circular(TavliRadius.xs),
              ),
              child: Text(
                '${room.doublingCube.value}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: TavliColors.text,
                ),
              ),
            ),
          const Spacer(),
          _playerChip(
            room.player2?.name ?? '?',
            room.player2?.rating ?? 0,
            !isP1Turn,
            false,
          ),
        ],
      ),
    );
  }

  Widget _playerChip(String name, int rating, bool isActive, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TavliSpacing.sm,
        vertical: TavliSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? TavliColors.primary.withValues(alpha: 0.2)
            : TavliColors.background.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(TavliRadius.md),
        border: isActive ? Border.all(color: TavliColors.primary) : null,
      ),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: TavliColors.light,
            ),
          ),
          Text(
            '$rating',
            style: TextStyle(
              fontSize: 11,
              color: TavliColors.light.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(ThemeData theme, GameRoom room) {
    final boardData = room.boardState;
    final points = (boardData['points'] as List?)?.cast<int>() ?? List.filled(24, 0);

    return Padding(
      padding: const EdgeInsets.all(TavliSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: TavliColors.primary,
          borderRadius: BorderRadius.circular(TavliRadius.lg),
          border: Border.all(color: TavliColors.background),
          boxShadow: TavliShadows.medium,
        ),
        child: Padding(
          padding: const EdgeInsets.all(TavliSpacing.sm),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (int i = 12; i < 24; i++)
                      Expanded(child: _buildPointWidget(i, points)),
                  ],
                ),
              ),
              const Divider(color: TavliColors.primary, height: 1),
              Expanded(
                child: Row(
                  children: [
                    for (int i = 11; i >= 0; i--)
                      Expanded(child: _buildPointWidget(i, points)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointWidget(int index, List<int> points) {
    final count = points[index];
    final isP1 = count > 0;
    final absCount = count.abs();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (absCount > 0)
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isP1 ? TavliColors.checkerDark : TavliColors.checkerLight,
              border: Border.all(color: TavliColors.primary, width: 0.5),
            ),
            child: Center(
              child: Text(
                '$absCount',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isP1 ? TavliColors.light : TavliColors.text,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDice(ThemeData theme, DiceState dice) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TavliSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _dieWidget(dice.die1),
          const SizedBox(width: TavliSpacing.sm),
          _dieWidget(dice.die2),
        ],
      ),
    );
  }

  Widget _dieWidget(int value) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: TavliColors.light,
        borderRadius: BorderRadius.circular(TavliRadius.sm),
        border: Border.all(color: TavliColors.primary),
        boxShadow: TavliShadows.xsmall,
      ),
      child: Center(
        child: Text(
          '$value',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: TavliColors.text,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(ThemeData theme, GameRoom room) {
    final currentPlayer = room.currentTurn == 'player1'
        ? room.player1.name
        : (room.player2?.name ?? '?');

    return Container(
      padding: const EdgeInsets.all(TavliSpacing.sm),
      color: TavliColors.background,
      child: Center(
        child: Text(
          room.status == GameRoomStatus.finished
              ? 'Game over — ${room.winner == "player1" ? room.player1.name : room.player2?.name ?? "?"} wins!'
              : "$currentPlayer's turn · Move ${room.moveHistory.length + 1}",
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

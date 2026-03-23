import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/multiplayer_service_provider.dart';
import '../matchmaking/firestore_matchmaking_service.dart';

/// Screen shown while searching for an opponent.
class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  late FirestoreMatchmakingService _matchmaking;
  StreamSubscription<MatchmakingStatus>? _subscription;
  int _elapsedSeconds = 0;
  Timer? _elapsedTimer;
  bool _matched = false;

  @override
  void initState() {
    super.initState();
    _matchmaking = FirestoreMatchmakingService(
      multiplayerService: ref.read(multiplayerServiceProvider),
    );
    _startSearching();
  }

  Future<void> _startSearching() async {
    final profileAsync = await ref.read(currentPlayerProfileProvider.future);
    if (profileAsync == null || !mounted) return;

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });

    _subscription = _matchmaking
        .findMatch(
      playerUid: profileAsync.uid,
      playerName: profileAsync.displayName,
      rating: profileAsync.rating,
    )
        .listen((status) {
      if (status.isMatched && status.gameRoomId != null && !_matched) {
        _matched = true;
        _navigateToGame(status.gameRoomId!, profileAsync.uid);
      }
    });
  }

  void _navigateToGame(String gameRoomId, String playerUid) {
    if (!mounted) return;
    context.go('/online-game', extra: {
      'gameRoomId': gameRoomId,
      'localPlayerNumber': 1, // Creator is always player 1.
      'localPlayerUid': playerUid,
    });
  }

  Future<void> _cancel() async {
    final profile = await ref.read(currentPlayerProfileProvider.future);
    if (profile != null) {
      await _matchmaking.cancelMatchmaking(profile.uid);
    }
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _elapsedTimer?.cancel();
    _matchmaking.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Match'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _cancel,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(colors.primary),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Searching for opponent...',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              timeText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _elapsedSeconds < 10
                  ? 'Looking for players near your rating...'
                  : _elapsedSeconds < 30
                      ? 'Expanding search range...'
                      : 'Searching all available players...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 48),
            OutlinedButton(
              onPressed: _cancel,
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

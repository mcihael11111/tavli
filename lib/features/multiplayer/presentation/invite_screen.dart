import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../social/invite/invite_service.dart';
import '../data/game_room.dart';
import '../data/multiplayer_service_provider.dart';

/// Screen for creating a room and sharing the invite.
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _inviteService = InviteService();
  String? _gameRoomId;
  bool _creating = false;
  StreamSubscription<GameRoom>? _roomSubscription;
  bool _opponentJoined = false;
  String? _roomError;

  @override
  void initState() {
    super.initState();
    _createRoom();
  }

  Future<void> _createRoom() async {
    setState(() => _creating = true);

    final profile = await ref.read(currentPlayerProfileProvider.future);
    if (profile == null || !mounted) return;

    final service = ref.read(multiplayerServiceProvider);
    final roomId = await service.createRoom(
      playerUid: profile.uid,
      playerName: profile.displayName,
      playerRating: profile.rating,
    );

    if (!mounted) return;
    setState(() {
      _gameRoomId = roomId;
      _creating = false;
    });

    // Watch for opponent joining.
    _roomSubscription = service.watchRoom(roomId).listen(
      (room) {
        if (room.status == GameRoomStatus.inProgress && !_opponentJoined) {
          _opponentJoined = true;
          _navigateToGame(profile.uid);
        }
      },
      onError: (error) {
        debugPrint('Invite room stream error: $error');
        if (mounted) setState(() => _roomError = error.toString());
      },
    );
  }

  void _navigateToGame(String playerUid) {
    if (!mounted) return;
    context.go('/online-game', extra: {
      'gameRoomId': _gameRoomId,
      'localPlayerNumber': 1,
      'localPlayerUid': playerUid,
    });
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Invite Friend'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _roomError != null
          ? ErrorStateWidget(
              title: 'Room error',
              message: 'Could not watch for opponent.',
              onRetry: _createRoom,
            )
          : _creating || _gameRoomId == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Room code.
                    Text(
                      'Room Code',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: TavliSpacing.xs),
                    Semantics(
                      button: true,
                      label: 'Copy room code',
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: _gameRoomId!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Room code copied!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: TavliSpacing.lg, vertical: TavliSpacing.sm),
                        decoration: BoxDecoration(
                          color: TavliColors.primary,
                          borderRadius: BorderRadius.circular(TavliRadius.md),
                          border: Border.all(color: TavliColors.background),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _gameRoomId!,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(width: TavliSpacing.xs),
                            const Icon(Icons.copy,
                                size: 20, color: TavliColors.primary),
                          ],
                        ),
                      ),
                      ),
                    ),
                    const SizedBox(height: TavliSpacing.xl),

                    // QR code.
                    Container(
                      padding: const EdgeInsets.all(TavliSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(TavliRadius.lg),
                      ),
                      child: QrImageView(
                        data: _inviteService.generateQrData(_gameRoomId!),
                        version: QrVersions.auto,
                        size: 200,
                      ),
                    ),
                    const SizedBox(height: TavliSpacing.lg),

                    // Share button.
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final link = _inviteService
                              .generateDeepLink(_gameRoomId!);
                          Share.share(
                            'Join my Tavli game! Code: $_gameRoomId\n$link',
                          );
                        },
                        icon: const Icon(Icons.share, size: 20),
                        label: const Text('Share Invite'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: TavliSpacing.xl),

                    // Waiting indicator.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(colors.primary),
                          ),
                        ),
                        const SizedBox(width: TavliSpacing.sm),
                        Text(
                          'Waiting for opponent to join...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                colors.onSurface.withValues(alpha: 0.6),
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
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../social/invite/invite_service.dart';
import '../data/multiplayer_service_provider.dart';

/// Screen for joining a game room via code or QR scan.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  final _codeController = TextEditingController();
  bool _joining = false;
  String? _error;

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter a room code.');
      return;
    }

    setState(() {
      _joining = true;
      _error = null;
    });

    final profile = await ref.read(currentPlayerProfileProvider.future);
    if (profile == null || !mounted) return;

    final service = ref.read(multiplayerServiceProvider);
    final success = await service.joinRoom(
      gameId: code,
      playerUid: profile.uid,
      playerName: profile.displayName,
      playerRating: profile.rating,
    );

    if (!mounted) return;

    if (success) {
      context.go('/online-game', extra: {
        'gameRoomId': code,
        'localPlayerNumber': 2,
        'localPlayerUid': profile.uid,
      });
    } else {
      setState(() {
        _joining = false;
        _error = 'Room not found or already full.';
      });
    }
  }

  void _scanQrCode() {
    final inviteService = InviteService();

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Scan QR Code',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    final value = barcode.rawValue;
                    if (value == null) continue;

                    final roomId = inviteService.parseInviteLink(value);
                    if (roomId != null) {
                      Navigator.pop(ctx);
                      _codeController.text = roomId;
                      _joinRoom();
                      return;
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Join Room'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login, size: 48, color: TavliColors.primary),
            const SizedBox(height: 24),
            Text(
              'Enter Room Code',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Code input.
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'ABCD1234',
                hintStyle: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.3),
                  letterSpacing: 4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onSubmitted: (_) => _joinRoom(),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: colors.error, fontSize: 13),
              ),
            ],

            const SizedBox(height: 24),

            // Join button.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _joining ? null : _joinRoom,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _joining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Join Game'),
              ),
            ),

            const SizedBox(height: 32),

            // QR scan option.
            OutlinedButton.icon(
              onPressed: _scanQrCode,
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              label: const Text('Scan QR Code'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

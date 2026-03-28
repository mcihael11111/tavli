import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../multiplayer/data/ble_board_service.dart';
import '../data/ble_board_impl.dart';

/// Screen for pairing two phones for the dual-board experience.
class DualBoardPairingScreen extends StatefulWidget {
  const DualBoardPairingScreen({super.key});

  @override
  State<DualBoardPairingScreen> createState() =>
      _DualBoardPairingScreenState();
}

class _DualBoardPairingScreenState extends State<DualBoardPairingScreen> {
  final BleBoardImpl _bleService = BleBoardImpl();
  BleConnectionState _connectionState = BleConnectionState.idle;
  final List<BleDiscoveredDevice> _devices = [];
  StreamSubscription<BleConnectionState>? _stateSubscription;
  StreamSubscription<BleDiscoveredDevice>? _deviceSubscription;

  @override
  void initState() {
    super.initState();
    _stateSubscription = _bleService.connectionStateStream.listen((state) {
      if (mounted) setState(() => _connectionState = state);
      if (state == BleConnectionState.connected) {
        _navigateToGame();
      }
    });
    _deviceSubscription =
        _bleService.discoveredDevices.listen((device) {
      if (mounted) {
        setState(() {
          if (!_devices.any((d) => d.id == device.id)) {
            _devices.add(device);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _deviceSubscription?.cancel();
    _bleService.dispose();
    super.dispose();
  }

  void _startAsHost() {
    _bleService.startAdvertising();
  }

  void _startAsClient() {
    _bleService.startScanning();
  }

  void _connectToDevice(BleDiscoveredDevice device) {
    _bleService.connect(device.id);
  }

  void _navigateToGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DualBoardGameScreen(bleService: _bleService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientScaffold(
      appBar: AppBar(title: const Text('Dual-Phone Board')),
      body: Padding(
        padding: const EdgeInsets.all(TavliSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(TavliSpacing.md),
              decoration: BoxDecoration(
                color: TavliColors.primary,
                borderRadius: BorderRadius.circular(TavliRadius.lg),
                border: Border.all(color: TavliColors.background),
              ),
              child: Column(
                children: [
                  const Icon(Icons.phone_android, size: 40, color: TavliColors.primary),
                  const SizedBox(height: TavliSpacing.sm),
                  Text(
                    'Place two phones side by side',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: TavliSpacing.xxs),
                  Text(
                    'Each phone shows half the board.\nOne phone hosts, the other joins.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: TavliColors.light.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: TavliSpacing.xl),

            // Role selection (only when idle)
            if (_connectionState == BleConnectionState.idle) ...[
              FilledButton.icon(
                onPressed: _startAsHost,
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Host (Left Half)'),
                style: FilledButton.styleFrom(
                  backgroundColor: TavliColors.primary,
                  padding: const EdgeInsets.all(TavliSpacing.md),
                ),
              ),
              const SizedBox(height: TavliSpacing.sm),
              OutlinedButton.icon(
                onPressed: _startAsClient,
                icon: const Icon(Icons.search),
                label: const Text('Join (Right Half)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TavliColors.light,
                  backgroundColor: TavliColors.background.withValues(alpha: 0.15),
                  side: BorderSide(color: TavliColors.light.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.all(TavliSpacing.md),
                ),
              ),
            ],

            // Advertising state
            if (_connectionState == BleConnectionState.advertising)
              _buildStatusCard(
                theme,
                icon: Icons.wifi_tethering,
                title: 'Waiting for partner...',
                subtitle: 'Make sure the other phone taps "Join"',
                showProgress: true,
              ),

            // Scanning state
            if (_connectionState == BleConnectionState.scanning) ...[
              _buildStatusCard(
                theme,
                icon: Icons.bluetooth_searching,
                title: 'Searching for host...',
                subtitle: 'Looking for nearby Tavli devices',
                showProgress: true,
              ),
              const SizedBox(height: TavliSpacing.md),
              if (_devices.isNotEmpty) ...[
                const Text(
                  'FOUND DEVICES',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                    color: TavliColors.light,
                  ),
                ),
                const SizedBox(height: TavliSpacing.xs),
                ..._devices.map((device) => ListTile(
                      leading: const Icon(Icons.phone_android,
                          color: TavliColors.primary),
                      title: Text(device.name.isEmpty ? 'Tavli Board' : device.name),
                      subtitle: Text('Signal: ${device.rssi} dBm'),
                      trailing: FilledButton(
                        onPressed: () => _connectToDevice(device),
                        child: const Text('Connect'),
                      ),
                    )),
              ],
            ],

            // Connecting state
            if (_connectionState == BleConnectionState.connecting)
              _buildStatusCard(
                theme,
                icon: Icons.bluetooth_connected,
                title: 'Connecting...',
                subtitle: 'Establishing link',
                showProgress: true,
              ),

            // Connected (briefly shown before navigation)
            if (_connectionState == BleConnectionState.connected)
              _buildStatusCard(
                theme,
                icon: Icons.check_circle,
                title: 'Connected!',
                subtitle: 'Starting game...',
                showProgress: false,
                iconColor: TavliColors.success,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool showProgress = false,
    Color iconColor = TavliColors.primary,
  }) {
    return Container(
      padding: const EdgeInsets.all(TavliSpacing.lg),
      decoration: BoxDecoration(
        color: TavliColors.primary,
        borderRadius: BorderRadius.circular(TavliRadius.lg),
        border: Border.all(color: TavliColors.background),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: iconColor),
          const SizedBox(height: TavliSpacing.sm),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: TavliColors.light.withValues(alpha: 0.6),
            ),
          ),
          if (showProgress) ...[
            const SizedBox(height: TavliSpacing.sm),
            const LinearProgressIndicator(
              color: TavliColors.primary,
              backgroundColor: TavliColors.background,
            ),
          ],
        ],
      ),
    );
  }
}

/// The actual dual-board game screen — renders only half the board.
///
/// This is the landscape-only screen shown during dual-phone play.
/// Host shows points 1-12 (left half), client shows points 13-24 (right half).
class DualBoardGameScreen extends StatefulWidget {
  final BleBoardImpl bleService;

  const DualBoardGameScreen({super.key, required this.bleService});

  @override
  State<DualBoardGameScreen> createState() => _DualBoardGameScreenState();
}

class _DualBoardGameScreenState extends State<DualBoardGameScreen> {
  StreamSubscription<SyncMessage>? _messageSubscription;
  List<int> _points = List.filled(24, 0);
  int _bar1 = 0;
  int _bar2 = 0;
  int _borneOff1 = 0;
  int _borneOff2 = 0;
  int _activePlayer = 1;
  int? _die1;
  int? _die2;

  bool get _isHost => widget.bleService.role == DualPhoneRole.host;

  /// The range of points this device renders.
  /// Host: 0-11 (points 1-12), Client: 12-23 (points 13-24)
  int get _startPoint => _isHost ? 0 : 12;
  int get _endPoint => _isHost ? 12 : 24;

  @override
  void initState() {
    super.initState();
    // Lock to landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _messageSubscription =
        widget.bleService.incomingMessages.listen(_onMessage);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    // Restore orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _onMessage(SyncMessage message) {
    switch (message.type) {
      case SyncMessageType.fullState:
        setState(() {
          _points = (message.data['points'] as List).cast<int>();
          _bar1 = message.data['bar1'] as int;
          _bar2 = message.data['bar2'] as int;
          _borneOff1 = message.data['borneOff1'] as int;
          _borneOff2 = message.data['borneOff2'] as int;
          _activePlayer = message.data['activePlayer'] as int;
        });
        break;
      case SyncMessageType.diceRolled:
        setState(() {
          _die1 = message.data['die1'] as int;
          _die2 = message.data['die2'] as int;
        });
        break;
      case SyncMessageType.checkerCrossing:
        // Animate a checker entering/leaving this half of the board
        _handleCheckerCrossing(message.data);
        break;
      default:
        break;
    }
  }

  void _handleCheckerCrossing(Map<String, dynamic> data) {
    // TODO: Animate checker entering from edge based on crossing data
    debugPrint('DualBoard: Checker crossing ${data['edge']} at y=${data['y']}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TavliColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Connection status bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TavliSpacing.sm,
                vertical: TavliSpacing.xxs,
              ),
              color: TavliColors.primary,
              child: Row(
                children: [
                  Icon(
                    widget.bleService.isConnected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    size: 14,
                    color: TavliColors.light,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isHost ? 'Host · Points 1-12' : 'Client · Points 13-24',
                    style: const TextStyle(
                      fontSize: 11,
                      color: TavliColors.light,
                    ),
                  ),
                  const Spacer(),
                  if (_die1 != null && _die2 != null)
                    Text(
                      'Dice: $_die1-$_die2',
                      style: const TextStyle(
                        fontSize: 11,
                        color: TavliColors.light,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(width: TavliSpacing.sm),
                  Text(
                    'Player $_activePlayer\'s turn',
                    style: const TextStyle(
                      fontSize: 11,
                      color: TavliColors.light,
                    ),
                  ),
                ],
              ),
            ),

            // Half-board rendering
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(TavliSpacing.xs),
                child: Row(
                  children: [
                    // Top row of this half (6 points)
                    Expanded(
                      child: Column(
                        children: [
                          // Upper points
                          Expanded(
                            child: Row(
                              children: [
                                for (int i = _startPoint + 6; i < _endPoint; i++)
                                  Expanded(child: _buildHalfPoint(i, true)),
                              ],
                            ),
                          ),
                          // Bar area
                          Container(
                            height: 30,
                            color: TavliColors.primary.withValues(alpha: 0.1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Bar: $_bar1/$_bar2  Off: $_borneOff1/$_borneOff2',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: TavliColors.light,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Lower points
                          Expanded(
                            child: Row(
                              children: [
                                for (int i = _startPoint + 5;
                                    i >= _startPoint;
                                    i--)
                                  Expanded(child: _buildHalfPoint(i, false)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHalfPoint(int index, bool isTop) {
    final count = _points[index];
    final isP1 = count > 0;
    final absCount = count.abs();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: (index % 2 == 0)
            ? TavliColors.mahoganyDark.withValues(alpha: 0.3)
            : TavliColors.oliveWoodLight.withValues(alpha: 0.3),
        borderRadius: isTop
            ? const BorderRadius.vertical(top: Radius.circular(4))
            : const BorderRadius.vertical(bottom: Radius.circular(4)),
      ),
      child: Column(
        mainAxisAlignment:
            isTop ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isTop) const Spacer(),
          // Stack checkers
          for (int c = 0; c < absCount && c < 5; c++)
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.symmetric(vertical: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isP1 ? TavliColors.checkerDark : TavliColors.checkerLight,
                border: Border.all(
                  color: isP1
                      ? TavliColors.text.withValues(alpha: 0.3)
                      : TavliColors.primary.withValues(alpha: 0.3),
                ),
                boxShadow: const [
                  BoxShadow(blurRadius: 2, color: Color(0x33000000)),
                ],
              ),
              child: absCount > 5 && c == 4
                  ? Center(
                      child: Text(
                        '$absCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isP1 ? TavliColors.light : TavliColors.text,
                        ),
                      ),
                    )
                  : null,
            ),
          if (isTop) const Spacer(),
          // Point number
          Padding(
            padding: const EdgeInsets.only(bottom: 2, top: 2),
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontSize: 8, color: TavliColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

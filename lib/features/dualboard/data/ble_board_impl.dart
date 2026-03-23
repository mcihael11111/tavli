import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../../game/data/models/board_state.dart';
import '../../multiplayer/data/ble_board_service.dart';

/// Concrete BLE implementation for dual-phone board.
///
/// Uses a simple message-passing protocol over BLE characteristics.
/// Each device renders half the board (12 points) and syncs game state.
///
/// Protocol:
/// 1. Host starts advertising, client scans
/// 2. Client connects → both exchange hello messages
/// 3. Host sends calibration data, client responds
/// 4. Host owns game state, sends fullState to sync
/// 5. Moves are sent as moveApplied messages
/// 6. Checkers crossing screen boundary trigger checkerCrossing animation
///
/// Note: Actual BLE communication requires flutter_blue_plus or similar.
/// This implementation provides the protocol layer; platform BLE is stubbed
/// until flutter_blue_plus is added as a dependency.
class BleBoardImpl implements BleBoardService {
  // ── Connection state ──────────────────────────────────────────
  bool _connected = false;
  DualPhoneRole? _currentRole;
  String? _connectedDeviceId;
  String? _connectedDeviceName;

  // ── Message streams ───────────────────────────────────────────
  final StreamController<SyncMessage> _incomingController =
      StreamController<SyncMessage>.broadcast();
  final StreamController<BleDiscoveredDevice> _discoveredDevices =
      StreamController<BleDiscoveredDevice>.broadcast();
  final StreamController<BleConnectionState> _connectionState =
      StreamController<BleConnectionState>.broadcast();

  // ── Calibration ───────────────────────────────────────────────
  ScreenCalibration? _localCalibration;
  ScreenCalibration? _remoteCalibration;

  // ── Heartbeat ─────────────────────────────────────────────────
  Timer? _heartbeatTimer;
  DateTime? _lastRemoteHeartbeat;

  // ── Service UUIDs ─────────────────────────────────────────────
  static const serviceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const txCharUuid = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E';
  static const rxCharUuid = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';
  static const advertisingName = 'Tavli-Board';

  @override
  bool get isConnected => _connected;

  @override
  DualPhoneRole? get role => _currentRole;

  String? get connectedDeviceName => _connectedDeviceName;
  ScreenCalibration? get remoteCalibration => _remoteCalibration;

  @override
  Stream<SyncMessage> get incomingMessages => _incomingController.stream;

  /// Stream of discovered Tavli devices during scanning.
  Stream<BleDiscoveredDevice> get discoveredDevices =>
      _discoveredDevices.stream;

  /// Stream of connection state changes.
  Stream<BleConnectionState> get connectionStateStream =>
      _connectionState.stream;

  @override
  Future<void> startScanning() async {
    _connectionState.add(BleConnectionState.scanning);
    debugPrint('BLE: Starting scan for Tavli devices...');

    // TODO: Replace with flutter_blue_plus scanning
    // FlutterBluePlus.startScan(
    //   withServices: [Guid(serviceUuid)],
    //   timeout: const Duration(seconds: 15),
    // ).listen((result) {
    //   _discoveredDevices.add(BleDiscoveredDevice(
    //     id: result.device.remoteId.str,
    //     name: result.device.platformName,
    //     rssi: result.rssi,
    //   ));
    // });
  }

  @override
  Future<void> stopScanning() async {
    debugPrint('BLE: Stopping scan.');
    // TODO: FlutterBluePlus.stopScan();
  }

  @override
  Future<bool> connect(String deviceId) async {
    debugPrint('BLE: Connecting to $deviceId...');
    _connectionState.add(BleConnectionState.connecting);

    try {
      // TODO: Replace with flutter_blue_plus connection
      // final device = BluetoothDevice.fromId(deviceId);
      // await device.connect(timeout: const Duration(seconds: 10));
      // await _discoverAndSubscribe(device);

      _connected = true;
      _connectedDeviceId = deviceId;
      _currentRole = DualPhoneRole.client;
      _connectionState.add(BleConnectionState.connected);

      // Send hello
      await sendMessage(SyncMessage(
        type: SyncMessageType.hello,
        data: {
          'role': 'client',
          'version': 1,
        },
      ));

      _startHeartbeat();
      return true;
    } catch (e) {
      debugPrint('BLE: Connection failed: $e');
      _connectionState.add(BleConnectionState.disconnected);
      return false;
    }
  }

  /// Start advertising as host (waiting for client to connect).
  Future<void> startAdvertising() async {
    _currentRole = DualPhoneRole.host;
    _connectionState.add(BleConnectionState.advertising);
    debugPrint('BLE: Advertising as host...');

    // TODO: Replace with flutter_blue_plus peripheral mode
    // or use a server characteristic that clients write to
  }

  /// Called when a client connects (host side).
  void onClientConnected(String deviceId, String deviceName) {
    _connected = true;
    _connectedDeviceId = deviceId;
    _connectedDeviceName = deviceName;
    _connectionState.add(BleConnectionState.connected);

    // Send hello
    sendMessage(SyncMessage(
      type: SyncMessageType.hello,
      data: {
        'role': 'host',
        'version': 1,
      },
    ));

    _startHeartbeat();
  }

  @override
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _connected = false;
    _connectedDeviceId = null;
    _connectedDeviceName = null;
    _connectionState.add(BleConnectionState.disconnected);

    // TODO: device.disconnect();
    debugPrint('BLE: Disconnected.');
  }

  @override
  Future<void> sendMessage(SyncMessage message) async {
    if (!_connected) return;

    final encoded = jsonEncode(message.toJson());
    final bytes = utf8.encode(encoded);

    debugPrint('BLE: Sending ${message.type.name} (${bytes.length} bytes)');

    // TODO: Write to TX characteristic
    // await _txCharacteristic?.write(bytes);
  }

  @override
  Future<void> sendCalibration(ScreenCalibration calibration) async {
    _localCalibration = calibration;
    await sendMessage(SyncMessage(
      type: SyncMessageType.calibration,
      data: calibration.toJson(),
    ));
  }

  /// Send full board state to the paired device (host → client).
  Future<void> syncBoardState(BoardState state) async {
    await sendMessage(SyncMessage(
      type: SyncMessageType.fullState,
      data: {
        'points': state.points,
        'bar1': state.bar1,
        'bar2': state.bar2,
        'borneOff1': state.borneOff1,
        'borneOff2': state.borneOff2,
        'activePlayer': state.activePlayer,
        'cube': state.doublingCubeValue,
      },
    ));
  }

  /// Notify the paired device that a checker is crossing the screen boundary.
  ///
  /// [fromPoint] and [toPoint] are the logical point indices.
  /// [crossingEdge] is 'left' or 'right' relative to this device's view.
  /// [yPosition] is the normalized y-position (0.0-1.0) of the crossing.
  Future<void> sendCheckerCrossing({
    required int fromPoint,
    required int toPoint,
    required String crossingEdge,
    required double yPosition,
    required int player,
  }) async {
    await sendMessage(SyncMessage(
      type: SyncMessageType.checkerCrossing,
      data: {
        'from': fromPoint,
        'to': toPoint,
        'edge': crossingEdge,
        'y': yPosition,
        'player': player,
      },
    ));
  }

  /// Send a dice roll result to the paired device.
  Future<void> sendDiceRoll(int die1, int die2) async {
    await sendMessage(SyncMessage(
      type: SyncMessageType.diceRolled,
      data: {'die1': die1, 'die2': die2},
    ));
  }

  // ── Internal: Message handling ────────────────────────────────

  /// Called when data is received from the BLE characteristic.
  void _onDataReceived(List<int> data) {
    try {
      final decoded = utf8.decode(data);
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      final message = SyncMessage.fromJson(json);

      debugPrint('BLE: Received ${message.type.name}');

      // Handle protocol messages internally
      switch (message.type) {
        case SyncMessageType.ping:
          _lastRemoteHeartbeat = DateTime.now();
          break;
        case SyncMessageType.calibration:
          _remoteCalibration = ScreenCalibration(
            screenWidthMm: (message.data['wMm'] as num).toDouble(),
            screenHeightMm: (message.data['hMm'] as num).toDouble(),
            pixelDensity: (message.data['dpi'] as num).toDouble(),
            boardOffsetX: (message.data['offX'] as num?)?.toDouble() ?? 0,
            boardOffsetY: (message.data['offY'] as num?)?.toDouble() ?? 0,
          );
          break;
        default:
          break;
      }

      // Forward to listeners
      _incomingController.add(message);
    } catch (e) {
      debugPrint('BLE: Failed to parse message: $e');
    }
  }

  // ── Internal: Heartbeat ───────────────────────────────────────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (_connected) {
          sendMessage(SyncMessage(
            type: SyncMessageType.ping,
            data: {},
          ));

          // Check remote heartbeat freshness
          if (_lastRemoteHeartbeat != null) {
            final staleness =
                DateTime.now().difference(_lastRemoteHeartbeat!).inSeconds;
            if (staleness > 15) {
              debugPrint('BLE: Remote heartbeat stale ($staleness s)');
              _connectionState.add(BleConnectionState.unstable);
            }
          }
        }
      },
    );
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _incomingController.close();
    _discoveredDevices.close();
    _connectionState.close();
  }
}

/// A discovered BLE device during scanning.
class BleDiscoveredDevice {
  final String id;
  final String name;
  final int rssi;

  const BleDiscoveredDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });
}

/// BLE connection lifecycle states.
enum BleConnectionState {
  idle,
  scanning,
  advertising,
  connecting,
  connected,
  unstable,
  disconnected,
}

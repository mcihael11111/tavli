/// V2 Dual-Phone Board — BLE communication architecture.
///
/// Two phones placed side-by-side in landscape form one full board
/// (12 points per phone). This service handles:
/// - BLE discovery and pairing (NFC tap-to-pair as alternative)
/// - Host/client role negotiation
/// - Cross-screen state synchronization (<50ms target)
/// - Screen calibration for different phone sizes
library;

/// Role of this device in the dual-phone setup.
enum DualPhoneRole {
  /// This device shows the left half of the board (points 1-12).
  host,
  /// This device shows the right half (points 13-24).
  client,
}

/// Sync message types between the two phones.
enum SyncMessageType {
  /// Initial handshake with device info.
  hello,
  /// Full board state sync.
  fullState,
  /// Single move applied.
  moveApplied,
  /// Dice roll result.
  diceRolled,
  /// Checker crossing from one screen to another.
  checkerCrossing,
  /// Calibration data (screen size, offset).
  calibration,
  /// Heartbeat / keep-alive.
  ping,
}

/// A sync message sent between devices.
class SyncMessage {
  final SyncMessageType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  SyncMessage({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'data': data,
        'ts': timestamp.millisecondsSinceEpoch,
      };

  factory SyncMessage.fromJson(Map<String, dynamic> json) {
    return SyncMessage(
      type: SyncMessageType.values.byName(json['type'] as String),
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
    );
  }
}

/// Calibration data for aligning two different phone screens.
class ScreenCalibration {
  final double screenWidthMm;
  final double screenHeightMm;
  final double pixelDensity;
  final double boardOffsetX;
  final double boardOffsetY;

  const ScreenCalibration({
    required this.screenWidthMm,
    required this.screenHeightMm,
    required this.pixelDensity,
    this.boardOffsetX = 0,
    this.boardOffsetY = 0,
  });

  Map<String, dynamic> toJson() => {
        'wMm': screenWidthMm,
        'hMm': screenHeightMm,
        'dpi': pixelDensity,
        'offX': boardOffsetX,
        'offY': boardOffsetY,
      };
}

/// BLE board service interface.
///
/// Concrete implementation will use flutter_blue_plus or similar.
/// This defines the contract for dual-phone board communication.
abstract class BleBoardService {
  /// Start scanning for nearby Tavli devices.
  Future<void> startScanning();

  /// Stop scanning.
  Future<void> stopScanning();

  /// Connect to a discovered device.
  Future<bool> connect(String deviceId);

  /// Disconnect.
  Future<void> disconnect();

  /// Send a sync message to the paired device.
  Future<void> sendMessage(SyncMessage message);

  /// Stream of incoming sync messages.
  Stream<SyncMessage> get incomingMessages;

  /// Current connection state.
  bool get isConnected;

  /// Current role (host or client).
  DualPhoneRole? get role;

  /// Send calibration data.
  Future<void> sendCalibration(ScreenCalibration calibration);
}

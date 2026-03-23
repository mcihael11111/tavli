import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Types of Tavli push notifications.
enum TavliNotificationType {
  /// An opponent made a move — it's your turn.
  yourTurn,

  /// A game invite was received.
  gameInvite,

  /// Matchmaking found an opponent.
  matchFound,

  /// Opponent offered a double.
  doubleOffered,

  /// Opponent disconnected from a game.
  opponentDisconnected,

  /// Friend request received.
  friendRequest,

  /// Generic / unknown notification.
  general,
}

/// Parsed notification payload from FCM.
class TavliNotification {
  final TavliNotificationType type;
  final String? gameRoomId;
  final String? senderName;
  final String? title;
  final String? body;

  const TavliNotification({
    required this.type,
    this.gameRoomId,
    this.senderName,
    this.title,
    this.body,
  });

  factory TavliNotification.fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final typeStr = data['type'] as String? ?? '';

    final type = switch (typeStr) {
      'your_turn' => TavliNotificationType.yourTurn,
      'game_invite' => TavliNotificationType.gameInvite,
      'match_found' => TavliNotificationType.matchFound,
      'double_offered' => TavliNotificationType.doubleOffered,
      'opponent_disconnected' => TavliNotificationType.opponentDisconnected,
      'friend_request' => TavliNotificationType.friendRequest,
      _ => TavliNotificationType.general,
    };

    return TavliNotification(
      type: type,
      gameRoomId: data['gameRoomId'] as String?,
      senderName: data['senderName'] as String?,
      title: message.notification?.title ?? data['title'] as String?,
      body: message.notification?.body ?? data['body'] as String?,
    );
  }
}

/// Top-level background message handler (must be a top-level function).
///
/// Called when the app is in the background or terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background handling is automatic for notification messages.
  // Data-only messages can be processed here if needed.
  debugPrint('Background message: ${message.messageId}');
}

/// Manages Firebase Cloud Messaging for push notifications.
///
/// Handles:
/// - Permission requests (iOS)
/// - FCM token management
/// - Foreground message handling
/// - Notification tap handling (app opened from notification)
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();

  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Stream of notifications received while app is in the foreground.
  final StreamController<TavliNotification> _foregroundNotifications =
      StreamController<TavliNotification>.broadcast();

  /// Stream of notifications tapped by the user (app opened from notification).
  final StreamController<TavliNotification> _notificationTaps =
      StreamController<TavliNotification>.broadcast();

  /// Foreground notification stream — listen for in-app display.
  Stream<TavliNotification> get onForegroundNotification =>
      _foregroundNotifications.stream;

  /// Notification tap stream — listen to navigate to relevant screen.
  Stream<TavliNotification> get onNotificationTap => _notificationTaps.stream;

  String? _fcmToken;

  /// Current FCM token (null if not yet obtained).
  String? get fcmToken => _fcmToken;

  /// Initialize the notification service.
  ///
  /// Call this after Firebase.initializeApp() in main().
  Future<void> initialize() async {
    // Register background handler.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (required on iOS, no-op on Android < 13).
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push notifications denied by user.');
      return;
    }

    debugPrint(
      'Push notification permission: ${settings.authorizationStatus}',
    );

    // Get FCM token.
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM token: $_fcmToken');
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }

    // Listen for token refresh.
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('FCM token refreshed: $newToken');
      // TODO: Update token in Firestore user profile.
    });

    // Foreground messages.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Notification tap (app in background → brought to foreground).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via notification.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // iOS foreground presentation options.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.messageId}');
    final notification = TavliNotification.fromRemoteMessage(message);
    _foregroundNotifications.add(notification);
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    final notification = TavliNotification.fromRemoteMessage(message);
    _notificationTaps.add(notification);
  }

  /// Subscribe to a topic (e.g., 'game_<roomId>' for game updates).
  Future<void> subscribeToGame(String gameRoomId) async {
    await _messaging.subscribeToTopic('game_$gameRoomId');
  }

  /// Unsubscribe from a game topic.
  Future<void> unsubscribeFromGame(String gameRoomId) async {
    await _messaging.unsubscribeFromTopic('game_$gameRoomId');
  }

  void dispose() {
    _foregroundNotifications.close();
    _notificationTaps.close();
  }
}

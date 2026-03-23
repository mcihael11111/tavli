import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firestore_multiplayer_service.dart';

/// Provides the Firestore-backed multiplayer service.
final multiplayerServiceProvider =
    Provider<FirestoreMultiplayerService>((ref) {
  return FirestoreMultiplayerService();
});

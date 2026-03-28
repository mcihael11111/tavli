import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/settings_service.dart';
import '../data/auth_service.dart';
import '../domain/player_profile.dart';

/// Provides the auth service singleton.
final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

/// Stream of Firebase auth state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Player profile provider — reads/creates profile in Firestore.
final playerProfileProvider =
    FutureProvider.family<PlayerProfile, String>((ref, uid) async {
  final firestore = FirebaseFirestore.instance;
  final doc = await firestore.collection('players').doc(uid).get();

  if (doc.exists) {
    return PlayerProfile.fromJson(doc.data()!);
  }

  // First-time user — create profile.
  // Prefer the name set during onboarding, then Firebase, then default.
  final user = FirebaseAuth.instance.currentUser;
  final onboardingName = SettingsService.instance.playerDisplayName;
  final profile = PlayerProfile.newPlayer(
    uid: uid,
    displayName: onboardingName.isNotEmpty
        ? onboardingName
        : (user?.displayName ?? 'Player'),
  );

  await firestore.collection('players').doc(uid).set(profile.toJson());
  return profile;
});

/// Convenience provider for the current user's profile.
final currentPlayerProfileProvider =
    FutureProvider<PlayerProfile?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;
  return ref.watch(playerProfileProvider(user.uid).future);
});

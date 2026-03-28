import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Abstract auth service for testability.
abstract class AuthService {
  /// Current authenticated user, or null.
  User? get currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges;

  /// Whether a user is currently signed in.
  bool get isSignedIn;

  /// Sign in anonymously (guest mode).
  Future<UserCredential> signInAnonymously();

  /// Sign in with Google account.
  Future<UserCredential> signInWithGoogle();

  /// Link an anonymous account to Google credentials.
  Future<UserCredential> linkAnonymousToGoogle();

  /// Sign out.
  Future<void> signOut();

  /// Delete the current user's account.
  Future<void> deleteAccount();
}

/// Firebase-backed auth service.
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  bool get isSignedIn => currentUser != null;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  @override
  Future<UserCredential> linkAnonymousToGoogle() async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      throw FirebaseAuthException(
        code: 'not-anonymous',
        message: 'Current user is not anonymous.',
      );
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await user.linkWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }
    await _googleSignIn.signOut();
    await user.delete();
  }
}

/// In-memory auth service for testing.
class InMemoryAuthService implements AuthService {
  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  @override
  bool get isSignedIn => _currentUser != null;

  @override
  Stream<User?> get authStateChanges => Stream.value(_currentUser);

  @override
  Future<UserCredential> signInAnonymously() async {
    throw UnimplementedError('InMemoryAuthService: use for testing only');
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    throw UnimplementedError('InMemoryAuthService: use for testing only');
  }

  @override
  Future<UserCredential> linkAnonymousToGoogle() async {
    throw UnimplementedError('InMemoryAuthService: use for testing only');
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<void> deleteAccount() async {
    _currentUser = null;
  }
}

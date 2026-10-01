import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../auth_service.dart';

/// Real authentication backed by Firebase Auth (email/password).
class FirebaseAuthService implements AuthService {
  FirebaseAuthService([fb.FirebaseAuth? auth])
      : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  AuthAccount? _map(fb.User? user) =>
      user == null ? null : AuthAccount(uid: user.uid, email: user.email ?? '');

  @override
  AuthAccount? get currentAccount => _map(_auth.currentUser);

  @override
  Stream<AuthAccount?> authStateChanges() =>
      _auth.authStateChanges().map(_map);

  @override
  Future<AuthAccount> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _map(cred.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  @override
  Future<AuthAccount> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _map(cred.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on fb.FirebaseAuthException catch (e) {
      // Firebase requires a recent login to delete; surface a clear message.
      if (e.code == 'requires-recent-login') {
        throw const AuthException(
            'For your security, please sign in again before deleting your account.');
      }
      throw AuthException(_message(e));
    }
  }

  /// Maps Firebase error codes to friendly, plain-language messages.
  String _message(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Please choose a stronger password (at least 6 characters).';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

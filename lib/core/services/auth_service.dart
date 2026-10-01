import 'dart:async';

/// Represents the authenticated account (not the profile).
class AuthAccount {
  const AuthAccount({required this.uid, required this.email});
  final String uid;
  final String email;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Abstraction over the authentication backend.
///
/// The MVP ships with an in-memory implementation ([MockAuthService]).
/// To use Firebase Auth, add the firebase packages and implement this
/// interface with a `FirebaseAuthService`, then register it in the
/// service locator. No calling code needs to change.
abstract class AuthService {
  Stream<AuthAccount?> authStateChanges();
  AuthAccount? get currentAccount;

  Future<AuthAccount> signUp({required String email, required String password});
  Future<AuthAccount> signIn({required String email, required String password});
  Future<void> signOut();

  /// Basic account recovery — sends a reset instruction to the email.
  Future<void> sendPasswordReset(String email);

  /// Permanently deletes the account (GDPR / account deletion support).
  Future<void> deleteAccount();
}

/// In-memory auth for local development and the hackathon demo.
class MockAuthService implements AuthService {
  MockAuthService();

  final _controller = StreamController<AuthAccount?>.broadcast();
  final Map<String, String> _passwords = {}; // email -> password
  AuthAccount? _current;

  @override
  AuthAccount? get currentAccount => _current;

  @override
  Stream<AuthAccount?> authStateChanges() async* {
    // Emit the current state immediately so listeners resolve on startup,
    // then follow subsequent changes.
    yield _current;
    yield* _controller.stream;
  }

  String _uidFor(String email) => 'uid_${email.toLowerCase().hashCode}';

  @override
  Future<AuthAccount> signUp({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final key = email.toLowerCase().trim();
    if (_passwords.containsKey(key)) {
      throw const AuthException('An account with this email already exists.');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }
    _passwords[key] = password;
    _current = AuthAccount(uid: _uidFor(key), email: key);
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<AuthAccount> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final key = email.toLowerCase().trim();
    // For demo convenience, allow signing into any email if it does not exist.
    if (_passwords.containsKey(key) && _passwords[key] != password) {
      throw const AuthException('Incorrect password. Please try again.');
    }
    _passwords[key] ??= password;
    _current = AuthAccount(uid: _uidFor(key), email: key);
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _current = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // No-op in the mock. Real implementation emails a reset link.
  }

  @override
  Future<void> deleteAccount() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final email = _current?.email;
    if (email != null) _passwords.remove(email);
    _current = null;
    _controller.add(null);
  }
}

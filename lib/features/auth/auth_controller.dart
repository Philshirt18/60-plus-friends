import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_user.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/data_repository.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/service_locator.dart';
import '../../core/services/subscription_service.dart';

/// Streams the current authenticated account (or null).
final authAccountProvider = StreamProvider<AuthAccount?>((ref) {
  final auth = ref.watch(authServiceProvider);
  return auth.authStateChanges();
});

/// Convenience: the current uid, or null.
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authAccountProvider).valueOrNull?.uid;
});

/// The signed-in user's profile. Null when signed out OR signed in but has
/// not completed onboarding yet.
///
/// Retries transiently on failure (e.g. a cold-start network hiccup right
/// after a fresh install, before Firestore's local cache is warm) so a
/// flaky first fetch can't be misread as "no profile" and misroute an
/// existing user into onboarding, which would overwrite their real data.
final currentUserProvider =
    FutureProvider<AppUser?>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  final repo = ref.watch(dataRepositoryProvider);

  const delays = [Duration(milliseconds: 300), Duration(milliseconds: 800)];
  for (final delay in delays) {
    try {
      return await repo.getUser(uid);
    } catch (_) {
      await Future.delayed(delay);
    }
  }
  return repo.getUser(uid);
});

/// High-level session status used by the router for redirects.
enum SessionStatus { loading, signedOut, needsOnboarding, ready }

final sessionStatusProvider = Provider<SessionStatus>((ref) {
  final account = ref.watch(authAccountProvider);
  if (account.isLoading) return SessionStatus.loading;
  if (account.valueOrNull == null) return SessionStatus.signedOut;

  final profile = ref.watch(currentUserProvider);
  if (profile.isLoading) return SessionStatus.loading;
  // A fetch error is not the same as "no profile" — don't misroute a
  // signed-in user with a real profile into onboarding just because the
  // network blipped. Stay on the loading/splash state instead.
  if (profile.hasError) return SessionStatus.loading;
  return profile.valueOrNull == null
      ? SessionStatus.needsOnboarding
      : SessionStatus.ready;
});

/// Actions for signing in / up / out and recovery.
class AuthController {
  AuthController(this._ref);
  final Ref _ref;

  AuthService get _auth => _ref.read(authServiceProvider);
  DataRepository get _repo => _ref.read(dataRepositoryProvider);
  NotificationService get _notifications =>
      _ref.read(notificationServiceProvider);
  SubscriptionService get _subscriptions =>
      _ref.read(subscriptionServiceProvider);

  Future<void> _onSignedIn(String uid) async {
    await _notifications.identify(uid);
    // Associate purchases with this account so entitlements follow the user
    // across devices/reinstalls.
    try {
      await _subscriptions.init(appUserId: uid);
    } catch (_) {/* subscription provider not critical to sign-in */}
    // No need to invalidate currentUserProvider here: it already watches
    // currentUidProvider, so it refetches on its own the moment the auth
    // stream reports this uid. Invalidating again after the (sometimes
    // slow, network-bound) subscriptions.init call above forced a second,
    // redundant refetch — during which the router's `loading` state briefly
    // bounced the UI back to the splash screen right after sign-up/sign-in.
  }

  Future<void> signIn(String email, String password) async {
    final account = await _auth.signIn(email: email, password: password);
    await _onSignedIn(account.uid);
  }

  Future<void> signUp(String email, String password) async {
    final account = await _auth.signUp(email: email, password: password);
    await _onSignedIn(account.uid);
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordReset(email);

  Future<void> signOut() async {
    await _notifications.clearIdentity();
    await _auth.signOut();
    _ref.invalidate(currentUserProvider);
  }

  Future<void> deleteAccount() async {
    final uid = _auth.currentAccount?.uid;
    if (uid != null) await _repo.deleteUser(uid);
    await _notifications.clearIdentity();
    await _auth.deleteAccount();
    _ref.invalidate(currentUserProvider);
  }
}

final authControllerProvider = Provider<AuthController>(AuthController.new);

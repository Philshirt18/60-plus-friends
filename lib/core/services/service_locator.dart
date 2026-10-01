import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';
import 'data_repository.dart';
import 'firebase/firebase_auth_service.dart';
import 'firebase/firebase_config.dart';
import 'firebase/firebase_storage_service.dart';
import 'firebase/firestore_data_repository.dart';
import 'notification_service.dart';
import 'revenuecat_config.dart';
import 'revenuecat_subscription_service.dart';
import 'subscription_service.dart';

/// Central place where backend implementations are chosen.
///
/// Each provider prefers the real integration when its credentials/config are
/// present, and otherwise falls back to a mock/in-memory implementation so the
/// app always runs (in tests, or before `flutterfire configure`).
///   - Auth / Data  -> Firebase when initialized, else Mock/InMemory
///   - Subscriptions -> RevenueCat when key set, else Mock
///   - Notifications -> Mock (OneSignal to be added later)

final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseConfig.isAvailable
      ? FirebaseAuthService()
      : MockAuthService();
});

final dataRepositoryProvider = Provider<DataRepository>((ref) {
  return FirebaseConfig.isAvailable
      ? FirestoreDataRepository()
      : InMemoryDataRepository();
});

/// Profile photo storage. Null when Firebase isn't configured (the picker then
/// keeps the local file path, as before).
final storageServiceProvider = Provider<FirebaseStorageService?>((ref) {
  return FirebaseConfig.isAvailable ? FirebaseStorageService() : null;
});

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  // Use the real RevenueCat integration when an API key is configured;
  // otherwise fall back to the mock so the app still runs in development.
  final SubscriptionService service = RevenueCatConfig.isConfigured
      ? RevenueCatSubscriptionService()
      : MockSubscriptionService();
  service.init();
  return service;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = MockNotificationService();
  service.init();
  return service;
});

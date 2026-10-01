import 'dart:io' show Platform;

/// RevenueCat configuration.
///
/// Paste your PUBLIC SDK API keys from the RevenueCat dashboard
/// (Project settings → API keys). The Apple key starts with `appl_`, the
/// Google key with `goog_`. These are safe to ship in the client (they are
/// public SDK keys, not secrets).
///
/// You can also override at build time without editing code:
///   flutter run --dart-define=RC_IOS_KEY=appl_xxx --dart-define=RC_ANDROID_KEY=goog_xxx
class RevenueCatConfig {
  RevenueCatConfig._();

  // Apple App Store production public SDK key (safe to ship in the client).
  static const String _iosKey = String.fromEnvironment(
    'RC_IOS_KEY',
    defaultValue: 'appl_XEMhhkHtxnSgXBCRcCQpdUmdAqt',
  );

  // Android (Google Play) public SDK key — replace with your `goog_...` key
  // when you add an Android app in RevenueCat + Play Console.
  static const String _androidKey = String.fromEnvironment(
    'RC_ANDROID_KEY',
    defaultValue: 'goog_REPLACE_WITH_YOUR_GOOGLE_PUBLIC_KEY',
  );

  /// The offering identifier configured in the RevenueCat dashboard.
  /// `null` uses the current/default offering.
  static const String? offeringId = null;

  /// Returns the platform-appropriate public key.
  static String get apiKey {
    if (Platform.isIOS || Platform.isMacOS) return _iosKey;
    return _androidKey;
  }

  /// Whether a real key has been provided (vs. the placeholder). When false,
  /// the app falls back to the mock subscription service so it still runs.
  static bool get isConfigured =>
      !apiKey.contains('REPLACE_WITH_YOUR');
}

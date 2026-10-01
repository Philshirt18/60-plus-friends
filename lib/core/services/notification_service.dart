/// Kinds of push notifications the product may send. Kept modular and
/// meaningful — the goal is useful re-engagement, never spam.
enum AppNotificationType {
  newMatch,
  newMessage,
  activityJoined,
  activityReminder,
  newMatchingActivity,
}

/// User-controllable notification preferences.
class NotificationPreferences {
  const NotificationPreferences({
    this.newMatch = true,
    this.newMessage = true,
    this.activityJoined = true,
    this.activityReminder = true,
    this.newMatchingActivity = true,
  });

  final bool newMatch;
  final bool newMessage;
  final bool activityJoined;
  final bool activityReminder;
  final bool newMatchingActivity;

  NotificationPreferences copyWith({
    bool? newMatch,
    bool? newMessage,
    bool? activityJoined,
    bool? activityReminder,
    bool? newMatchingActivity,
  }) =>
      NotificationPreferences(
        newMatch: newMatch ?? this.newMatch,
        newMessage: newMessage ?? this.newMessage,
        activityJoined: activityJoined ?? this.activityJoined,
        activityReminder: activityReminder ?? this.activityReminder,
        newMatchingActivity: newMatchingActivity ?? this.newMatchingActivity,
      );
}

/// Abstraction over the push provider.
///
/// The MVP ships a [MockNotificationService]. To integrate OneSignal, add
/// `onesignal_flutter`, implement this interface with a
/// `OneSignalNotificationService` (initialise with your App ID, call
/// `OneSignal.login(externalId)` on sign-in, map [AppNotificationType]s to
/// tags/segments), and register it in the service locator.
abstract class NotificationService {
  Future<void> init();

  /// Associate the device with a signed-in user (OneSignal external id).
  Future<void> identify(String userId);

  /// Ask the OS for notification permission.
  Future<bool> requestPermission();

  /// Push the latest preferences to the provider (as tags/segments).
  Future<void> updatePreferences(NotificationPreferences prefs);

  Future<void> clearIdentity();
}

class MockNotificationService implements NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<void> identify(String userId) async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> updatePreferences(NotificationPreferences prefs) async {}

  @override
  Future<void> clearIdentity() async {}
}

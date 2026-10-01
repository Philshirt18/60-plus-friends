import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/notification_service.dart';
import '../../core/services/service_locator.dart';

/// Combined notification state: whether push is enabled at all (opt-in) plus
/// the per-type preferences.
class NotificationState {
  const NotificationState({
    required this.pushEnabled,
    required this.prefs,
  });

  final bool pushEnabled;
  final NotificationPreferences prefs;

  NotificationState copyWith({
    bool? pushEnabled,
    NotificationPreferences? prefs,
  }) =>
      NotificationState(
        pushEnabled: pushEnabled ?? this.pushEnabled,
        prefs: prefs ?? this.prefs,
      );
}

/// Push notifications are OFF until the user explicitly opts in (GDPR /
/// platform requirement). Only after opt-in do the per-type toggles apply.
class NotificationPrefsController extends StateNotifier<NotificationState> {
  NotificationPrefsController(this._ref)
      : super(const NotificationState(
          pushEnabled: false,
          prefs: NotificationPreferences(),
        )) {
    _restore();
  }

  final Ref _ref;
  static const _prefKey = 'push_enabled';

  NotificationService get _service => _ref.read(notificationServiceProvider);

  Future<void> _restore() async {
    try {
      final store = await SharedPreferences.getInstance();
      final enabled = store.getBool(_prefKey) ?? false;
      if (enabled) state = state.copyWith(pushEnabled: true);
    } catch (_) {
      // Preferences unavailable (e.g. in tests) — keep push disabled.
    }
  }

  /// Explicit opt-in: ask the OS for permission, then persist the choice.
  /// Returns true if push is now enabled.
  Future<bool> enablePush() async {
    final granted = await _service.requestPermission();
    final store = await SharedPreferences.getInstance();
    await store.setBool(_prefKey, granted);
    state = state.copyWith(pushEnabled: granted);
    if (granted) _service.updatePreferences(state.prefs);
    return granted;
  }

  Future<void> disablePush() async {
    final store = await SharedPreferences.getInstance();
    await store.setBool(_prefKey, false);
    state = state.copyWith(pushEnabled: false);
  }

  void _apply(NotificationPreferences prefs) {
    state = state.copyWith(prefs: prefs);
    if (state.pushEnabled) _service.updatePreferences(prefs);
  }

  void setNewMatch(bool v) => _apply(state.prefs.copyWith(newMatch: v));
  void setNewMessage(bool v) => _apply(state.prefs.copyWith(newMessage: v));
  void setActivityJoined(bool v) =>
      _apply(state.prefs.copyWith(activityJoined: v));
  void setActivityReminder(bool v) =>
      _apply(state.prefs.copyWith(activityReminder: v));
  void setNewMatchingActivity(bool v) =>
      _apply(state.prefs.copyWith(newMatchingActivity: v));
}

final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsController, NotificationState>(
  NotificationPrefsController.new,
);

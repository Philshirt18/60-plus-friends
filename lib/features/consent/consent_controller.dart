import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has acknowledged the first-run privacy/consent
/// notice. Persisted so it is only shown once.
class ConsentController extends StateNotifier<bool> {
  ConsentController() : super(true) {
    _restore();
  }

  static const _key = 'privacy_notice_acknowledged';

  /// true while we don't yet know / it still needs to be shown.
  bool get needsNotice => state;

  Future<void> _restore() async {
    try {
      final store = await SharedPreferences.getInstance();
      final acknowledged = store.getBool(_key) ?? false;
      state = !acknowledged;
    } catch (_) {
      // If preferences are unavailable (e.g. in tests), assume acknowledged
      // so we don't block the UI.
      state = false;
    }
  }

  Future<void> acknowledge() async {
    final store = await SharedPreferences.getInstance();
    await store.setBool(_key, true);
    state = false;
  }
}

/// True when the first-run privacy notice still needs to be shown.
final consentNeededProvider =
    StateNotifierProvider<ConsentController, bool>((_) => ConsentController());

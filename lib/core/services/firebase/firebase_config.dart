import 'package:firebase_core/firebase_core.dart';

/// Tracks whether Firebase has been initialized this session. The app falls
/// back to the in-memory/mock backend when Firebase is not configured, so it
/// still runs (e.g. before `flutterfire configure` has been run, or in tests).
class FirebaseConfig {
  FirebaseConfig._();

  static bool get isAvailable => Firebase.apps.isNotEmpty;
}

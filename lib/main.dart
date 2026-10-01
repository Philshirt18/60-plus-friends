import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase with the generated platform options. Guarded so the
  // app still launches (on the in-memory/mock backend) if initialisation
  // fails for any reason.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Not available — the service locator falls back to mock/in-memory.
  }

  // RevenueCat is configured lazily by `subscriptionServiceProvider` and then
  // associated to the account on sign-in via AuthController.

  runApp(const ProviderScope(child: SixtyPlusApp()));
}

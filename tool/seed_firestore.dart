// One-off tool to upload the demo seed people & activities into Firestore.
//
// Run from the project root on a device/simulator target:
//   flutter run -d <device> -t tool/seed_firestore.dart
//
// It writes to the same project configured in lib/firebase_options.dart.
// Safe to run more than once (uses deterministic seed_* document ids).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:sixty_plus_friends/core/services/seed_data.dart';
import 'package:sixty_plus_friends/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // The security rules require a signed-in user. Sign in (or create) a
  // throwaway seeding account so the temporary seed_* rules apply.
  const seedEmail = 'seed-admin@sixtyplusfriends.app';
  const seedPassword = 'SeedAdmin!2026';
  final auth = FirebaseAuth.instance;
  try {
    await auth.signInWithEmailAndPassword(
        email: seedEmail, password: seedPassword);
  } catch (_) {
    await auth.createUserWithEmailAndPassword(
        email: seedEmail, password: seedPassword);
  }
  // ignore: avoid_print
  print('signed in as seeding account: ${auth.currentUser?.uid}');

  final db = FirebaseFirestore.instance;

  // People.
  for (final u in SeedData.people()) {
    await db.collection('users').doc(u.id).set(u.toMap());
    // ignore: avoid_print
    print('seeded user ${u.id}');
  }

  // Activities.
  for (final a in SeedData.activities()) {
    await db.collection('activities').doc(a.id).set({
      'creatorId': a.creatorId,
      'title': a.title,
      'description': a.description,
      'category': a.category,
      'dateTime': Timestamp.fromDate(a.dateTime),
      'approximateLocation': a.approximateLocation,
      'maxParticipants': a.maxParticipants,
      'interestIds': a.interestIds,
      'participantIds': a.participantIds,
      'createdAt': FieldValue.serverTimestamp(),
      'photoUrl': a.photoUrl,
    });
    // ignore: avoid_print
    print('seeded activity ${a.id}');
  }

  // ignore: avoid_print
  print('DONE seeding Firestore.');
  runApp(const _Done());
}

class _Done extends StatelessWidget {
  const _Done();
  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Seeding complete. You can close this.',
                textAlign: TextAlign.center),
          ),
        ),
      );
}

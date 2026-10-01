import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Uploads profile photos to Firebase Storage and returns a download URL.
class FirebaseStorageService {
  FirebaseStorageService([FirebaseStorage? storage])
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads the local file at [localPath] as the profile photo for [userId].
  /// Returns the public download URL to store on the user's profile.
  Future<String> uploadProfilePhoto({
    required String userId,
    required String localPath,
  }) async {
    final ref = _storage.ref('profile_photos/$userId.jpg');
    final task = await ref.putFile(
      File(localPath),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }

  /// Uploads the local file at [localPath] as the photo for the activity
  /// [activityId]. Returns the public download URL to store on the activity.
  Future<String> uploadActivityPhoto({
    required String activityId,
    required String localPath,
  }) async {
    final ref = _storage.ref('activity_photos/$activityId/photo.jpg');
    final task = await ref.putFile(
      File(localPath),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }
}

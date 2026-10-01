import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_user.dart';
import '../../core/services/service_locator.dart';
import '../auth/auth_controller.dart';

/// Uploads a locally-picked photo (`file://...`) to storage when available,
/// returning the persisted download URL. Leaves already-remote or asset
/// references untouched, and gracefully falls back to the local path if there
/// is no storage backend (in-memory/dev mode).
Future<String?> resolveProfilePhoto(
  Ref ref, {
  required String userId,
  required String? photoRef,
}) async {
  if (photoRef == null || !photoRef.startsWith('file://')) return photoRef;
  final storage = ref.read(storageServiceProvider);
  if (storage == null) return photoRef; // dev/mock: keep local path
  try {
    return await storage.uploadProfilePhoto(
      userId: userId,
      localPath: photoRef.substring('file://'.length),
    );
  } catch (_) {
    return photoRef; // upload failed — keep local path rather than lose it
  }
}

class ProfileController {
  ProfileController(this._ref);
  final Ref _ref;

  Future<void> save(AppUser updated) async {
    final photo = await resolveProfilePhoto(
      _ref,
      userId: updated.id,
      photoRef: updated.profilePhotoUrl,
    );
    await _ref
        .read(dataRepositoryProvider)
        .saveUser(updated.copyWith(profilePhotoUrl: photo));
    _ref.invalidate(currentUserProvider);
  }

  Future<void> setHideExactLocation(bool value) async {
    final me = _ref.read(currentUserProvider).valueOrNull;
    if (me == null) return;
    await save(me.copyWith(hideExactLocation: value));
  }
}

final profileControllerProvider =
    Provider<ProfileController>(ProfileController.new);

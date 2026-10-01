import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Lets the user pick a profile photo from the camera or gallery.
///
/// Returns a `file://` reference to the picked image, or null if cancelled.
/// The image is downscaled for a reasonable profile-photo size.
///
/// NOTE: with a real backend you would upload the picked file to storage
/// (e.g. Firebase Storage) and persist the returned download URL instead of
/// the local file path. The display layer already supports both.
class PhotoPicker {
  PhotoPicker._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: Text('Add a photo',
                  style: Theme.of(ctx).textTheme.titleLarge),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primary, size: 28),
              title: const Text('Take a photo',
                  style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary, size: 28),
              title: const Text('Choose from library',
                  style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (source == null) return null;

    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file == null) return null;
      return 'file://${file.path}';
    } catch (_) {
      return null;
    }
  }
}

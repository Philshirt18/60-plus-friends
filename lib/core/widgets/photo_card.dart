import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/image_source.dart';

/// A large rectangular photo — the same "card" style used for people and
/// activities in Discover — with a gradient + initial/icon fallback when
/// there is no photo yet.
///
/// Pass [onEdit] to turn it into a tappable picker with a camera button
/// overlay (used when adding/changing a photo, e.g. profile or activity
/// creation).
class PhotoCard extends StatelessWidget {
  const PhotoCard({
    super.key,
    this.photoUrl,
    this.height = 260,
    this.fallbackLabel,
    this.fallbackIcon = Icons.image_outlined,
    this.onEdit,
    this.editLabel = 'Add photo',
  });

  final String? photoUrl;
  final double height;

  /// Shown as a big initial (e.g. a person's first letter) when there is no
  /// photo. Takes precedence over [fallbackIcon] when non-empty.
  final String? fallbackLabel;
  final IconData fallbackIcon;

  final VoidCallback? onEdit;
  final String editLabel;

  @override
  Widget build(BuildContext context) {
    final photo = imageProviderFor(photoUrl);
    final radius = BorderRadius.circular(AppSpacing.cardRadius);

    final content = ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo != null)
              Image(image: photo, fit: BoxFit.cover)
            else
              _Fallback(label: fallbackLabel, icon: fallbackIcon),
            if (onEdit != null)
              Positioned(
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: _EditButton(label: editLabel, onTap: onEdit!),
              ),
          ],
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
      ),
      child: onEdit == null
          ? content
          : InkWell(borderRadius: radius, onTap: onEdit, child: content),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.label, required this.icon});
  final String? label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final hasLabel = label != null && label!.isNotEmpty;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.accentLight],
        ),
      ),
      alignment: Alignment.center,
      child: hasLabel
          ? Text(
              label![0].toUpperCase(),
              style: const TextStyle(
                fontSize: 84,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            )
          : Icon(icon, size: 64, color: AppColors.primary),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

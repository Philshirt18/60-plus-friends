import 'package:flutter/material.dart';

/// The app's icon mark — the user-provided artwork (three friends standing
/// together), used exactly as designed rather than redrawn.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64, this.rounded = true});

  final double size;

  /// Whether to clip to the squircle app-icon shape. Set false when the
  /// mark is already placed inside its own rounded container.
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final content = Image.asset(
      'assets/images/brand_mark.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );

    if (!rounded) return content;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: content,
    );
  }
}

/// The full lockup — the mark with the "60+ Friends" wordmark baked in, as
/// provided. Best for large, uncramped surfaces (splash screen, marketing);
/// prefer [BrandMark] at small sizes where the text would blur.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.size = 160, this.rounded = true});

  final double size;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final content = Image.asset(
      'assets/images/brand_lockup.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );

    if (!rounded) return content;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: content,
    );
  }
}

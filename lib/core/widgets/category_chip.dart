import 'package:flutter/material.dart';

import '../models/interest.dart';
import '../theme/app_colors.dart';

/// A colourful interest pill tinted by its category, with the interest icon.
/// Falls back to the primary tint for non-interest labels.
class CategoryChip extends StatelessWidget {
  const CategoryChip.interest(this.interestId, {super.key})
      : label = null,
        background = null,
        foreground = null,
        icon = null;

  /// A generic tinted chip (used for "looking for" and free-form labels).
  const CategoryChip.custom({
    super.key,
    required this.label,
    this.icon,
    this.background,
    this.foreground,
  }) : interestId = null;

  final String? interestId;
  final String? label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final resolvedLabel =
        label ?? (interestId != null ? InterestCatalog.nameOf(interestId!) : '');
    final category =
        interestId != null ? InterestCatalog.categoryOf(interestId!) : null;
    final resolvedIcon =
        icon ?? (interestId != null ? InterestCatalog.iconOf(interestId!) : null);
    final bg = background ?? category?.background ?? AppColors.primaryLight;
    final fg = foreground ?? category?.foreground ?? AppColors.primaryDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (resolvedIcon != null) ...[
            Icon(resolvedIcon, size: 18, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            resolvedLabel,
            style: TextStyle(
              color: fg,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

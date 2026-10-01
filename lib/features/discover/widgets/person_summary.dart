import 'package:flutter/material.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/interest.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/category_chip.dart';

/// A labelled group of interest/preference pills used across person cards.
class LabeledChips extends StatelessWidget {
  const LabeledChips({
    super.key,
    required this.label,
    required this.values,
    this.icon,
    this.highlight = false,
    this.interestIds,
  });

  /// Colourful, category-tinted interest chips.
  const LabeledChips.interests({
    super.key,
    required this.label,
    required List<String> ids,
    this.icon,
  })  : interestIds = ids,
        values = const [],
        highlight = false;

  final String label;
  final List<String> values;
  final IconData? icon;
  final bool highlight;

  /// When set, render colourful category chips instead of [values].
  final List<String>? interestIds;

  @override
  Widget build(BuildContext context) {
    final useCategory = interestIds != null;
    if (!useCategory && values.isEmpty) return const SizedBox.shrink();
    if (useCategory && interestIds!.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.inkSoft),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: useCategory
              ? interestIds!
                  .map((id) => CategoryChip.interest(id))
                  .toList()
              : values
                  .map((v) => CategoryChip.custom(
                        label: v,
                        background: highlight
                            ? AppColors.accentLight
                            : AppColors.primaryLight,
                        foreground: highlight
                            ? AppColors.accent
                            : AppColors.primaryDark,
                      ))
                  .toList(),
        ),
      ],
    );
  }
}

/// Shared interest names between me and another user (for match messaging).
List<String> sharedInterestNames(AppUser me, AppUser other) {
  return me.interests
      .where(other.interests.contains)
      .map(InterestCatalog.nameOf)
      .toList();
}

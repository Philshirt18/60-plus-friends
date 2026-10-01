import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A pill chip used to display an interest or preference.
class InterestChip extends StatelessWidget {
  const InterestChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary : AppColors.primaryLight;
    final fg = selected ? Colors.white : AppColors.primaryDark;

    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: selected ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 18 : 20, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (selected && onTap != null) ...[
            const SizedBox(width: 6),
            Icon(Icons.check, size: compact ? 16 : 18, color: fg),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: content,
      ),
    );
  }
}

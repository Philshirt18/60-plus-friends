import 'package:flutter/material.dart';

import '../../../core/models/activity.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/utils/image_source.dart';
import '../../../core/widgets/category_chip.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    this.joined = false,
  });

  final Activity activity;
  final VoidCallback onTap;
  final bool joined;

  @override
  Widget build(BuildContext context) {
    final photo = imageProviderFor(activity.photoUrl);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(activity: activity, photo: photo),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(activity.title,
                            style: Theme.of(context).textTheme.titleLarge),
                      ),
                      if (joined)
                        const Icon(Icons.check_circle,
                            color: AppColors.success),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _iconRow(Icons.schedule,
                      Formatting.activityWhenShort(activity.dateTime)),
                  const SizedBox(height: 6),
                  _iconRow(
                    Icons.place_outlined,
                    (activity.approxDistanceKm != null &&
                            activity.approxDistanceKm! > 0)
                        ? '${activity.approxDistanceKm!.round()} km away'
                        : activity.approximateLocation,
                  ),
                  const SizedBox(height: 6),
                  _iconRow(
                    Icons.people_outline,
                    '${activity.interestedCount} of ${activity.maxParticipants} people',
                  ),
                  if (activity.interestIds.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: activity.interestIds
                          .take(3)
                          .map((id) => CategoryChip.interest(id))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.inkSoft),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 16, color: AppColors.inkSoft)),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.activity, required this.photo});
  final Activity activity;
  final ImageProvider? photo;

  @override
  Widget build(BuildContext context) {
    final dateBadge = activity.isToday()
        ? 'Today'
        : (activity.isThisWeek() ? 'This week' : null);

    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo != null)
            Image(image: photo!, fit: BoxFit.cover)
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryLight, AppColors.accentLight],
                ),
              ),
              child: Center(
                child: Icon(Icons.event, size: 48, color: AppColors.primary),
              ),
            ),
          if (dateBadge != null)
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: _Pill(
                icon: Icons.calendar_today,
                label: dateBadge,
                iconColor: AppColors.creativeFg,
              ),
            ),
          if (activity.approxDistanceKm != null)
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: _Pill(
                icon: Icons.place,
                label: '${activity.approxDistanceKm!.round()} km',
                iconColor: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.iconColor,
  });
  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
        ],
      ),
    );
  }
}

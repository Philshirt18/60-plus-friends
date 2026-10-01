import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/activity.dart';
import '../../core/models/interest.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/interest_chip.dart';
import '../../core/widgets/photo_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_controller.dart';
import '../messages/messages_controller.dart';
import 'activities_controller.dart';

class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key, required this.activityId});
  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    final activityAsync = ref.watch(activityByIdProvider(activityId));

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: SafeArea(
        child: activityAsync.when(
          loading: () => const LoadingView(),
          error: (_, __) =>
              const ErrorView(message: 'Could not load this activity.'),
          data: (activity) {
            if (activity == null) {
              return const ErrorView(message: 'This activity is no longer available.');
            }
            final joined = me != null && activity.hasJoined(me.id);
            final isCreator = me != null && activity.creatorId == me.id;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (activity.photoUrl != null) ...[
                          PhotoCard(
                            photoUrl: activity.photoUrl,
                            fallbackIcon: Icons.image_outlined,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        Text(activity.title,
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: AppSpacing.md),
                        _InfoRow(
                            icon: Icons.schedule,
                            text: Formatting.activityWhenShort(
                                activity.dateTime)),
                        const SizedBox(height: AppSpacing.sm),
                        _InfoRow(
                            icon: Icons.place_outlined,
                            text: (activity.approxDistanceKm != null &&
                                    activity.approxDistanceKm! > 0)
                                ? '${activity.approxDistanceKm!.round()} km away'
                                : activity.approximateLocation),
                        const SizedBox(height: AppSpacing.sm),
                        _InfoRow(
                          icon: Icons.people_outline,
                          text:
                              '${activity.interestedCount} of ${activity.maxParticipants} interested',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (activity.interestIds.isNotEmpty) ...[
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: activity.interestIds
                                .map((id) => InterestChip(
                                      label: InterestCatalog.nameOf(id),
                                      icon: InterestCatalog.iconOf(id),
                                      compact: true,
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        Text('About',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.sm),
                        Text(activity.description,
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Who\'s coming',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.sm),
                        _Participants(participantIds: activity.participantIds),
                      ],
                    ),
                  ),
                ),
                _ActionBar(
                  activity: activity,
                  joined: joined,
                  isCreator: isCreator,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 18, color: AppColors.ink)),
        ),
      ],
    );
  }
}

class _Participants extends ConsumerWidget {
  const _Participants({required this.participantIds});
  final List<String> participantIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (participantIds.isEmpty) {
      return const Text('Be the first to join.',
          style: TextStyle(fontSize: 17, color: AppColors.inkSoft));
    }
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: participantIds.map((id) {
        final person = ref.watch(userByIdProvider(id)).valueOrNull;
        return Column(
          children: [
            ProfileAvatar(
              name: person?.firstName ?? '?',
              photoUrl: person?.profilePhotoUrl,
              radius: 28,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                person?.firstName ?? '...',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _ActionBar extends ConsumerStatefulWidget {
  const _ActionBar({
    required this.activity,
    required this.joined,
    required this.isCreator,
  });
  final Activity activity;
  final bool joined;
  final bool isCreator;

  @override
  ConsumerState<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends ConsumerState<_ActionBar> {
  bool _busy = false;

  Future<void> _toggle() async {
    setState(() => _busy = true);
    final ctrl = ref.read(activitiesControllerProvider);
    if (widget.joined) {
      await ctrl.leave(widget.activity.id);
    } else {
      await ctrl.join(widget.activity.id);
    }
    ref.invalidate(activityByIdProvider(widget.activity.id));
    if (mounted) setState(() => _busy = false);
  }

  void _edit() {
    context.push('/activities/edit', extra: widget.activity);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this activity?'),
        content: const Text(
            'This cannot be undone. Everyone who joined will no longer see it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    await ref.read(activitiesControllerProvider).delete(widget.activity.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: widget.isCreator
            ? Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Edit',
                      icon: Icons.edit_outlined,
                      onPressed: _busy ? null : _edit,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Delete',
                      icon: Icons.delete_outline,
                      foregroundColor: AppColors.danger,
                      onPressed: _busy ? null : _delete,
                    ),
                  ),
                ],
              )
            : (widget.joined
                ? SecondaryButton(
                    label: "Leave activity",
                    icon: Icons.logout,
                    foregroundColor: AppColors.danger,
                    onPressed: _busy ? null : _toggle,
                  )
                : PrimaryButton(
                    label: activity.isFull
                        ? 'This activity is full'
                        : 'Join activity',
                    icon: Icons.add,
                    loading: _busy,
                    onPressed:
                        activity.isFull ? null : _toggle,
                  )),
      ),
    );
  }
}

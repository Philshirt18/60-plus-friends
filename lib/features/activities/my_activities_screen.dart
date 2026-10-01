import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_controller.dart';
import 'activities_controller.dart';
import 'widgets/activity_card.dart';

class MyActivitiesScreen extends ConsumerWidget {
  const MyActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    final mineAsync = ref.watch(myActivitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My activities')),
      body: SafeArea(
        child: mineAsync.when(
          loading: () => const LoadingView(),
          error: (_, __) => ErrorView(
            message: 'We could not load your activities.',
            onRetry: () => ref.invalidate(myActivitiesProvider),
          ),
          data: (activities) {
            if (activities.isEmpty) {
              return EmptyState(
                icon: Icons.event_note_outlined,
                title: 'No activities yet',
                message: 'Join an activity nearby or create your own to bring '
                    'people together.',
                actionLabel: 'Create an activity',
                onAction: () => context.push('/activities/create'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: activities.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) {
                final a = activities[i];
                return ActivityCard(
                  activity: a,
                  joined: me != null && a.creatorId != me.id,
                  onTap: () => context.push('/activities/detail', extra: a),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

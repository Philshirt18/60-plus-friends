import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_controller.dart';
import 'activities_controller.dart';
import 'widgets/activity_card.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    final filter = ref.watch(activityFilterProvider);
    final activitiesAsync = ref.watch(filteredActivitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_available_outlined),
            tooltip: 'My activities',
            onPressed: () => context.push('/activities/mine'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/activities/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (me != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                child: Row(
                  children: [
                    const Icon(Icons.place,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        me.approximateArea.isEmpty
                            ? 'Activities near you'
                            : 'Activities near ${me.approximateArea}',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSoft),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                children: ActivityFilter.values.map((f) {
                  final selected = f == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(f.label,
                          style: const TextStyle(fontSize: 16)),
                      selected: selected,
                      onSelected: (_) => ref
                          .read(activityFilterProvider.notifier)
                          .state = f,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: AppColors.primaryLight,
                      side: BorderSide.none,
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: activitiesAsync.when(
                loading: () => const LoadingView(),
                error: (_, __) => ErrorView(
                  message: 'We could not load activities.',
                  onRetry: () => ref.invalidate(allActivitiesProvider),
                ),
                data: (activities) {
                  if (activities.isEmpty) {
                    return EmptyState(
                      icon: Icons.event_busy_outlined,
                      title: 'Nothing planned nearby yet',
                      message: 'Why not create the first activity? A short '
                          'walk or a coffee is a lovely way to meet people.',
                      actionLabel: 'Create an activity',
                      onAction: () => context.push('/activities/create'),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(allActivitiesProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: activities.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, i) {
                        final a = activities[i];
                        final joined =
                            me != null && a.hasJoined(me.id);
                        return ActivityCard(
                          activity: a,
                          joined: joined,
                          onTap: () =>
                              context.push('/activities/detail', extra: a),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

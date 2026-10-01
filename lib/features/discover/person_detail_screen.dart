import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_controller.dart';
import 'widgets/person_summary.dart';

class PersonDetailScreen extends ConsumerWidget {
  const PersonDetailScreen({super.key, required this.person});
  final AppUser person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    final shared = me != null ? sharedInterestNames(me, person) : <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(person.firstName),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Report',
            onPressed: () =>
                context.push('/report', extra: person),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    ProfileAvatar(
                      name: person.firstName,
                      photoUrl: person.profilePhotoUrl,
                      radius: 64,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(person.firstName,
                        style: Theme.of(context).textTheme.displaySmall),
                    Text('${person.ageLabel} years',
                        style: const TextStyle(
                            fontSize: 18, color: AppColors.inkSoft)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 18, color: AppColors.inkSoft),
                        const SizedBox(width: 4),
                        Text(
                          person.approxDistanceKm != null
                              ? '${person.approxDistanceKm!.round()} km from you'
                              : 'Nearby',
                          style: const TextStyle(
                              fontSize: 16, color: AppColors.inkSoft),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (person.bio.isNotEmpty) ...[
                Text('About', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(person.bio,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (shared.isNotEmpty) ...[
                LabeledChips(
                  label: 'SHARED INTERESTS',
                  icon: Icons.favorite_border,
                  values: shared,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              LabeledChips.interests(
                label: 'INTERESTS',
                icon: Icons.interests,
                ids: person.interests,
              ),
              const SizedBox(height: AppSpacing.lg),
              LabeledChips(
                label: 'LOOKING FOR',
                icon: Icons.handshake_outlined,
                values: person.lookingFor.map((e) => e.label).toList(),
                highlight: true,
              ),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: () => _confirmBlock(context, ref),
                icon: const Icon(Icons.block),
                label: Text('Block ${person.firstName}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger, width: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmBlock(BuildContext context, WidgetRef ref) {
    context.push('/block', extra: person);
  }
}

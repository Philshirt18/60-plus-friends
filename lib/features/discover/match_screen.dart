import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_user.dart';
import '../../core/models/interest.dart';
import '../../core/models/social_models.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_controller.dart';

/// A warm, friendship-focused connection screen. No romantic language,
/// no hearts, no "It's a match!".
class MatchScreen extends ConsumerWidget {
  const MatchScreen({super.key, required this.match, required this.person});
  final Match match;
  final AppUser person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    final sharedNames = match.sharedInterestIds.isNotEmpty
        ? match.sharedInterestIds.map(InterestCatalog.nameOf).toList()
        : (me != null
            ? me.interests
                .where(person.interests.contains)
                .map(InterestCatalog.nameOf)
                .toList()
            : <String>[]);

    final sharedText = _sharedSentence(person.firstName, sharedNames);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.diversity_1, size: 72, color: Colors.white),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'You found a connection!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ProfileAvatar(
                    name: me?.firstName ?? 'You',
                    photoUrl: me?.profilePhotoUrl,
                    radius: 44,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Icon(Icons.add, color: Colors.white70, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  ProfileAvatar(
                    name: person.firstName,
                    photoUrl: person.profilePhotoUrl,
                    radius: 44,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                sharedText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Send a message',
                icon: Icons.chat_bubble_outline,
                onPressed: () => _openConversation(context, ref, me),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Keep discovering',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sharedSentence(String name, List<String> shared) {
    if (shared.isEmpty) {
      return 'You and $name would love to meet new people nearby.';
    }
    if (shared.length == 1) {
      return 'You and $name both enjoy ${shared.first.toLowerCase()}.';
    }
    final first = shared.take(2).map((s) => s.toLowerCase()).toList();
    return 'You and $name both enjoy ${first[0]} and ${first[1]}.';
  }

  Future<void> _openConversation(
      BuildContext context, WidgetRef ref, AppUser? me) async {
    if (me == null) return;
    final repo = ref.read(dataRepositoryProvider);
    final convo = await repo.conversationForMatch(match, me.id);
    if (!context.mounted) return;
    context.pushReplacement('/conversation', extra: {
      'conversationId': convo.id,
      'person': person,
    });
  }
}

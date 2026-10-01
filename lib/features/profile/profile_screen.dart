import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/photo_card.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_controller.dart';
import '../discover/widgets/person_summary.dart';
import '../premium/premium_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    final isPremium = ref.watch(isPremiumProvider);

    if (me == null) {
      return const Scaffold(body: LoadingView());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: Column(
                children: [
                  PhotoCard(
                    photoUrl: me.profilePhotoUrl,
                    fallbackLabel: me.firstName,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(me.firstName,
                      style: Theme.of(context).textTheme.displaySmall),
                  Text('${me.ageLabel} years',
                      style: const TextStyle(
                          fontSize: 18, color: AppColors.inkSoft)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 18, color: AppColors.inkSoft),
                      const SizedBox(width: 4),
                      Text('${me.approximateArea}, ${me.city}',
                          style: const TextStyle(
                              fontSize: 16, color: AppColors.inkSoft)),
                    ],
                  ),
                  if (isPremium) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium,
                              size: 18, color: AppColors.accent),
                          SizedBox(width: 6),
                          Text('Premium member',
                              style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => context.push('/profile/edit'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit profile'),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (me.bio.isNotEmpty) ...[
              Text('About', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(me.bio, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.lg),
            ],
            LabeledChips.interests(
              label: 'INTERESTS',
              icon: Icons.interests,
              ids: me.interests,
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledChips(
              label: 'LOOKING FOR',
              icon: Icons.handshake_outlined,
              values: me.lookingFor.map((e) => e.label).toList(),
              highlight: true,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (!isPremium)
              _PremiumBanner(onTap: () => context.push('/premium')),
            const SizedBox(height: AppSpacing.md),
            _ProfileLink(
              icon: Icons.person_add_alt_1_outlined,
              label: 'Invite someone',
              onTap: () => context.push('/invite'),
            ),
            _ProfileLink(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium,
                color: AppColors.accent, size: 32),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Try Premium',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Text(
                    'See who is interested, widen your search and more.',
                    style: TextStyle(fontSize: 15, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontSize: 18)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

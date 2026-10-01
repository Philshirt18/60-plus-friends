import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_controller.dart';
import '../profile/profile_controller.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    if (me == null) return const Scaffold(body: LoadingView());

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const _PrivacyIntro(),
            const SizedBox(height: AppSpacing.lg),
            SwitchListTile(
              value: me.hideExactLocation,
              onChanged: (v) =>
                  ref.read(profileControllerProvider).setHideExactLocation(v),
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              title: const Text('Hide my exact location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              subtitle: const Text(
                'Only your city and approximate area are ever shown. Recommended on.',
                style: TextStyle(fontSize: 16, color: AppColors.inkSoft),
              ),
            ),
            const Divider(height: AppSpacing.xl),
            _WhatWeShow(),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => context.push('/privacy-policy'),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Read our privacy policy'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyIntro extends StatelessWidget {
  const _PrivacyIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user, color: AppColors.primary, size: 32),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Your privacy comes first. We only store what the app needs to '
              'help you meet people nearby.',
              style: TextStyle(fontSize: 16, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatWeShow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const shown = [
      'Your first name',
      'Your age range',
      'Your city and approximate area',
      'Your interests and what you are looking for',
      'Your short introduction and photo',
    ];
    const hidden = [
      'Your exact address',
      'Your precise, real-time location',
      'Your email address',
      'Your phone number',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What others can see',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        ...shown.map((s) => _row(Icons.check_circle, AppColors.success, s)),
        const SizedBox(height: AppSpacing.md),
        Text('Never shared', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        ...hidden.map((s) => _row(Icons.remove_circle, AppColors.inkFaint, s)),
      ],
    );
  }

  Widget _row(IconData icon, Color color, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: Text(text, style: const TextStyle(fontSize: 17))),
          ],
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../auth/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          children: [
            _sectionHeader(context, 'Account'),
            _tile(
              context,
              icon: Icons.person_outline,
              label: 'Edit profile',
              onTap: () => context.push('/profile/edit'),
            ),
            _tile(
              context,
              icon: Icons.workspace_premium_outlined,
              label: 'Premium',
              onTap: () => context.push('/premium'),
            ),
            _sectionHeader(context, 'Privacy & safety'),
            _tile(
              context,
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy',
              onTap: () => context.push('/privacy'),
            ),
            _tile(
              context,
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () => context.push('/notifications-settings'),
            ),
            _tile(
              context,
              icon: Icons.shield_outlined,
              label: 'Community guidelines',
              onTap: () => context.push('/guidelines'),
            ),
            _tile(
              context,
              icon: Icons.description_outlined,
              label: 'Terms of service',
              onTap: () => context.push('/terms'),
            ),
            _tile(
              context,
              icon: Icons.lock_outline,
              label: 'Privacy policy',
              onTap: () => context.push('/privacy-policy'),
            ),
            _sectionHeader(context, 'Community'),
            _tile(
              context,
              icon: Icons.person_add_alt_1_outlined,
              label: 'Invite someone',
              onTap: () => context.push('/invite'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: OutlinedButton.icon(
                onPressed: () => _confirmSignOut(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextButton(
                onPressed: () => _confirmDelete(context, ref),
                child: const Text(
                  'Delete my account',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.inkFaint,
                letterSpacing: 0.5)),
      );

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in at any time.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider).signOut();
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently removes your profile, matches and messages. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider).deleteAccount();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/primary_button.dart';

/// A first-run privacy notice presented as a non-dismissible bottom sheet.
/// Summarises what data is used and links to the full policy, satisfying
/// GDPR transparency at first use. Returns when the user acknowledges.
Future<void> showPrivacyNotice(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => PopScope(
      canPop: false,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user,
                      size: 40, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text('Your privacy',
                    style: Theme.of(ctx).textTheme.headlineSmall),
              ),
              const SizedBox(height: AppSpacing.md),
              const _Point(
                icon: Icons.place_outlined,
                text:
                    'We only use your city and approximate area to show people '
                    'and activities nearby — never your exact address or '
                    'real-time location.',
              ),
              const _Point(
                icon: Icons.visibility_off_outlined,
                text:
                    'Your email is never shown to other members. You control '
                    'what appears on your profile.',
              ),
              const _Point(
                icon: Icons.tune,
                text:
                    'Push notifications are off until you turn them on, and '
                    'you can delete your account and data at any time.',
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                children: [
                  _Link(
                      label: 'Privacy Policy',
                      onTap: () => ctx.push('/privacy-policy')),
                  _Link(label: 'Terms', onTap: () => ctx.push('/terms')),
                  _Link(
                      label: 'Guidelines',
                      onTap: () => ctx.push('/guidelines')),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Got it',
                icon: Icons.check,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text(
                  'Data controller: ${AppInfo.companyName}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.inkFaint),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 16, height: 1.4, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label,
          style: const TextStyle(
              fontSize: 15,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline)),
    );
  }
}

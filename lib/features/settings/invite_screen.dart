import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/primary_button.dart';
import '../auth/auth_controller.dart';

class InviteScreen extends ConsumerWidget {
  const InviteScreen({super.key});

  static const _inviteLink = 'https://sixtyplusfriends.app/invite';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    final area = me?.approximateArea ?? 'your area';

    final message =
        'Come and join me on 60+ Friends — a friendly community to meet '
        'people nearby in $area and do activities together. $_inviteLink';

    return Scaffold(
      appBar: AppBar(title: const Text('Invite someone')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.group_add,
                      size: 56, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('The more, the merrier',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Know someone who would enjoy meeting new people nearby? '
                'Invite them along. The community grows one friendly '
                'introduction at a time.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: AppColors.inkSoft),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: AppColors.inkSoft),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(_inviteLink,
                          style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Share invitation',
                icon: Icons.share,
                onPressed: () => Share.share(message),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

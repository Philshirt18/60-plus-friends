import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/primary_button.dart';
import '../messages/messages_controller.dart';

class BlockUserScreen extends ConsumerStatefulWidget {
  const BlockUserScreen({super.key, required this.person});
  final AppUser person;

  @override
  ConsumerState<BlockUserScreen> createState() => _BlockUserScreenState();
}

class _BlockUserScreenState extends ConsumerState<BlockUserScreen> {
  bool _busy = false;

  Future<void> _block() async {
    setState(() => _busy = true);
    await ref.read(messagesControllerProvider).block(widget.person.id);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.person.firstName} has been blocked.')),
    );
    // Return to the tab root.
    context.go('/matches');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Block')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              const Center(
                child: Icon(Icons.block, size: 64, color: AppColors.danger),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Block ${widget.person.firstName}?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${widget.person.firstName} will no longer appear in Discover, '
                'and you will not see each other or be able to message. They '
                'are not told that you blocked them.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, color: AppColors.inkSoft),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Block ${widget.person.firstName}',
                loading: _busy,
                onPressed: _block,
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: 'Cancel',
                foregroundColor: AppColors.inkSoft,
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

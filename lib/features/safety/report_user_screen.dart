import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/app_user.dart';
import '../../core/models/social_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/primary_button.dart';
import '../auth/auth_controller.dart';
import '../messages/messages_controller.dart';

class ReportUserScreen extends ConsumerStatefulWidget {
  const ReportUserScreen({super.key, required this.person});
  final AppUser person;

  @override
  ConsumerState<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends ConsumerState<ReportUserScreen> {
  static const _reasons = [
    'Inappropriate messages',
    'Fake profile',
    'Harassment or bullying',
    'Asking for money',
    'Something else',
  ];

  String? _reason;
  final _details = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) return;
    final me = ref.read(currentUserProvider).valueOrNull;
    if (me == null) return;

    setState(() => _submitting = true);
    await ref.read(messagesControllerProvider).report(
          Report(
            id: const Uuid().v4(),
            reporterId: me.id,
            reportedUserId: widget.person.id,
            reason: _reason!,
            details: _details.text.trim(),
            createdAt: DateTime.now(),
          ),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Thank you. Our team will review this report. You can also block this person.'),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report ${widget.person.firstName}')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Reports are confidential. Let us know what happened so we can '
                'keep the community safe and welcoming.',
                style: TextStyle(fontSize: 17, color: AppColors.inkSoft),
              ),
              const SizedBox(height: AppSpacing.lg),
              RadioGroup<String>(
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                child: Column(
                  children: _reasons
                      .map((r) => RadioListTile<String>(
                            value: r,
                            title:
                                Text(r, style: const TextStyle(fontSize: 18)),
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.primary,
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _details,
                maxLines: 4,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Anything else? (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Submit report',
                loading: _submitting,
                onPressed: _reason == null ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'notifications_controller.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationPrefsProvider);
    final ctrl = ref.read(notificationPrefsProvider.notifier);
    final prefs = state.prefs;
    final on = state.pushEnabled;

    Future<void> toggleMaster(bool value) async {
      if (value) {
        final granted = await ctrl.enablePush();
        if (!granted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Notifications are turned off in your device settings. '
                  'You can enable them there any time.'),
            ),
          );
        }
      } else {
        await ctrl.disablePush();
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: on ? AppColors.primaryLight : AppColors.background,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: on,
                    onChanged: toggleMaster,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Push notifications',
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      on
                          ? 'You will receive the notifications you choose below.'
                          : 'Turn on to receive helpful updates. You choose '
                              'exactly what, and can turn them off any time.',
                      style: const TextStyle(
                          fontSize: 16, color: AppColors.inkSoft),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('What you would like to hear about',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'We only send useful, occasional notifications — never spam.',
              style: TextStyle(fontSize: 15, color: AppColors.inkSoft),
            ),
            const SizedBox(height: AppSpacing.sm),
            Opacity(
              opacity: on ? 1 : 0.4,
              child: IgnorePointer(
                ignoring: !on,
                child: Column(
                  children: [
                    _switch(
                      title: 'New connections',
                      subtitle: 'When you and someone both show interest',
                      value: prefs.newMatch,
                      onChanged: ctrl.setNewMatch,
                    ),
                    _switch(
                      title: 'New messages',
                      subtitle: 'When someone sends you a message',
                      value: prefs.newMessage,
                      onChanged: ctrl.setNewMessage,
                    ),
                    _switch(
                      title: 'Someone joined your activity',
                      subtitle: 'When a person joins an activity you created',
                      value: prefs.activityJoined,
                      onChanged: ctrl.setActivityJoined,
                    ),
                    _switch(
                      title: 'Activity reminders',
                      subtitle: 'A gentle reminder before an activity you joined',
                      value: prefs.activityReminder,
                      onChanged: ctrl.setActivityReminder,
                    ),
                    _switch(
                      title: 'New activities for you',
                      subtitle:
                          'When a new activity matches your interests nearby',
                      value: prefs.newMatchingActivity,
                      onChanged: ctrl.setNewMatchingActivity,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 16, color: AppColors.inkSoft)),
    );
  }
}

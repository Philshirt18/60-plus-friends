import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_user.dart';
import '../../core/models/social_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_controller.dart';
import 'messages_controller.dart';

/// Combined "Matches" tab: new connections row + conversations list.
class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: SafeArea(
        child: matchesAsync.when(
          loading: () => const LoadingView(),
          error: (_, __) => ErrorView(
            message: 'We could not load your matches.',
            onRetry: () => ref.invalidate(matchesProvider),
          ),
          data: (matches) {
            if (matches.isEmpty) {
              return EmptyState(
                icon: Icons.handshake_outlined,
                title: 'No connections yet',
                message:
                    'Keep discovering people who share your interests. When '
                    'you both show interest, you can start a conversation here.',
                actionLabel: 'Discover people',
                onAction: () => context.go('/discover'),
              );
            }
            final conversations =
                conversationsAsync.valueOrNull ?? const <Conversation>[];
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(matchesProvider),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  _NewConnections(matches: matches),
                  const Divider(height: AppSpacing.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: Text('Conversations',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (conversations.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Say hello to one of your connections above to start '
                        'a conversation.',
                        style: TextStyle(
                            fontSize: 17, color: AppColors.inkSoft),
                      ),
                    )
                  else
                    ...conversations.map(
                      (c) => _ConversationTile(conversation: c),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NewConnections extends ConsumerWidget {
  const _NewConnections({required this.matches});
  final List<Match> matches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    if (me == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text('New connections',
              style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: matches.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) {
              final match = matches[i];
              final otherId = match.otherUser(me.id);
              final personAsync = ref.watch(userByIdProvider(otherId));
              final person = personAsync.valueOrNull;
              return _ConnectionAvatar(
                name: person?.firstName ?? '...',
                photoUrl: person?.profilePhotoUrl,
                onTap: person == null
                    ? null
                    : () => _openConversation(context, ref, match, person),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openConversation(
    BuildContext context,
    WidgetRef ref,
    Match match,
    AppUser person,
  ) async {
    final convo =
        await ref.read(messagesControllerProvider).openConversationForMatch(match);
    if (!context.mounted) return;
    context.push('/conversation', extra: {
      'conversationId': convo.id,
      'person': person,
    });
  }
}

class _ConnectionAvatar extends StatelessWidget {
  const _ConnectionAvatar({
    required this.name,
    required this.photoUrl,
    required this.onTap,
  });
  final String name;
  final String? photoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            ProfileAvatar(name: name, photoUrl: photoUrl, radius: 38),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation});
  final Conversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    if (me == null) return const SizedBox.shrink();
    final otherId = conversation.otherUser(me.id);
    final person = ref.watch(userByIdProvider(otherId)).valueOrNull;
    final unread = conversation.unreadCount > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      leading: ProfileAvatar(
        name: person?.firstName ?? '?',
        photoUrl: person?.profilePhotoUrl,
        radius: 30,
      ),
      title: Text(
        person?.firstName ?? 'Connection',
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        conversation.lastMessage ?? 'Say hello',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 16,
          color: unread ? AppColors.ink : AppColors.inkSoft,
          fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(Formatting.messageTimestamp(conversation.updatedAt),
              style: const TextStyle(fontSize: 14, color: AppColors.inkFaint)),
          const SizedBox(height: 4),
          if (unread)
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      onTap: person == null
          ? null
          : () => context.push('/conversation', extra: {
                'conversationId': conversation.id,
                'person': person,
              }),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_user.dart';
import '../../core/models/social_models.dart';
import '../../core/services/service_locator.dart';
import '../auth/auth_controller.dart';

/// Resolves a user profile by id (cached per id).
final userByIdProvider =
    FutureProvider.family<AppUser?, String>((ref, id) async {
  return ref.watch(dataRepositoryProvider).getUser(id);
});

/// The current user's matches.
final matchesProvider = FutureProvider<List<Match>>((ref) async {
  final me = await ref.watch(currentUserProvider.future);
  if (me == null) return [];
  return ref.watch(dataRepositoryProvider).getMatches(me.id);
});

/// Live conversation list for the current user.
final conversationsProvider = StreamProvider<List<Conversation>>((ref) {
  final me = ref.watch(currentUserProvider).valueOrNull;
  if (me == null) return const Stream.empty();
  return ref.watch(dataRepositoryProvider).watchConversations(me.id);
});

/// Live messages for a conversation.
final messagesProvider =
    StreamProvider.family<List<Message>, String>((ref, conversationId) {
  return ref.watch(dataRepositoryProvider).watchMessages(conversationId);
});

class MessagesController {
  MessagesController(this._ref);
  final Ref _ref;

  Future<Conversation> openConversationForMatch(Match match) async {
    final me = await _ref.read(currentUserProvider.future);
    final repo = _ref.read(dataRepositoryProvider);
    return repo.conversationForMatch(match, me!.id);
  }

  Future<void> send(String conversationId, String text) async {
    final me = await _ref.read(currentUserProvider.future);
    if (me == null) return;
    await _ref.read(dataRepositoryProvider).sendMessage(
          conversationId: conversationId,
          senderId: me.id,
          text: text,
        );
  }

  Future<void> markRead(String conversationId) async {
    final me = await _ref.read(currentUserProvider.future);
    if (me == null) return;
    await _ref
        .read(dataRepositoryProvider)
        .markConversationRead(conversationId, me.id);
  }

  Future<void> block(String userId) async {
    final me = await _ref.read(currentUserProvider.future);
    if (me == null) return;
    await _ref.read(dataRepositoryProvider).blockUser(
          blockingUserId: me.id,
          blockedUserId: userId,
        );
    _ref.invalidate(matchesProvider);
  }

  Future<void> report(Report report) async {
    await _ref.read(dataRepositoryProvider).reportUser(report);
  }
}

final messagesControllerProvider =
    Provider<MessagesController>(MessagesController.new);

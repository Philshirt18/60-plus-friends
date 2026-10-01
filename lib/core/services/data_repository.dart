import 'dart:async';

import 'package:uuid/uuid.dart';

import '../models/activity.dart';
import '../models/app_user.dart';
import '../models/social_models.dart';
import 'seed_data.dart';

/// Abstraction over the data backend (profiles, discovery, matches,
/// messaging, activities, safety).
///
/// The MVP ships an [InMemoryDataRepository]. To use Firestore, add the
/// firebase packages and implement this interface with a
/// `FirestoreDataRepository` backed by collections mirroring the data model,
/// then register it in the service locator. UI and controllers depend only on
/// this abstraction.
abstract class DataRepository {
  // Profile
  Future<AppUser?> getUser(String userId);
  Future<void> saveUser(AppUser user);
  Future<void> deleteUser(String userId);

  // Discovery
  Future<List<AppUser>> discoverCandidates(String forUserId);

  // Interest expressions & matches
  /// Records interest and returns a [Match] if it is now mutual.
  Future<Match?> expressInterest({
    required String fromUserId,
    required String toUserId,
  });
  Future<void> passUser({required String fromUserId, required String toUserId});
  Future<List<Match>> getMatches(String userId);

  // Messaging
  Stream<List<Conversation>> watchConversations(String userId);
  Stream<List<Message>> watchMessages(String conversationId);
  Future<Conversation> conversationForMatch(Match match, String me);
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  });
  Future<void> markConversationRead(String conversationId, String userId);

  // Activities
  Future<List<Activity>> getActivities();
  Future<Activity?> getActivity(String id);
  Future<List<Activity>> getActivitiesForUser(String userId);
  Future<Activity> createActivity(Activity activity);
  Future<Activity> updateActivity(Activity activity);
  Future<Activity> updateActivityPhoto(String activityId, String photoUrl);
  Future<void> deleteActivity(String activityId);
  Future<Activity> joinActivity(String activityId, String userId);
  Future<Activity> leaveActivity(String activityId, String userId);

  // Safety
  Future<void> blockUser({required String blockingUserId, required String blockedUserId});
  Future<void> unblockUser({required String blockingUserId, required String blockedUserId});
  Future<Set<String>> blockedUserIds(String userId);
  Future<void> reportUser(Report report);
}

class InMemoryDataRepository implements DataRepository {
  InMemoryDataRepository() {
    for (final u in SeedData.people()) {
      _users[u.id] = u;
    }
    for (final a in SeedData.activities()) {
      _activities[a.id] = a;
    }
  }

  final _uuid = const Uuid();

  final Map<String, AppUser> _users = {};
  final List<InterestExpression> _expressions = [];
  final Set<String> _passes = {}; // "from|to"
  final Map<String, Match> _matches = {};
  final Map<String, Conversation> _conversations = {};
  final Map<String, List<Message>> _messages = {};
  final Map<String, Activity> _activities = {};
  final List<Report> _reports = [];
  final Set<String> _blocks = {}; // "blocker|blocked"

  final _conversationControllers =
      <String, StreamController<List<Conversation>>>{};
  final _messageControllers = <String, StreamController<List<Message>>>{};

  // ---- Profile ----
  @override
  Future<AppUser?> getUser(String userId) async => _users[userId];

  /// Ids we've already bootstrapped a starter social graph for.
  final Set<String> _bootstrapped = {};

  @override
  Future<void> saveUser(AppUser user) async {
    final isNew = !_users.containsKey(user.id);
    _users[user.id] = user;

    // The first time a real (non-seed) user completes their profile, give
    // them a lifelike starting point: one existing connection with a short
    // conversation, plus a couple of people who have already shown interest
    // in them (so liking those back forms a real match). Other likes stay
    // unanswered, just like real life.
    if (isNew && !user.id.startsWith('seed_')) {
      _bootstrapStarterGraph(user.id);
    }
  }

  void _bootstrapStarterGraph(String userId) {
    if (_bootstrapped.contains(userId)) return;
    _bootstrapped.add(userId);

    // --- C: people who have already expressed interest in this user, so
    // liking them back becomes a mutual match with a celebration.
    for (final id in const ['seed_maria', 'seed_john']) {
      if (_users.containsKey(id)) {
        _expressions.add(InterestExpression(
          fromUserId: id,
          toUserId: userId,
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        ));
      }
    }

    // --- B: an existing connection with a short conversation waiting.
    const partnerId = 'seed_anne';
    final partner = _users[partnerId];
    if (partner == null) return;

    // Mutual interest already happened earlier.
    _expressions.add(InterestExpression(
      fromUserId: userId,
      toUserId: partnerId,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ));
    _expressions.add(InterestExpression(
      fromUserId: partnerId,
      toUserId: userId,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ));

    final me = _users[userId];
    final shared = me == null
        ? <String>[]
        : me.interests.where(partner.interests.contains).toList();

    final match = Match(
      id: _uuid.v4(),
      userA: partnerId,
      userB: userId,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      sharedInterestIds: shared,
    );
    _matches[match.id] = match;

    final convoId = _uuid.v4();
    final convo = Conversation(
      id: convoId,
      matchId: match.id,
      participantIds: [partnerId, userId],
      lastMessage: 'That sounds lovely. Shall we say Thursday for a coffee?',
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      unreadCount: 1,
    );
    _conversations[convoId] = convo;
    _messages[convoId] = [
      Message(
        id: _uuid.v4(),
        conversationId: convoId,
        senderId: partnerId,
        text: "Hello! Lovely to connect. I saw we both enjoy walking.",
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        readAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Message(
        id: _uuid.v4(),
        conversationId: convoId,
        senderId: partnerId,
        text: 'That sounds lovely. Shall we say Thursday for a coffee?',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  @override
  Future<void> deleteUser(String userId) async {
    _users.remove(userId);
    _expressions.removeWhere(
        (e) => e.fromUserId == userId || e.toUserId == userId);
    _matches.removeWhere((_, m) => m.userA == userId || m.userB == userId);
  }

  // ---- Discovery ----
  @override
  Future<List<AppUser>> discoverCandidates(String forUserId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final blocked = await blockedUserIds(forUserId);
    final matchedOthers =
        (await getMatches(forUserId)).map((m) => m.otherUser(forUserId)).toSet();
    return _users.values.where((u) {
      if (u.id == forUserId) return false;
      if (blocked.contains(u.id)) return false;
      if (matchedOthers.contains(u.id)) return false;
      if (_passes.contains('$forUserId|${u.id}')) return false;
      if (_hasExpressed(forUserId, u.id)) return false;
      return true;
    }).toList();
  }

  bool _hasExpressed(String from, String to) =>
      _expressions.any((e) => e.fromUserId == from && e.toUserId == to);

  // ---- Interest / Match ----
  @override
  Future<Match?> expressInterest({
    required String fromUserId,
    required String toUserId,
  }) async {
    if (!_hasExpressed(fromUserId, toUserId)) {
      _expressions.add(InterestExpression(
        fromUserId: fromUserId,
        toUserId: toUserId,
        createdAt: DateTime.now(),
      ));
    }
    final mutual = _hasExpressed(toUserId, fromUserId);
    if (!mutual) return null;

    final existing = _matches.values.firstWhereOrNullCompat(
      (m) => m.hasPair(fromUserId, toUserId),
    );
    if (existing != null) return existing;

    final from = _users[fromUserId];
    final to = _users[toUserId];
    final shared = <String>[];
    if (from != null && to != null) {
      shared.addAll(from.interests.where(to.interests.contains));
    }
    final match = Match(
      id: _uuid.v4(),
      userA: fromUserId,
      userB: toUserId,
      createdAt: DateTime.now(),
      sharedInterestIds: shared,
    );
    _matches[match.id] = match;
    return match;
  }

  @override
  Future<void> passUser({
    required String fromUserId,
    required String toUserId,
  }) async {
    _passes.add('$fromUserId|$toUserId');
  }

  @override
  Future<List<Match>> getMatches(String userId) async {
    final blocked = await blockedUserIds(userId);
    final list = _matches.values
        .where((m) => m.userA == userId || m.userB == userId)
        .where((m) => !blocked.contains(m.otherUser(userId)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // ---- Messaging ----
  @override
  Stream<List<Conversation>> watchConversations(String userId) {
    final controller = _conversationControllers.putIfAbsent(
      userId,
      () => StreamController<List<Conversation>>.broadcast(),
    );
    scheduleMicrotask(() => _emitConversations(userId));
    return controller.stream;
  }

  void _emitConversations(String userId) {
    final controller = _conversationControllers[userId];
    if (controller == null) return;
    final list = _conversations.values
        .where((c) => c.participantIds.contains(userId))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    controller.add(list);
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    final controller = _messageControllers.putIfAbsent(
      conversationId,
      () => StreamController<List<Message>>.broadcast(),
    );
    scheduleMicrotask(() {
      controller.add(List.of(_messages[conversationId] ?? const []));
    });
    return controller.stream;
  }

  @override
  Future<Conversation> conversationForMatch(Match match, String me) async {
    final existing = _conversations.values
        .firstWhereOrNullCompat((c) => c.matchId == match.id);
    if (existing != null) return existing;

    final convo = Conversation(
      id: _uuid.v4(),
      matchId: match.id,
      participantIds: [match.userA, match.userB],
      lastMessage: null,
      updatedAt: DateTime.now(),
    );
    _conversations[convo.id] = convo;
    _messages[convo.id] = [];
    _emitConversations(match.userA);
    _emitConversations(match.userB);
    return convo;
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final convo = _conversations[conversationId];
    if (convo == null) return;

    final message = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: senderId,
      text: trimmed,
      createdAt: DateTime.now(),
    );
    (_messages[conversationId] ??= []).add(message);

    final other = convo.otherUser(senderId);
    _conversations[conversationId] = convo.copyWith(
      lastMessage: trimmed,
      updatedAt: message.createdAt,
      unreadCount: convo.unreadCount + 1,
    );

    _messageControllers[conversationId]
        ?.add(List.of(_messages[conversationId]!));
    _emitConversations(senderId);
    _emitConversations(other);
  }

  @override
  Future<void> markConversationRead(
      String conversationId, String userId) async {
    final list = _messages[conversationId];
    if (list != null) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].senderId != userId && !list[i].isRead) {
          list[i] = list[i].copyWith(readAt: DateTime.now());
        }
      }
    }
    final convo = _conversations[conversationId];
    if (convo != null) {
      _conversations[conversationId] = convo.copyWith(unreadCount: 0);
      _emitConversations(userId);
    }
  }

  // ---- Activities ----
  @override
  Future<List<Activity>> getActivities() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final list = _activities.values.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  @override
  Future<Activity?> getActivity(String id) async => _activities[id];

  @override
  Future<List<Activity>> getActivitiesForUser(String userId) async {
    final list = _activities.values
        .where((a) => a.participantIds.contains(userId))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  @override
  Future<Activity> createActivity(Activity activity) async {
    final id = activity.id.isEmpty ? _uuid.v4() : activity.id;
    final stored = Activity(
      id: id,
      creatorId: activity.creatorId,
      title: activity.title,
      description: activity.description,
      category: activity.category,
      dateTime: activity.dateTime,
      approximateLocation: activity.approximateLocation,
      maxParticipants: activity.maxParticipants,
      interestIds: activity.interestIds,
      participantIds: activity.participantIds.contains(activity.creatorId)
          ? activity.participantIds
          : [activity.creatorId, ...activity.participantIds],
      createdAt: DateTime.now(),
      approxDistanceKm: 0,
      photoUrl: activity.photoUrl,
    );
    _activities[id] = stored;
    return stored;
  }

  @override
  Future<Activity> updateActivity(Activity activity) async {
    _activities[activity.id] = activity;
    return activity;
  }

  @override
  Future<Activity> updateActivityPhoto(String activityId, String photoUrl) async {
    final a = _activities[activityId]!;
    _activities[activityId] = a.copyWith(photoUrl: photoUrl);
    return _activities[activityId]!;
  }

  @override
  Future<void> deleteActivity(String activityId) async {
    _activities.remove(activityId);
  }

  @override
  Future<Activity> joinActivity(String activityId, String userId) async {
    final a = _activities[activityId]!;
    if (!a.participantIds.contains(userId) && !a.isFull) {
      _activities[activityId] =
          a.copyWith(participantIds: [...a.participantIds, userId]);
    }
    return _activities[activityId]!;
  }

  @override
  Future<Activity> leaveActivity(String activityId, String userId) async {
    final a = _activities[activityId]!;
    _activities[activityId] = a.copyWith(
      participantIds:
          a.participantIds.where((id) => id != userId).toList(),
    );
    return _activities[activityId]!;
  }

  // ---- Safety ----
  @override
  Future<void> blockUser({
    required String blockingUserId,
    required String blockedUserId,
  }) async {
    _blocks.add('$blockingUserId|$blockedUserId');
    _emitConversations(blockingUserId);
  }

  @override
  Future<void> unblockUser({
    required String blockingUserId,
    required String blockedUserId,
  }) async {
    _blocks.remove('$blockingUserId|$blockedUserId');
  }

  @override
  Future<Set<String>> blockedUserIds(String userId) async {
    return _blocks
        .where((b) => b.startsWith('$userId|'))
        .map((b) => b.split('|')[1])
        .toSet();
  }

  @override
  Future<void> reportUser(Report report) async {
    _reports.add(report);
  }
}

extension on Match {
  bool hasPair(String a, String b) =>
      (userA == a && userB == b) || (userA == b && userB == a);
}

extension _FirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNullCompat(bool Function(E) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

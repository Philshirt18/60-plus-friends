import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/activity.dart';
import '../../models/app_user.dart';
import '../../models/social_models.dart';
import '../data_repository.dart';
import '../matching.dart';

/// Firestore-backed implementation of [DataRepository].
///
/// Collection layout:
///   users/{uid}                             -> profile (AppUser)
///   users/{uid}/blocks/{blockedUid}         -> a block this user made
///   interestExpressions/{from_to}          -> { from, to, createdAt }
///   passes/{from_to}                        -> { from, to }               (private "not for me")
///   matches/{matchId}                       -> { users:[a,b], userA, userB, sharedInterestIds, createdAt }
///   conversations/{cid}                     -> { matchId, participantIds, lastMessage, updatedAt, unread:{uid:count} }
///   conversations/{cid}/messages/{mid}      -> { senderId, text, createdAt, readBy:[uid] }
///   activities/{aid}                        -> Activity (participantIds array)
///   reports/{rid}                           -> Report
class FirestoreDataRepository implements DataRepository {
  FirestoreDataRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _expressions =>
      _db.collection('interestExpressions');
  CollectionReference<Map<String, dynamic>> get _passes =>
      _db.collection('passes');
  CollectionReference<Map<String, dynamic>> get _matches =>
      _db.collection('matches');
  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection('conversations');
  CollectionReference<Map<String, dynamic>> get _activities =>
      _db.collection('activities');
  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  String _pairId(String a, String b) => '${a}_$b';

  // ---------------------------------------------------------------- Profile
  @override
  Future<AppUser?> getUser(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return null;
    return AppUser.fromMap({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<void> saveUser(AppUser user) async {
    final ref = _users.doc(user.id);
    final existed = (await ref.get()).exists;
    await ref.set(user.toMap(), SetOptions(merge: true));

    // First time a real user completes their profile: give them a lifelike
    // starting point (B + C) — an existing connection with a waiting message,
    // plus a couple of seed people who already "liked" them so liking back
    // forms a real match. Guarded so it runs at most once.
    if (!existed && !user.id.startsWith('seed_')) {
      // Best-effort: a failure here (e.g. offline) must never make the
      // profile save itself look like it failed — the profile is already
      // persisted at this point.
      try {
        await _bootstrapStarterGraph(user.id);
      } catch (_) {}
    }
  }

  Future<void> _bootstrapStarterGraph(String userId) async {
    // Guard: skip if a marker already exists.
    final marker = _users.doc(userId).collection('meta').doc('starter');
    if ((await marker.get()).exists) return;

    // Only proceed if seed people are present in Firestore.
    final maria = await _users.doc('seed_maria').get();
    final anne = await _users.doc('seed_anne').get();
    if (!maria.exists && !anne.exists) return;

    final batch = _db.batch();

    // C: seed people who have already expressed interest in this user.
    for (final id in const ['seed_maria', 'seed_john']) {
      batch.set(_expressions.doc(_pairId(id, userId)), {
        'from': id,
        'to': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // B: an existing mutual connection (Anne) with a short conversation.
    if (anne.exists) {
      const partnerId = 'seed_anne';
      batch.set(_expressions.doc(_pairId(userId, partnerId)), {
        'from': userId,
        'to': partnerId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(_expressions.doc(_pairId(partnerId, userId)), {
        'from': partnerId,
        'to': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final me = await _users.doc(userId).get();
      final myInterests =
          (me.data()?['interests'] as List?)?.cast<String>() ?? const [];
      final theirInterests =
          (anne.data()?['interests'] as List?)?.cast<String>() ?? const [];
      final shared =
          myInterests.where(theirInterests.contains).toList();

      final matchRef = _matches.doc();
      batch.set(matchRef, {
        'users': [partnerId, userId],
        'userA': partnerId,
        'userB': userId,
        'sharedInterestIds': shared,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final convoRef = _conversations.doc();
      batch.set(convoRef, {
        'matchId': matchRef.id,
        'participantIds': [partnerId, userId],
        'lastMessage': 'That sounds lovely. Shall we say Thursday for a coffee?',
        'updatedAt': FieldValue.serverTimestamp(),
        'unread': {userId: 1, partnerId: 0},
      });
      batch.set(convoRef.collection('messages').doc(), {
        'senderId': partnerId,
        'text': "Hello! Lovely to connect. I saw we both enjoy walking.",
        'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 4))),
        'readBy': [partnerId, userId],
      });
      batch.set(convoRef.collection('messages').doc(), {
        'senderId': partnerId,
        'text': 'That sounds lovely. Shall we say Thursday for a coffee?',
        'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 2))),
        'readBy': [partnerId],
      });
    }

    batch.set(marker, {'createdAt': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  @override
  Future<void> deleteUser(String userId) async {
    // Remove the profile. Related content (matches, messages) is cleaned up
    // by scheduled functions / rules in production; here we remove the doc so
    // the user disappears from discovery immediately (GDPR erasure of profile).
    await _users.doc(userId).delete();
  }

  // -------------------------------------------------------------- Discovery
  @override
  Future<List<AppUser>> discoverCandidates(String forUserId) async {
    final me = await getUser(forUserId);
    if (me == null) return [];

    // Fetch a reasonable candidate pool. For a larger user base this would be
    // narrowed by geo/city indexes; for now we page the collection.
    final snap = await _users.limit(200).get();

    final blocked = await blockedUserIds(forUserId);
    final matchedOthers =
        (await getMatches(forUserId)).map((m) => m.otherUser(forUserId)).toSet();

    // Exclude people already expressed-to or passed.
    final expressed = await _expressions
        .where('from', isEqualTo: forUserId)
        .get()
        .then((s) => s.docs.map((d) => d.data()['to'] as String).toSet());
    final passed = await _passes
        .where('from', isEqualTo: forUserId)
        .get()
        .then((s) => s.docs.map((d) => d.data()['to'] as String).toSet());

    final candidates = <AppUser>[];
    for (final doc in snap.docs) {
      final id = doc.id;
      if (id == forUserId) continue;
      if (blocked.contains(id) ||
          matchedOthers.contains(id) ||
          expressed.contains(id) ||
          passed.contains(id)) {
        continue;
      }
      candidates.add(AppUser.fromMap({...doc.data(), 'id': id}));
    }
    return MatchScorer.rank(me, candidates);
  }

  // ----------------------------------------------------- Interest & matches
  @override
  Future<Match?> expressInterest({
    required String fromUserId,
    required String toUserId,
  }) async {
    // Record my interest (idempotent via deterministic id).
    await _expressions.doc(_pairId(fromUserId, toUserId)).set({
      'from': fromUserId,
      'to': toUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Did the other person already express interest in me?
    final reverse =
        await _expressions.doc(_pairId(toUserId, fromUserId)).get();
    if (!reverse.exists) return null;

    // Mutual — create (or fetch) the match.
    final existing = await _matches
        .where('users', arrayContains: fromUserId)
        .get()
        .then((s) => s.docs.where((d) {
              final users = (d.data()['users'] as List).cast<String>();
              return users.contains(toUserId);
            }).toList());
    if (existing.isNotEmpty) {
      return _matchFrom(existing.first);
    }

    final from = await getUser(fromUserId);
    final to = await getUser(toUserId);
    final shared = (from != null && to != null)
        ? from.interests.where(to.interests.contains).toList()
        : <String>[];

    final ref = _matches.doc();
    final data = {
      'users': [fromUserId, toUserId],
      'userA': fromUserId,
      'userB': toUserId,
      'sharedInterestIds': shared,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await ref.set(data);
    return Match(
      id: ref.id,
      userA: fromUserId,
      userB: toUserId,
      createdAt: DateTime.now(),
      sharedInterestIds: shared,
    );
  }

  @override
  Future<void> passUser({
    required String fromUserId,
    required String toUserId,
  }) async {
    await _passes.doc(_pairId(fromUserId, toUserId)).set({
      'from': fromUserId,
      'to': toUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<Match>> getMatches(String userId) async {
    final snap = await _matches.where('users', arrayContains: userId).get();
    final blocked = await blockedUserIds(userId);
    final matches = snap.docs
        .map(_matchFrom)
        .where((m) => !blocked.contains(m.otherUser(userId)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches;
  }

  Match _matchFrom(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    return Match(
      id: d.id,
      userA: data['userA'] as String,
      userB: data['userB'] as String,
      createdAt: _ts(data['createdAt']),
      sharedInterestIds:
          (data['sharedInterestIds'] as List?)?.cast<String>() ?? const [],
    );
  }

  // --------------------------------------------------------------- Messaging
  @override
  Stream<List<Conversation>> watchConversations(String userId) {
    return _conversations
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              final unreadMap =
                  (data['unread'] as Map?)?.cast<String, dynamic>() ?? {};
              return Conversation(
                id: d.id,
                matchId: data['matchId'] as String? ?? '',
                participantIds:
                    (data['participantIds'] as List).cast<String>(),
                lastMessage: data['lastMessage'] as String?,
                updatedAt: _ts(data['updatedAt']),
                unreadCount: (unreadMap[userId] as num?)?.toInt() ?? 0,
              );
            }).toList());
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              final readBy = (data['readBy'] as List?)?.cast<String>() ?? [];
              return Message(
                id: d.id,
                conversationId: conversationId,
                senderId: data['senderId'] as String,
                text: data['text'] as String? ?? '',
                createdAt: _ts(data['createdAt']),
                readAt: readBy.length > 1 ? _ts(data['createdAt']) : null,
              );
            }).toList());
  }

  @override
  Future<Conversation> conversationForMatch(Match match, String me) async {
    final existing = await _conversations
        .where('matchId', isEqualTo: match.id)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      final d = existing.docs.first;
      final data = d.data();
      return Conversation(
        id: d.id,
        matchId: match.id,
        participantIds: (data['participantIds'] as List).cast<String>(),
        lastMessage: data['lastMessage'] as String?,
        updatedAt: _ts(data['updatedAt']),
      );
    }
    final ref = _conversations.doc();
    await ref.set({
      'matchId': match.id,
      'participantIds': [match.userA, match.userB],
      'lastMessage': null,
      'updatedAt': FieldValue.serverTimestamp(),
      'unread': {match.userA: 0, match.userB: 0},
    });
    return Conversation(
      id: ref.id,
      matchId: match.id,
      participantIds: [match.userA, match.userB],
      lastMessage: null,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final convoRef = _conversations.doc(conversationId);
    final convo = await convoRef.get();
    final participants =
        (convo.data()?['participantIds'] as List?)?.cast<String>() ?? [];
    final other = participants.firstWhere((p) => p != senderId,
        orElse: () => senderId);

    final batch = _db.batch();
    final msgRef = convoRef.collection('messages').doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [senderId],
    });
    batch.update(convoRef, {
      'lastMessage': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
      'unread.$other': FieldValue.increment(1),
    });
    await batch.commit();
  }

  @override
  Future<void> markConversationRead(
      String conversationId, String userId) async {
    await _conversations
        .doc(conversationId)
        .update({'unread.$userId': 0});
  }

  // -------------------------------------------------------------- Activities
  @override
  Future<List<Activity>> getActivities() async {
    final snap =
        await _activities.orderBy('dateTime').limit(200).get();
    return snap.docs.map(_activityFrom).toList();
  }

  @override
  Future<Activity?> getActivity(String id) async {
    final doc = await _activities.doc(id).get();
    if (!doc.exists) return null;
    return _activityFrom(doc);
  }

  @override
  Future<List<Activity>> getActivitiesForUser(String userId) async {
    final snap = await _activities
        .where('participantIds', arrayContains: userId)
        .orderBy('dateTime')
        .get();
    return snap.docs.map(_activityFrom).toList();
  }

  @override
  Future<Activity> createActivity(Activity activity) async {
    final ref =
        activity.id.isEmpty ? _activities.doc() : _activities.doc(activity.id);
    final participants = activity.participantIds.contains(activity.creatorId)
        ? activity.participantIds
        : [activity.creatorId, ...activity.participantIds];
    await ref.set({
      'creatorId': activity.creatorId,
      'title': activity.title,
      'description': activity.description,
      'category': activity.category,
      'dateTime': Timestamp.fromDate(activity.dateTime),
      'approximateLocation': activity.approximateLocation,
      'maxParticipants': activity.maxParticipants,
      'interestIds': activity.interestIds,
      'participantIds': participants,
      'createdAt': FieldValue.serverTimestamp(),
      'photoUrl': activity.photoUrl,
    });
    final doc = await ref.get();
    return _activityFrom(doc);
  }

  @override
  Future<Activity> updateActivity(Activity activity) async {
    await _activities.doc(activity.id).update({
      'title': activity.title,
      'description': activity.description,
      'category': activity.category,
      'dateTime': Timestamp.fromDate(activity.dateTime),
      'approximateLocation': activity.approximateLocation,
      'maxParticipants': activity.maxParticipants,
      'interestIds': activity.interestIds,
      'photoUrl': activity.photoUrl,
    });
    return (await getActivity(activity.id))!;
  }

  @override
  Future<Activity> updateActivityPhoto(String activityId, String photoUrl) async {
    await _activities.doc(activityId).update({'photoUrl': photoUrl});
    return (await getActivity(activityId))!;
  }

  @override
  Future<void> deleteActivity(String activityId) async {
    await _activities.doc(activityId).delete();
  }

  @override
  Future<Activity> joinActivity(String activityId, String userId) async {
    await _activities.doc(activityId).update({
      'participantIds': FieldValue.arrayUnion([userId]),
    });
    return (await getActivity(activityId))!;
  }

  @override
  Future<Activity> leaveActivity(String activityId, String userId) async {
    await _activities.doc(activityId).update({
      'participantIds': FieldValue.arrayRemove([userId]),
    });
    return (await getActivity(activityId))!;
  }

  Activity _activityFrom(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data()!;
    return Activity(
      id: d.id,
      creatorId: data['creatorId'] as String,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      dateTime: _ts(data['dateTime']),
      approximateLocation: data['approximateLocation'] as String? ?? '',
      maxParticipants: (data['maxParticipants'] as num?)?.toInt() ?? 6,
      interestIds: (data['interestIds'] as List?)?.cast<String>() ?? const [],
      participantIds:
          (data['participantIds'] as List?)?.cast<String>() ?? const [],
      createdAt: _ts(data['createdAt']),
      photoUrl: data['photoUrl'] as String?,
    );
  }

  // ------------------------------------------------------------------ Safety
  @override
  Future<void> blockUser({
    required String blockingUserId,
    required String blockedUserId,
  }) async {
    await _users
        .doc(blockingUserId)
        .collection('blocks')
        .doc(blockedUserId)
        .set({'createdAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> unblockUser({
    required String blockingUserId,
    required String blockedUserId,
  }) async {
    await _users
        .doc(blockingUserId)
        .collection('blocks')
        .doc(blockedUserId)
        .delete();
  }

  @override
  Future<Set<String>> blockedUserIds(String userId) async {
    final snap = await _users.doc(userId).collection('blocks').get();
    return snap.docs.map((d) => d.id).toSet();
  }

  @override
  Future<void> reportUser(Report report) async {
    await _reports.add({
      'reporterId': report.reporterId,
      'reportedUserId': report.reportedUserId,
      'reason': report.reason,
      'details': report.details,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------------ Helper
  DateTime _ts(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}

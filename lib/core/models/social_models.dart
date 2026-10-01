// Models for interest expressions, matches, conversations and messages.

class InterestExpression {
  const InterestExpression({
    required this.fromUserId,
    required this.toUserId,
    required this.createdAt,
  });

  final String fromUserId;
  final String toUserId;
  final DateTime createdAt;
}

class Match {
  const Match({
    required this.id,
    required this.userA,
    required this.userB,
    required this.createdAt,
    required this.sharedInterestIds,
  });

  final String id;
  final String userA;
  final String userB;
  final DateTime createdAt;
  final List<String> sharedInterestIds;

  String otherUser(String me) => me == userA ? userB : userA;
}

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  Message copyWith({DateTime? readAt}) => Message(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        text: text,
        createdAt: createdAt,
        readAt: readAt ?? this.readAt,
      );
}

class Conversation {
  const Conversation({
    required this.id,
    required this.matchId,
    required this.participantIds,
    required this.lastMessage,
    required this.updatedAt,
    this.unreadCount = 0,
  });

  final String id;
  final String matchId;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime updatedAt;
  final int unreadCount;

  String otherUser(String me) =>
      participantIds.firstWhere((p) => p != me, orElse: () => me);

  Conversation copyWith({
    String? lastMessage,
    DateTime? updatedAt,
    int? unreadCount,
  }) =>
      Conversation(
        id: id,
        matchId: matchId,
        participantIds: participantIds,
        lastMessage: lastMessage ?? this.lastMessage,
        updatedAt: updatedAt ?? this.updatedAt,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}

/// A safety report filed against a user.
class Report {
  const Report({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.details,
    required this.createdAt,
  });

  final String id;
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final String details;
  final DateTime createdAt;
}

class Block {
  const Block({
    required this.blockingUserId,
    required this.blockedUserId,
    required this.createdAt,
  });

  final String blockingUserId;
  final String blockedUserId;
  final DateTime createdAt;
}

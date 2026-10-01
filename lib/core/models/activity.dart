/// A local, real-world activity that users can create and join.
class Activity {
  const Activity({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.category,
    required this.dateTime,
    required this.approximateLocation,
    required this.maxParticipants,
    required this.interestIds,
    required this.participantIds,
    required this.createdAt,
    this.approxDistanceKm,
    this.photoUrl,
  });

  final String id;
  final String creatorId;
  final String title;
  final String description;
  final String? photoUrl;

  /// Free-form category label, e.g. "Walking · Outdoors".
  final String category;
  final DateTime dateTime;

  /// Approximate location label, e.g. "Torre del Mar" — never an address.
  final String approximateLocation;
  final int maxParticipants;
  final List<String> interestIds;
  final List<String> participantIds;
  final DateTime createdAt;
  final double? approxDistanceKm;

  int get interestedCount => participantIds.length;

  bool get isFull => participantIds.length >= maxParticipants;

  bool hasJoined(String userId) => participantIds.contains(userId);

  bool isToday() {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  bool isThisWeek() {
    final now = DateTime.now();
    final end = now.add(const Duration(days: 7));
    return dateTime.isAfter(now.subtract(const Duration(hours: 12))) &&
        dateTime.isBefore(end);
  }

  Activity copyWith({
    String? title,
    String? description,
    String? category,
    DateTime? dateTime,
    String? approximateLocation,
    int? maxParticipants,
    List<String>? interestIds,
    List<String>? participantIds,
    String? photoUrl,
  }) =>
      Activity(
        id: id,
        creatorId: creatorId,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        dateTime: dateTime ?? this.dateTime,
        approximateLocation: approximateLocation ?? this.approximateLocation,
        maxParticipants: maxParticipants ?? this.maxParticipants,
        interestIds: interestIds ?? this.interestIds,
        participantIds: participantIds ?? this.participantIds,
        createdAt: createdAt,
        approxDistanceKm: approxDistanceKm,
        photoUrl: photoUrl ?? this.photoUrl,
      );
}

import '../models/app_user.dart';

/// Simple, transparent scoring for MVP discovery ranking.
///
/// Scoring (easy to tweak):
///   +10 per shared interest
///   +20 same city
///   +10 nearby (<= 10 km)
///   +5  similar age range (adjacent or same bracket)
///   +10 per shared "looking for" preference
class MatchScorer {
  static const int perSharedInterest = 10;
  static const int sameCity = 20;
  static const int nearby = 10;
  static const int similarAge = 5;
  static const int perSharedLookingFor = 10;

  static const double nearbyThresholdKm = 10;

  /// Interests the two users have in common.
  static List<String> sharedInterests(AppUser me, AppUser other) =>
      me.interests.where(other.interests.contains).toList();

  static int score(AppUser me, AppUser other) {
    var total = 0;

    total += sharedInterests(me, other).length * perSharedInterest;

    if (me.city.isNotEmpty &&
        me.city.toLowerCase() == other.city.toLowerCase()) {
      total += sameCity;
    }

    final dist = other.approxDistanceKm;
    if (dist != null && dist <= nearbyThresholdKm) {
      total += nearby;
    }

    final ageGap =
        (me.ageRange.index - other.ageRange.index).abs();
    if (ageGap <= 1) total += similarAge;

    final sharedLooking =
        me.lookingFor.where(other.lookingFor.contains).length;
    total += sharedLooking * perSharedLookingFor;

    return total;
  }

  /// Returns candidates sorted by descending score.
  static List<AppUser> rank(AppUser me, List<AppUser> candidates) {
    final scored = candidates
        .map((c) => (user: c, score: score(me, c)))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.map((e) => e.user).toList();
  }
}

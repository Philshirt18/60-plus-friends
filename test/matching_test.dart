import 'package:flutter_test/flutter_test.dart';
import 'package:sixty_plus_friends/core/models/app_user.dart';
import 'package:sixty_plus_friends/core/models/interest.dart';
import 'package:sixty_plus_friends/core/services/matching.dart';

AppUser _user({
  required String id,
  required String city,
  double? distance,
  AgeRange age = AgeRange.a65to69,
  List<String> interests = const [],
  List<LookingFor> lookingFor = const [],
}) {
  return AppUser(
    id: id,
    firstName: id,
    ageRange: age,
    country: 'Spain',
    city: city,
    approximateArea: city,
    approxDistanceKm: distance,
    interests: interests,
    lookingFor: lookingFor,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('MatchScorer', () {
    final me = _user(
      id: 'me',
      city: 'Málaga',
      interests: const ['walking', 'travel', 'music'],
      lookingFor: const [LookingFor.friendship, LookingFor.activities],
    );

    test('awards points for shared interests, city, distance, age and looking-for',
        () {
      final other = _user(
        id: 'other',
        city: 'Málaga',
        distance: 3,
        age: AgeRange.a65to69,
        interests: const ['walking', 'travel', 'books'],
        lookingFor: const [LookingFor.friendship],
      );

      // 2 shared interests (20) + same city (20) + nearby (10)
      // + same age bracket (5) + 1 shared looking-for (10) = 65
      expect(MatchScorer.score(me, other), 65);
    });

    test('ranks a stronger candidate ahead of a weaker one', () {
      final strong = _user(
        id: 'strong',
        city: 'Málaga',
        distance: 2,
        interests: const ['walking', 'travel', 'music'],
        lookingFor: const [LookingFor.friendship, LookingFor.activities],
      );
      final weak = _user(
        id: 'weak',
        city: 'Sevilla',
        distance: 200,
        age: AgeRange.a80plus,
        interests: const ['golf'],
      );

      final ranked = MatchScorer.rank(me, [weak, strong]);
      expect(ranked.first.id, 'strong');
      expect(ranked.last.id, 'weak');
    });
  });
}

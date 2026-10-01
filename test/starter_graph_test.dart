import 'package:flutter_test/flutter_test.dart';
import 'package:sixty_plus_friends/core/models/app_user.dart';
import 'package:sixty_plus_friends/core/models/interest.dart';
import 'package:sixty_plus_friends/core/services/data_repository.dart';

AppUser _me() => AppUser(
      id: 'uid_judge',
      firstName: 'Judge',
      ageRange: AgeRange.a65to69,
      country: 'Spain',
      city: 'Málaga',
      approximateArea: 'Torre del Mar',
      interests: const ['walking', 'coffee', 'travel'],
      lookingFor: const [LookingFor.friendship],
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('Starter social graph (B + C)', () {
    test('new user starts with one existing match and a conversation', () async {
      final repo = InMemoryDataRepository();
      await repo.saveUser(_me());

      final matches = await repo.getMatches('uid_judge');
      expect(matches, isNotEmpty,
          reason: 'Judge should already have a connection on first open');

      final convos = await repo.watchConversations('uid_judge').first;
      expect(convos, isNotEmpty);
      expect(convos.first.unreadCount, greaterThan(0),
          reason: 'A waiting unread message makes the app feel alive');
    });

    test('liking someone who already liked you forms a real match', () async {
      final repo = InMemoryDataRepository();
      await repo.saveUser(_me());

      // Maria has already expressed interest in the judge (seeded).
      final match = await repo.expressInterest(
        fromUserId: 'uid_judge',
        toUserId: 'seed_maria',
      );
      expect(match, isNotNull,
          reason: 'Reciprocated interest should create a match');
    });

    test('liking someone who has NOT liked you does not match', () async {
      final repo = InMemoryDataRepository();
      await repo.saveUser(_me());

      // Carmen has not expressed interest in the judge.
      final match = await repo.expressInterest(
        fromUserId: 'uid_judge',
        toUserId: 'seed_carmen',
      );
      expect(match, isNull,
          reason: 'Unreciprocated interest stays pending, like real life');
    });

    test('bootstrap only happens once', () async {
      final repo = InMemoryDataRepository();
      await repo.saveUser(_me());
      final firstCount = (await repo.getMatches('uid_judge')).length;

      // Saving again (e.g. profile edit) must not add another starter match.
      await repo.saveUser(_me().copyWith(bio: 'updated'));
      final secondCount = (await repo.getMatches('uid_judge')).length;

      expect(secondCount, firstCount);
    });
  });
}

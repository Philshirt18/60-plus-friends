import '../models/activity.dart';
import '../models/app_user.dart';
import '../models/interest.dart';

/// Seed people & activities so the app is lively on first run (helps the
/// cold-start problem for the demo). All locations are approximate area labels.
class SeedData {
  SeedData._();

  static final DateTime _now = DateTime.now();

  static List<AppUser> people() => [
        AppUser(
          id: 'seed_maria',
          firstName: 'Maria',
          ageRange: AgeRange.a65to69,
          country: 'Spain',
          city: 'Málaga',
          approximateArea: 'Torre del Mar',
          approxDistanceKm: 3,
          profilePhotoUrl: 'asset://assets/images/maria.png',
          bio:
              "I enjoy long walks, classical music and discovering new places. I'd love to meet people nearby for coffee or a walk.",
          interests: const ['walking', 'travel', 'music', 'coffee'],
          lookingFor: const [LookingFor.friendship, LookingFor.activities],
          createdAt: _now,
        ),
        AppUser(
          id: 'seed_john',
          firstName: 'John',
          ageRange: AgeRange.a70to74,
          country: 'Spain',
          city: 'Málaga',
          approximateArea: 'Nerja',
          approxDistanceKm: 8,
          profilePhotoUrl: 'asset://assets/images/john.png',
          bio:
              'Retired teacher, keen on history, books and a good game of cards. Always up for a friendly chat over coffee.',
          interests: const ['history', 'books', 'games', 'coffee'],
          lookingFor: const [LookingFor.conversation, LookingFor.hobbyPartners],
          createdAt: _now,
        ),
        AppUser(
          id: 'seed_carmen',
          firstName: 'Carmen',
          ageRange: AgeRange.a60to64,
          country: 'Spain',
          city: 'Vélez-Málaga',
          approximateArea: 'Vélez-Málaga',
          approxDistanceKm: 5,
          profilePhotoUrl: 'asset://assets/images/carmen.png',
          bio:
              'Love gardening, painting and swimming. Looking for friendly people to share hobbies and sunny mornings with.',
          interests: const ['gardening', 'painting', 'swimming', 'walking'],
          lookingFor: const [LookingFor.hobbyPartners, LookingFor.localCommunity],
          createdAt: _now,
        ),
        AppUser(
          id: 'seed_peter',
          firstName: 'Peter',
          ageRange: AgeRange.a75to79,
          country: 'Spain',
          city: 'Málaga',
          approximateArea: 'Málaga centre',
          approxDistanceKm: 12,
          profilePhotoUrl: 'asset://assets/images/peter.png',
          bio:
              'Photography enthusiast and slow traveller. Would enjoy company for museum visits and seaside strolls.',
          interests: const ['photography', 'travel', 'walking', 'history'],
          lookingFor: const [LookingFor.travelCompanions, LookingFor.friendship],
          createdAt: _now,
        ),
        AppUser(
          id: 'seed_anne',
          firstName: 'Anne',
          ageRange: AgeRange.a65to69,
          country: 'Spain',
          city: 'Málaga',
          approximateArea: 'Torre del Mar',
          approxDistanceKm: 2,
          profilePhotoUrl: 'asset://assets/images/anne.png',
          bio:
              'Yoga most mornings, cooking most evenings. Happy to meet people for a walk, a coffee or a shared meal.',
          interests: const ['yoga', 'cooking', 'coffee', 'walking'],
          lookingFor: const [LookingFor.friendship, LookingFor.localCommunity],
          createdAt: _now,
        ),
        AppUser(
          id: 'seed_david',
          firstName: 'David',
          ageRange: AgeRange.a70to74,
          country: 'Spain',
          city: 'Nerja',
          approximateArea: 'Nerja',
          approxDistanceKm: 9,
          profilePhotoUrl: 'asset://assets/images/david.png',
          bio:
              'Cyclist and amateur guitarist. Looking for hobby partners and people who enjoy the outdoors.',
          interests: const ['cycling', 'music', 'hiking', 'beach'],
          lookingFor: const [LookingFor.hobbyPartners, LookingFor.activities],
          createdAt: _now,
        ),
      ];

  static List<Activity> activities() => [
        Activity(
          id: 'seed_act_walk',
          creatorId: 'seed_maria',
          title: 'Sunday Morning Walk',
          description:
              "I'm going for a relaxed walk along the promenade and would be happy to have some company.",
          category: 'Walking · Outdoors',
          dateTime: _nextWeekday(DateTime.sunday, 10, 30),
          approximateLocation: 'Torre del Mar',
          maxParticipants: 8,
          interestIds: const ['walking', 'beach'],
          participantIds: const ['seed_maria', 'seed_anne', 'seed_peter', 'seed_carmen'],
          createdAt: _now,
          approxDistanceKm: 3,
          photoUrl: 'asset://assets/images/activity_walk.png',
        ),
        Activity(
          id: 'seed_act_coffee',
          creatorId: 'seed_john',
          title: 'Coffee and conversation',
          description:
              'A friendly get-together over coffee. All welcome, come and say hello.',
          category: 'Conversation · Coffee',
          dateTime: _nextWeekday(DateTime.thursday, 16, 0),
          approximateLocation: 'Torre del Mar',
          maxParticipants: 6,
          interestIds: const ['coffee', 'conversation'],
          participantIds: const ['seed_john', 'seed_anne'],
          createdAt: _now,
          approxDistanceKm: 3,
          photoUrl: 'asset://assets/images/activity_coffee.png',
        ),
        Activity(
          id: 'seed_act_cards',
          creatorId: 'seed_carmen',
          title: 'Afternoon card games',
          description:
              'Casual card games and good conversation. Beginners very welcome.',
          category: 'Games · Social',
          dateTime: _nextWeekday(DateTime.tuesday, 17, 30),
          approximateLocation: 'Vélez-Málaga',
          maxParticipants: 4,
          interestIds: const ['games', 'conversation'],
          participantIds: const ['seed_carmen'],
          createdAt: _now,
          approxDistanceKm: 5,
          photoUrl: 'asset://assets/images/activity_cards.png',
        ),
        Activity(
          id: 'seed_act_photo',
          creatorId: 'seed_peter',
          title: 'Old town photo stroll',
          description:
              'A gentle walk through the old town taking photos. Any camera or phone is fine.',
          category: 'Photography · Walking',
          dateTime: _nextWeekday(DateTime.saturday, 11, 0),
          approximateLocation: 'Málaga centre',
          maxParticipants: 6,
          interestIds: const ['photography', 'walking', 'history'],
          participantIds: const ['seed_peter', 'seed_david'],
          createdAt: _now,
          approxDistanceKm: 12,
          photoUrl: 'asset://assets/images/activity_photo.png',
        ),
      ];

  static DateTime _nextWeekday(int weekday, int hour, int minute) {
    var date = DateTime(_now.year, _now.month, _now.day, hour, minute);
    while (date.weekday != weekday || date.isBefore(_now)) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }
}

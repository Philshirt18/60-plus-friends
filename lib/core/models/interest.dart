import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Interest categories offered during onboarding.
enum InterestCategory {
  outdoors('Outdoors', AppColors.outdoorsBg, AppColors.outdoorsFg),
  social('Social', AppColors.socialBg, AppColors.socialFg),
  creative('Creative', AppColors.creativeBg, AppColors.creativeFg),
  learning('Learning', AppColors.learningBg, AppColors.learningFg),
  fitness('Sports & Fitness', AppColors.fitnessBg, AppColors.fitnessFg);

  const InterestCategory(this.label, this.background, this.foreground);
  final String label;
  final Color background;
  final Color foreground;
}

/// A single interest a user can select.
class Interest {
  const Interest({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
  });

  final String id;
  final String name;
  final InterestCategory category;
  final IconData icon;

  @override
  bool operator ==(Object other) => other is Interest && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// The static catalogue of interests available in the MVP.
class InterestCatalog {
  InterestCatalog._();

  static const List<Interest> all = [
    // Outdoors
    Interest(id: 'walking', name: 'Walking', category: InterestCategory.outdoors, icon: Icons.directions_walk),
    Interest(id: 'hiking', name: 'Hiking', category: InterestCategory.outdoors, icon: Icons.terrain),
    Interest(id: 'cycling', name: 'Cycling', category: InterestCategory.outdoors, icon: Icons.directions_bike),
    Interest(id: 'gardening', name: 'Gardening', category: InterestCategory.outdoors, icon: Icons.local_florist),
    Interest(id: 'beach', name: 'Beach', category: InterestCategory.outdoors, icon: Icons.beach_access),
    // Social
    Interest(id: 'coffee', name: 'Coffee', category: InterestCategory.social, icon: Icons.local_cafe),
    Interest(id: 'restaurants', name: 'Restaurants', category: InterestCategory.social, icon: Icons.restaurant),
    Interest(id: 'travel', name: 'Travel', category: InterestCategory.social, icon: Icons.flight_takeoff),
    Interest(id: 'conversation', name: 'Conversation', category: InterestCategory.social, icon: Icons.chat_bubble_outline),
    Interest(id: 'games', name: 'Games', category: InterestCategory.social, icon: Icons.casino),
    // Creative
    Interest(id: 'painting', name: 'Painting', category: InterestCategory.creative, icon: Icons.palette),
    Interest(id: 'photography', name: 'Photography', category: InterestCategory.creative, icon: Icons.camera_alt),
    Interest(id: 'music', name: 'Music', category: InterestCategory.creative, icon: Icons.music_note),
    Interest(id: 'writing', name: 'Writing', category: InterestCategory.creative, icon: Icons.edit_note),
    Interest(id: 'crafts', name: 'Crafts', category: InterestCategory.creative, icon: Icons.cut),
    // Learning
    Interest(id: 'languages', name: 'Languages', category: InterestCategory.learning, icon: Icons.translate),
    Interest(id: 'history', name: 'History', category: InterestCategory.learning, icon: Icons.account_balance),
    Interest(id: 'technology', name: 'Technology', category: InterestCategory.learning, icon: Icons.devices),
    Interest(id: 'cooking', name: 'Cooking', category: InterestCategory.learning, icon: Icons.soup_kitchen),
    Interest(id: 'books', name: 'Books', category: InterestCategory.learning, icon: Icons.menu_book),
    // Sports & Fitness
    Interest(id: 'yoga', name: 'Yoga', category: InterestCategory.fitness, icon: Icons.self_improvement),
    Interest(id: 'swimming', name: 'Swimming', category: InterestCategory.fitness, icon: Icons.pool),
    Interest(id: 'tennis', name: 'Tennis', category: InterestCategory.fitness, icon: Icons.sports_tennis),
    Interest(id: 'golf', name: 'Golf', category: InterestCategory.fitness, icon: Icons.golf_course),
    Interest(id: 'dancing', name: 'Dancing', category: InterestCategory.fitness, icon: Icons.music_note_outlined),
  ];

  static final Map<String, Interest> _byId = {for (final i in all) i.id: i};

  static Interest? byId(String id) => _byId[id];

  static String nameOf(String id) => _byId[id]?.name ?? id;

  static IconData iconOf(String id) => _byId[id]?.icon ?? Icons.star_outline;

  static InterestCategory? categoryOf(String id) => _byId[id]?.category;

  static List<Interest> byCategory(InterestCategory category) =>
      all.where((i) => i.category == category).toList();
}

/// What a user is looking for (friendship-oriented, never romantic).
enum LookingFor {
  friendship('Friendship'),
  activities('Someone for activities'),
  conversation('Conversation'),
  hobbyPartners('Hobby partners'),
  travelCompanions('Travel companions'),
  localCommunity('Local community');

  const LookingFor(this.label);
  final String label;

  static LookingFor fromName(String name) =>
      LookingFor.values.firstWhere((e) => e.name == name,
          orElse: () => LookingFor.friendship);
}

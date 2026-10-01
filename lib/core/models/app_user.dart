import 'interest.dart';

/// Age brackets used instead of an exact age for privacy and simplicity.
enum AgeRange {
  a60to64('60–64', 62),
  a65to69('65–69', 67),
  a70to74('70–74', 72),
  a75to79('75–79', 77),
  a80plus('80+', 82);

  const AgeRange(this.label, this.midpoint);
  final String label;
  final int midpoint;

  static AgeRange fromName(String name) =>
      AgeRange.values.firstWhere((e) => e.name == name,
          orElse: () => AgeRange.a60to64);
}

/// A user profile. Only privacy-safe fields are stored: city + an approximate
/// area label, never an exact address or precise coordinates.
class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.ageRange,
    required this.country,
    required this.city,
    required this.approximateArea,
    this.approxDistanceKm,
    this.profilePhotoUrl,
    this.bio = '',
    this.interests = const [],
    this.lookingFor = const [],
    required this.createdAt,
    this.hideExactLocation = true,
  });

  final String id;
  final String firstName;
  final AgeRange ageRange;
  final String country;
  final String city;

  /// Human-friendly approximate area, e.g. "Torre del Mar".
  final String approximateArea;

  /// Rough distance from the current user in km (display only, coarse).
  final double? approxDistanceKm;

  final String? profilePhotoUrl;
  final String bio;
  final List<String> interests; // interest ids
  final List<LookingFor> lookingFor;
  final DateTime createdAt;
  final bool hideExactLocation;

  String get ageLabel => ageRange.label;

  AppUser copyWith({
    String? firstName,
    AgeRange? ageRange,
    String? country,
    String? city,
    String? approximateArea,
    double? approxDistanceKm,
    String? profilePhotoUrl,
    String? bio,
    List<String>? interests,
    List<LookingFor>? lookingFor,
    bool? hideExactLocation,
  }) {
    return AppUser(
      id: id,
      firstName: firstName ?? this.firstName,
      ageRange: ageRange ?? this.ageRange,
      country: country ?? this.country,
      city: city ?? this.city,
      approximateArea: approximateArea ?? this.approximateArea,
      approxDistanceKm: approxDistanceKm ?? this.approxDistanceKm,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      lookingFor: lookingFor ?? this.lookingFor,
      createdAt: createdAt,
      hideExactLocation: hideExactLocation ?? this.hideExactLocation,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'firstName': firstName,
        'ageRange': ageRange.name,
        'country': country,
        'city': city,
        'approximateArea': approximateArea,
        'profilePhotoUrl': profilePhotoUrl,
        'bio': bio,
        'interests': interests,
        'lookingFor': lookingFor.map((e) => e.name).toList(),
        'createdAt': createdAt.toIso8601String(),
        'hideExactLocation': hideExactLocation,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'] as String,
        firstName: map['firstName'] as String,
        ageRange: AgeRange.fromName(map['ageRange'] as String? ?? 'a60to64'),
        country: map['country'] as String? ?? '',
        city: map['city'] as String? ?? '',
        approximateArea: map['approximateArea'] as String? ?? '',
        profilePhotoUrl: map['profilePhotoUrl'] as String?,
        bio: map['bio'] as String? ?? '',
        interests: (map['interests'] as List?)?.cast<String>() ?? const [],
        lookingFor: (map['lookingFor'] as List?)
                ?.cast<String>()
                .map(LookingFor.fromName)
                .toList() ??
            const [],
        createdAt:
            DateTime.tryParse(map['createdAt'] as String? ?? '') ??
                DateTime.now(),
        hideExactLocation: map['hideExactLocation'] as bool? ?? true,
      );
}

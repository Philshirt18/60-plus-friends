import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_user.dart';
import '../../core/models/interest.dart';
import '../../core/services/service_locator.dart';
import '../auth/auth_controller.dart';
import '../profile/profile_controller.dart' show resolveProfilePhoto;

/// Mutable draft profile assembled across onboarding steps.
class OnboardingDraft {
  OnboardingDraft({
    this.ageRange,
    this.country = 'Spain',
    this.city = '',
    this.approximateArea = '',
    List<String>? interests,
    List<LookingFor>? lookingFor,
    this.firstName = '',
    this.bio = '',
    this.photoUrl,
  })  : interests = interests ?? [],
        lookingFor = lookingFor ?? [];

  AgeRange? ageRange;
  String country;
  String city;
  String approximateArea;
  List<String> interests;
  List<LookingFor> lookingFor;
  String firstName;
  String bio;
  String? photoUrl;

  bool get locationValid =>
      country.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      approximateArea.trim().isNotEmpty;

  bool get profileValid => firstName.trim().isNotEmpty && ageRange != null;
}

class OnboardingController extends StateNotifier<OnboardingDraft> {
  OnboardingController(this._ref) : super(OnboardingDraft());
  final Ref _ref;

  void setAge(AgeRange age) => state = _clone()..ageRange = age;

  void setLocation({
    required String country,
    required String city,
    required String area,
  }) =>
      state = _clone()
        ..country = country
        ..city = city
        ..approximateArea = area;

  void toggleInterest(String id) {
    final next = _clone();
    if (next.interests.contains(id)) {
      next.interests.remove(id);
    } else {
      next.interests.add(id);
    }
    state = next;
  }

  void toggleLookingFor(LookingFor value) {
    final next = _clone();
    if (next.lookingFor.contains(value)) {
      next.lookingFor.remove(value);
    } else {
      next.lookingFor.add(value);
    }
    state = next;
  }

  void setProfile({String? firstName, String? bio, String? photoUrl}) {
    final next = _clone();
    if (firstName != null) next.firstName = firstName;
    if (bio != null) next.bio = bio;
    if (photoUrl != null) next.photoUrl = photoUrl;
    state = next;
  }

  OnboardingDraft _clone() => OnboardingDraft(
        ageRange: state.ageRange,
        country: state.country,
        city: state.city,
        approximateArea: state.approximateArea,
        interests: List.of(state.interests),
        lookingFor: List.of(state.lookingFor),
        firstName: state.firstName,
        bio: state.bio,
        photoUrl: state.photoUrl,
      );

  /// Persists the draft as the user's profile and refreshes the session.
  Future<void> finish() async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) throw StateError('Not signed in');
    final draft = state;

    // Upload a locally-picked photo to storage (when available).
    final photo = await resolveProfilePhoto(
      _ref,
      userId: uid,
      photoRef: draft.photoUrl,
    );

    final user = AppUser(
      id: uid,
      firstName: draft.firstName.trim(),
      ageRange: draft.ageRange ?? AgeRange.a60to64,
      country: draft.country.trim(),
      city: draft.city.trim(),
      approximateArea: draft.approximateArea.trim(),
      approxDistanceKm: 0,
      profilePhotoUrl: photo,
      bio: draft.bio.trim(),
      interests: draft.interests,
      lookingFor: draft.lookingFor,
      createdAt: DateTime.now(),
    );

    await _ref.read(dataRepositoryProvider).saveUser(user);
    _ref.invalidate(currentUserProvider);
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingDraft>(
        OnboardingController.new);

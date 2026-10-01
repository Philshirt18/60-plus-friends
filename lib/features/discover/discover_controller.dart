import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_user.dart';
import '../../core/models/social_models.dart';
import '../../core/services/matching.dart';
import '../../core/services/service_locator.dart';
import '../auth/auth_controller.dart';
import '../messages/messages_controller.dart' show matchesProvider;

/// Free-tier daily limit on "Interested" taps. Premium removes the cap.
const int kFreeDailyInterests = 10;

/// Loads and ranks discovery candidates for the current user.
final discoverProvider = FutureProvider<List<AppUser>>((ref) async {
  final me = await ref.watch(currentUserProvider.future);
  if (me == null) return [];
  final repo = ref.watch(dataRepositoryProvider);
  final candidates = await repo.discoverCandidates(me.id);
  return MatchScorer.rank(me, candidates);
});

/// Tracks how many "Interested" taps have been used today (session-scoped).
class DailyInterestCounter extends StateNotifier<int> {
  DailyInterestCounter() : super(0);
  void increment() => state = state + 1;
  void reset() => state = 0;
}

final dailyInterestCounterProvider =
    StateNotifierProvider<DailyInterestCounter, int>(
        (ref) => DailyInterestCounter());

class DiscoverController {
  DiscoverController(this._ref);
  final Ref _ref;

  /// Expresses interest. Returns a [Match] if it became mutual.
  ///
  /// Deliberately does NOT invalidate [discoverProvider]: the deck's local
  /// index already advances past this person, and refetching mid-deck would
  /// reshuffle/re-rank the list under the user's feet, making the card jump
  /// twice. The next natural refetch (revisiting Discover) already excludes
  /// anyone acted on, since that filtering happens server-side.
  Future<Match?> expressInterest(String targetUserId) async {
    final me = await _ref.read(currentUserProvider.future);
    if (me == null) return null;
    _ref.read(dailyInterestCounterProvider.notifier).increment();
    final match = await _ref.read(dataRepositoryProvider).expressInterest(
          fromUserId: me.id,
          toUserId: targetUserId,
        );
    if (match != null) _ref.invalidate(matchesProvider);
    return match;
  }

  Future<void> pass(String targetUserId) async {
    final me = await _ref.read(currentUserProvider.future);
    if (me == null) return;
    await _ref.read(dataRepositoryProvider).passUser(
          fromUserId: me.id,
          toUserId: targetUserId,
        );
  }
}

final discoverControllerProvider =
    Provider<DiscoverController>(DiscoverController.new);

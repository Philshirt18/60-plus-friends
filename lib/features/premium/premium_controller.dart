import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/service_locator.dart';
import '../../core/services/subscription_service.dart';

/// Streams entitlement changes, seeded with the current state.
final entitlementProvider = StreamProvider<EntitlementState>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.entitlementChanges();
});

/// Simple boolean: is the user premium right now?
final isPremiumProvider = Provider<bool>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  final streamed = ref.watch(entitlementProvider).valueOrNull;
  return (streamed ?? service.current).isPremium;
});

class PremiumController {
  PremiumController(this._ref);
  final Ref _ref;

  SubscriptionService get _service => _ref.read(subscriptionServiceProvider);

  Future<List<SubscriptionPackage>> packages() => _service.fetchPackages();

  Future<bool> purchase(SubscriptionPackage package) async {
    final state = await _service.purchase(package);
    return state.isPremium;
  }

  Future<bool> restore() async {
    final state = await _service.restore();
    return state.isPremium;
  }
}

final premiumControllerProvider =
    Provider<PremiumController>(PremiumController.new);

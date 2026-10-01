import 'dart:async';

/// Entitlement identifiers. `premium` unlocks the paid features.
class Entitlements {
  static const String premium = 'premium';
}

/// A purchasable package presented on the paywall.
class SubscriptionPackage {
  const SubscriptionPackage({
    required this.id,
    required this.title,
    required this.priceLabel,
    required this.period,
    this.highlighted = false,
  });

  final String id;
  final String title;
  final String priceLabel;
  final String period;
  final bool highlighted;
}

/// Raised when the user cancels a purchase, so the UI can quietly ignore it.
class PurchaseCancelled implements Exception {
  const PurchaseCancelled();
}

/// Current entitlement state derived from the store.
class EntitlementState {
  const EntitlementState({required this.isPremium});
  final bool isPremium;

  static const free = EntitlementState(isPremium: false);
  static const premium = EntitlementState(isPremium: true);
}

/// Abstraction over the subscription provider.
///
/// The MVP ships a [MockSubscriptionService]. To integrate RevenueCat, add
/// `purchases_flutter`, implement this interface with a
/// `RevenueCatSubscriptionService` (configure with your API key, read
/// `CustomerInfo.entitlements`, map offerings to [SubscriptionPackage]s), and
/// register it in the service locator. Entitlement checks in the UI stay the
/// same because they only depend on this abstraction.
abstract class SubscriptionService {
  Future<void> init({String? appUserId});
  Stream<EntitlementState> entitlementChanges();
  EntitlementState get current;

  Future<List<SubscriptionPackage>> fetchPackages();
  Future<EntitlementState> purchase(SubscriptionPackage package);
  Future<EntitlementState> restore();
}

/// In-memory subscription used for local development / demo. It fully models
/// premium state, purchase and restore so premium gating is real and testable.
class MockSubscriptionService implements SubscriptionService {
  final _controller = StreamController<EntitlementState>.broadcast();
  EntitlementState _state = EntitlementState.free;

  @override
  EntitlementState get current => _state;

  @override
  Future<void> init({String? appUserId}) async {}

  @override
  Stream<EntitlementState> entitlementChanges() => _controller.stream;

  @override
  Future<List<SubscriptionPackage>> fetchPackages() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [
      SubscriptionPackage(
        id: 'monthly',
        title: 'Monthly',
        priceLabel: '\$4.99',
        period: 'per month',
      ),
      SubscriptionPackage(
        id: 'annual',
        title: 'Yearly',
        priceLabel: '\$39.99',
        period: 'per year · save 33%',
        highlighted: true,
      ),
    ];
  }

  @override
  Future<EntitlementState> purchase(SubscriptionPackage package) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _state = EntitlementState.premium;
    _controller.add(_state);
    return _state;
  }

  @override
  Future<EntitlementState> restore() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _controller.add(_state);
    return _state;
  }
}

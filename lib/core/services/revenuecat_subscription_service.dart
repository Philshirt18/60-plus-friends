import 'dart:async';

import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import 'revenuecat_config.dart';
import 'subscription_service.dart';

/// Real subscription provider backed by RevenueCat.
///
/// Implements the same [SubscriptionService] abstraction the app already uses,
/// so the paywall, premium gating and entitlement checks work unchanged.
class RevenueCatSubscriptionService implements SubscriptionService {
  RevenueCatSubscriptionService();

  final _controller = StreamController<EntitlementState>.broadcast();
  EntitlementState _state = EntitlementState.free;

  /// Maps our display package id -> the underlying RevenueCat package so we
  /// can complete a purchase from a [SubscriptionPackage].
  final Map<String, Package> _packagesById = {};

  // Tracks the one in-flight/completed `Purchases.configure()` call so a
  // later `init(appUserId: ...)` (e.g. right after sign-up) always waits for
  // it instead of racing `Purchases.logIn` against a `configure` that is
  // still running on the native side — doing so previously crashed the
  // RevenueCat iOS SDK with a native assertion failure.
  Future<void>? _configureFuture;
  String? _configuredAppUserId;

  @override
  EntitlementState get current => _state;

  @override
  Stream<EntitlementState> entitlementChanges() => _controller.stream;

  @override
  Future<void> init({String? appUserId}) {
    final inFlight = _configureFuture;
    if (inFlight == null) {
      final future = _configure(appUserId);
      _configureFuture = future;
      return future;
    }
    return inFlight.then((_) => _logIn(appUserId));
  }

  Future<void> _configure(String? appUserId) async {
    await Purchases.setLogLevel(LogLevel.warn);

    final config = PurchasesConfiguration(RevenueCatConfig.apiKey);
    if (appUserId != null) config.appUserID = appUserId;
    await Purchases.configure(config);
    _configuredAppUserId = appUserId;

    // Seed current entitlement and listen for changes.
    try {
      _updateFrom(await Purchases.getCustomerInfo());
    } catch (_) {/* offline / not ready yet */}

    Purchases.addCustomerInfoUpdateListener(_updateFrom);
  }

  Future<void> _logIn(String? appUserId) async {
    if (appUserId == null || appUserId == _configuredAppUserId) return;
    try {
      await Purchases.logIn(appUserId);
      _configuredAppUserId = appUserId;
    } catch (_) {/* ignore */}
  }

  void _updateFrom(CustomerInfo info) {
    final isPremium =
        info.entitlements.active.containsKey(Entitlements.premium);
    _state = EntitlementState(isPremium: isPremium);
    _controller.add(_state);
  }

  @override
  Future<List<SubscriptionPackage>> fetchPackages() async {
    final offerings = await Purchases.getOfferings();
    final Offering? offering = RevenueCatConfig.offeringId != null
        ? offerings.all[RevenueCatConfig.offeringId]
        : offerings.current;

    if (offering == null) return const [];

    _packagesById.clear();
    final result = <SubscriptionPackage>[];

    for (final pkg in offering.availablePackages) {
      _packagesById[pkg.identifier] = pkg;
      result.add(_toDisplay(pkg));
    }

    // Put the annual/longest option first as the highlighted "best value".
    result.sort((a, b) => b.highlighted ? 1 : -1);
    return result;
  }

  SubscriptionPackage _toDisplay(Package pkg) {
    final product = pkg.storeProduct;
    final isAnnual = pkg.packageType == PackageType.annual;
    final title = switch (pkg.packageType) {
      PackageType.annual => 'Yearly',
      PackageType.monthly => 'Monthly',
      PackageType.weekly => 'Weekly',
      PackageType.lifetime => 'Lifetime',
      _ => product.title,
    };
    final period = switch (pkg.packageType) {
      PackageType.annual => 'per year',
      PackageType.monthly => 'per month',
      PackageType.weekly => 'per week',
      PackageType.lifetime => 'one-time',
      _ => '',
    };

    return SubscriptionPackage(
      id: pkg.identifier,
      title: title,
      priceLabel: product.priceString,
      period: period,
      highlighted: isAnnual,
    );
  }

  @override
  Future<EntitlementState> purchase(SubscriptionPackage package) async {
    final rcPackage = _packagesById[package.id];
    if (rcPackage == null) {
      // Packages not loaded yet; refresh and retry once.
      await fetchPackages();
    }
    final target = _packagesById[package.id];
    if (target == null) {
      throw StateError('Package "${package.id}" is not available.');
    }

    try {
      final result =
          await Purchases.purchase(PurchaseParams.package(target));
      _updateFrom(result.customerInfo);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        throw const PurchaseCancelled();
      }
      rethrow;
    }
    return _state;
  }

  @override
  Future<EntitlementState> restore() async {
    final info = await Purchases.restorePurchases();
    _updateFrom(info);
    return _state;
  }
}

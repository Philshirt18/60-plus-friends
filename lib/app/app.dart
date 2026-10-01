import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/consent/consent_controller.dart';
import '../features/consent/privacy_notice.dart';
import 'router.dart' show routerProvider, rootNavigatorKey;

class SixtyPlusApp extends ConsumerWidget {
  const SixtyPlusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '60+ Friends',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        // Clamp text scaling so very large system fonts don't break layouts,
        // while still allowing generous scaling for accessibility.
        final mq = MediaQuery.of(context);
        final clamped = mq.textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.4,
        );
        return MediaQuery(
          data: mq.copyWith(textScaler: clamped),
          child: _ConsentGate(child: child!),
        );
      },
    );
  }
}

/// Shows the first-run privacy notice once, then never again.
class _ConsentGate extends ConsumerStatefulWidget {
  const _ConsentGate({required this.child});
  final Widget child;

  @override
  ConsumerState<_ConsentGate> createState() => _ConsentGateState();
}

class _ConsentGateState extends ConsumerState<_ConsentGate> {
  bool _showing = false;
  late final GoRouter _router;

  // The notice must not cover the splash or the intro: the intro would sit
  // hidden underneath it, and when the intro auto-advances the sheet gets
  // carried away with its page — dismissed without the user ever tapping
  // "Got it", so it reappears on every launch.
  static const _deferredOn = {'/splash', '/intro'};

  @override
  void initState() {
    super.initState();
    _router = ref.read(routerProvider);
    _router.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShow(ref.read(consentNeededProvider));
    });
  }

  bool get _deferred => _deferredOn
      .contains(_router.routerDelegate.currentConfiguration.uri.path);

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(consentNeededProvider, (_, needed) {
      _maybeShow(needed);
    });
    // Also handle the case where it's already needed on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShow(ref.read(consentNeededProvider));
    });
    return widget.child;
  }

  Future<void> _maybeShow(bool needed) async {
    if (!needed || _showing || !mounted || _deferred) return;
    // Present using the root navigator's context so the sheet sits under a
    // Navigator (the MaterialApp.builder context does not).
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;
    _showing = true;
    await showPrivacyNotice(navContext);
    if (mounted) {
      await ref.read(consentNeededProvider.notifier).acknowledge();
    }
    _showing = false;
  }
}

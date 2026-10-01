import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/activity.dart';
import '../core/models/app_user.dart';
import '../core/models/social_models.dart';
import '../features/activities/activities_screen.dart';
import '../features/activities/activity_detail_screen.dart';
import '../features/activities/create_activity_screen.dart';
import '../features/activities/my_activities_screen.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/intro_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/discover/discover_screen.dart';
import '../features/discover/match_screen.dart';
import '../features/discover/person_detail_screen.dart';
import '../features/messages/conversation_screen.dart';
import '../features/messages/matches_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/premium/premium_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/safety/block_user_screen.dart';
import '../features/safety/report_user_screen.dart';
import '../features/settings/content_page.dart';
import '../features/settings/invite_screen.dart';
import '../features/settings/notifications_settings_screen.dart';
import '../features/settings/privacy_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import 'home_shell.dart';

/// Root navigator key, also used to present app-level overlays (e.g. the
/// first-run privacy notice) from a context that sits under the Navigator.
final rootNavigatorKey = GlobalKey<NavigatorState>();
final _rootKey = rootNavigatorKey;

/// Bridges Riverpod session status into a Listenable for go_router refresh.
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(this._ref) {
    _sub = _ref.listen<SessionStatus>(
      sessionStatusProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }
  final Ref _ref;
  late final ProviderSubscription<SessionStatus> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionListenable(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/discover',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(sessionStatusProvider);
      final loc = state.matchedLocation;

      const authLocations = {
        '/intro',
        '/welcome',
        '/login',
        '/register',
        '/forgot-password',
      };

      switch (status) {
        case SessionStatus.loading:
          return '/splash';
        case SessionStatus.signedOut:
          // Any arrival at a non-auth route while signed out goes through
          // the intro first (cold start via /splash, or signing out from
          // deep inside the app) — /intro itself hands off to /welcome.
          return authLocations.contains(loc) ? null : '/intro';
        case SessionStatus.needsOnboarding:
          return loc == '/onboarding' ? null : '/onboarding';
        case SessionStatus.ready:
          if (loc == '/splash' ||
              loc == '/onboarding' ||
              authLocations.contains(loc)) {
            return '/discover';
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/intro',
        builder: (_, __) => const IntroScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),

      // Main tabbed shell.
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/discover',
              builder: (_, __) => const DiscoverScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/activities',
              builder: (_, __) => const ActivitiesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/matches',
              builder: (_, __) => const MatchesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ]),
        ],
      ),

      // Top-level (full screen) routes.
      GoRoute(
        path: '/person',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            PersonDetailScreen(person: state.extra as AppUser),
      ),
      GoRoute(
        path: '/match',
        parentNavigatorKey: _rootKey,
        builder: (_, state) {
          final data = state.extra as Map<String, dynamic>;
          return MatchScreen(
            match: data['match'] as Match,
            person: data['person'] as AppUser,
          );
        },
      ),
      GoRoute(
        path: '/conversation',
        parentNavigatorKey: _rootKey,
        builder: (_, state) {
          final data = state.extra as Map<String, dynamic>;
          return ConversationScreen(
            conversationId: data['conversationId'] as String,
            person: data['person'] as AppUser,
          );
        },
      ),
      GoRoute(
        path: '/activities/mine',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const MyActivitiesScreen(),
      ),
      GoRoute(
        path: '/activities/create',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CreateActivityScreen(),
      ),
      GoRoute(
        path: '/activities/edit',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            CreateActivityScreen(editing: state.extra as Activity),
      ),
      GoRoute(
        path: '/activities/detail',
        parentNavigatorKey: _rootKey,
        builder: (_, state) {
          final activity = state.extra as Activity;
          return ActivityDetailScreen(activityId: activity.id);
        },
      ),
      GoRoute(
        path: '/report',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            ReportUserScreen(person: state.extra as AppUser),
      ),
      GoRoute(
        path: '/block',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            BlockUserScreen(person: state.extra as AppUser),
      ),
      GoRoute(
        path: '/premium',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/privacy',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/notifications-settings',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const NotificationsSettingsScreen(),
      ),
      GoRoute(
        path: '/invite',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const InviteScreen(),
      ),
      GoRoute(
        path: '/guidelines',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => LegalContent.communityGuidelines,
      ),
      GoRoute(
        path: '/terms',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => LegalContent.terms,
      ),
      GoRoute(
        path: '/privacy-policy',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => LegalContent.privacyPolicy,
      ),
    ],
  );
});

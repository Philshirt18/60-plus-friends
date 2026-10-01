# 60+ Friends

**Meet people nearby. Share interests. Enjoy life together.**

A polished Flutter app for people aged 60+ to make new local connections
through shared interests and real-world activities. It is built around
friendship and community — **not** dating.

> Life doesn't get smaller after 60. Your social world can get bigger.

---

## Status

- Runs today with zero backend setup using in-memory mock services and seed
  data, so the full product loop is demoable immediately.
- `flutter analyze` — no issues. `flutter test` — passing.
- Firebase, RevenueCat and OneSignal are integrated behind clean abstractions
  and can be switched on without touching feature/UI code.

## Run

```bash
flutter pub get
flutter run
```

Sign up with any email/password (min 6 characters), complete onboarding, and
you'll land in Discover with seeded people and activities near "Torre del Mar".

## Architecture

Feature-based, with Riverpod for state and go_router for navigation.

```
lib/
  app/            App root, router, bottom-nav shell
  core/
    models/       AppUser, Interest, Activity, Match, Message, Report, Block ...
    services/     Abstractions + mock implementations + service_locator
    theme/        Colors, spacing, typography (accessible 60+ design system)
    utils/        Validators, date formatting
    widgets/      Shared accessible widgets
  features/
    auth/         Welcome, login, register, recovery, session/auth state
    onboarding/   6-step onboarding (age, location, interests, looking-for, profile)
    discover/     Discovery deck, matching, person detail, connection screen
    messages/     Matches list, conversation/chat
    activities/   Discovery + filters, detail, create, my activities
    profile/      Profile + edit
    premium/      Paywall + entitlement state (RevenueCat abstraction)
    safety/       Report + block
    settings/     Settings, privacy, notifications, legal, invite
    splash/       Splash
```

### Swappable backends

All integrations sit behind interfaces registered in
`lib/core/services/service_locator.dart`:

| Concern        | Interface              | Mock (default)              | Production target |
|----------------|------------------------|-----------------------------|-------------------|
| Auth           | `AuthService`          | `MockAuthService`           | Firebase Auth     |
| Data           | `DataRepository`       | `InMemoryDataRepository`    | Firestore         |
| Subscriptions  | `SubscriptionService`  | `MockSubscriptionService`   | RevenueCat        |
| Notifications  | `NotificationService`  | `MockNotificationService`   | OneSignal         |

UI and controllers depend only on the interfaces, so switching to a real
backend means implementing the interface and registering it in one place.

## Matching algorithm (MVP)

Simple and transparent (`lib/core/services/matching.dart`), easy to tweak:

- +10 per shared interest
- +20 same city
- +10 nearby (≤ 10 km)
- +5 similar age range
- +10 per shared "looking for" preference

Candidates are sorted by descending score. No AI. Covered by unit tests.

## Enabling the real integrations

Uncomment the relevant packages in `pubspec.yaml`, then:

**Firebase**
1. `dart pub global activate flutterfire_cli && flutterfire configure`
2. Initialise in `main.dart` before `runApp`.
3. Implement `FirebaseAuthService` / `FirestoreDataRepository` and register
   them in the service locator.

**RevenueCat**
1. Add `purchases_flutter`.
2. Implement `RevenueCatSubscriptionService` (configure API key, map offerings
   to `SubscriptionPackage`, read the `premium` entitlement).
3. Register it in the service locator. The paywall and premium gating are
   already wired to the abstraction.

**OneSignal**
1. Add `onesignal_flutter`.
2. Implement `OneSignalNotificationService` (init with App ID, `login`
   external id on sign-in, map notification types to tags/segments).
3. Register it in the service locator. Notification preferences UI already
   calls `updatePreferences`.

## Product principles honoured

- Friendship-first language and visuals; no dating aesthetics or romantic
  copy on the connection screen.
- Accessible: large type, high contrast, 56dp+ touch targets, icon **and**
  text navigation, clamped text scaling, plain language.
- Privacy: only city + approximate area stored; exact address/location/email/
  phone never shown. Block, report, privacy controls and account deletion.
- Generous free tier; premium is additive, not a paywall on core social use.
- Empty states always encourage the next real-world action.
```

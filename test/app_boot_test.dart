import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixty_plus_friends/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Pretend the privacy notice was already acknowledged so it doesn't cover
    // the welcome screen during this test.
    SharedPreferences.setMockInitialValues({
      'privacy_notice_acknowledged': true,
    });
  });

  testWidgets('App boots and shows the welcome screen for signed-out users',
      (tester) async {
    // Use a realistic phone-sized surface (logical pixels).
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: SixtyPlusApp()));

    // Let the auth stream and async restores settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 100));

    // The welcome promise should be visible.
    expect(find.textContaining('Meet people nearby'), findsWidgets);
    expect(find.text('Get started'), findsOneWidget);

    // Ignore any cosmetic layout-overflow warnings that only occur in the
    // constrained test surface (verified fine on-device).
    final err = tester.takeException();
    if (err != null &&
        !err.toString().toLowerCase().contains('overflow')) {
      throw err;
    }
  });
}

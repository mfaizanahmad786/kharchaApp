import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/theme/app_theme.dart';
import 'package:kharcha/core/widgets/rolling_amount.dart';
import 'package:kharcha/data/prefs/settings_store.dart';
import 'package:kharcha/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_fonts.dart';

/// The odometer roll on the balance and the month's spending. Two of these
/// are regression cover: the controller was once a `late final` whose
/// initialiser could run from dispose() on any build that returned early
/// (hidden amounts), which throws when the element is already deactivated.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsStore settings;

  setUpAll(loadAppFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = await SettingsStore.create();
  });

  Future<void> pump(
    WidgetTester tester,
    int paisa, {
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsStoreProvider.overrideWithValue(settings)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(disableAnimations: reduceMotion),
              child: Center(
                child: RollingAmount(
                  paisa,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a settled figure is one Text', (t) async {
    await pump(t, 73819683);
    await t.pumpAndSettle();

    expect(find.text('₨7,38,196.83', findRichText: true), findsOneWidget);
  });

  testWidgets('a changed digit shows both glyphs mid-roll, then settles', (
    t,
  ) async {
    await pump(t, 73819683);
    await t.pumpAndSettle();

    // ₨7,38,196.83 -> ₨7,38,195.83: one digit moves.
    await pump(t, 73819583);
    await t.pump(const Duration(milliseconds: 200));

    // Mid-roll the figure is split into glyphs, with the outgoing 6 and the
    // incoming 5 both on screen.
    expect(find.text('₨7,38,196.83', findRichText: true), findsNothing);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    await t.pumpAndSettle();
    expect(find.text('₨7,38,195.83', findRichText: true), findsOneWidget);
  });

  testWidgets('a rise brings the new digit up from below', (t) async {
    await pump(t, 73819583);
    await t.pumpAndSettle();

    // ...195.83 -> ...196.83: the 5 leaves through the top and the 6 rises
    // into its place, so mid-roll the 6 sits below the 5.
    await pump(t, 73819683);
    await t.pump(const Duration(milliseconds: 200));

    expect(
      t.getTopLeft(find.text('6')).dy,
      greaterThan(t.getTopLeft(find.text('5')).dy),
    );
  });

  testWidgets('a fall brings the new digit down from above', (t) async {
    await pump(t, 73819683);
    await t.pumpAndSettle();

    await pump(t, 73819583);
    await t.pump(const Duration(milliseconds: 200));

    expect(
      t.getTopLeft(find.text('5')).dy,
      lessThan(t.getTopLeft(find.text('6')).dy),
    );
  });

  testWidgets('reduced motion updates without rolling', (t) async {
    await pump(t, 73819683, reduceMotion: true);
    await t.pumpAndSettle();

    await pump(t, 73819583, reduceMotion: true);
    await t.pump(const Duration(milliseconds: 200));

    expect(find.text('₨7,38,195.83', findRichText: true), findsOneWidget);
  });

  testWidgets('a change of length swaps rather than rolls', (t) async {
    await pump(t, 100000);
    await t.pumpAndSettle();

    await pump(t, 99000);
    await t.pump(const Duration(milliseconds: 200));

    expect(find.text('₨990.00', findRichText: true), findsOneWidget);
  });

  testWidgets('hidden amounts build and dispose cleanly', (t) async {
    await settings.setHideAmounts(true);
    await pump(t, 73819683);
    await t.pumpAndSettle();

    expect(find.text('₨••••'), findsOneWidget);

    // Tearing the widget down is the half that used to throw.
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpAndSettle();
  });
}

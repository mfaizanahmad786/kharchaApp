import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/data/prefs/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingsStore> freshStore([Map<String, Object> seed = const {}]) async {
    SharedPreferences.setMockInitialValues(seed);
    return SettingsStore.create();
  }

  group('appearance', () {
    test('follows the system until someone chooses otherwise', () async {
      expect((await freshStore()).themeMode, ThemeMode.system);
    });

    test('a choice survives being read back', () async {
      final store = await freshStore();
      for (final mode in ThemeMode.values) {
        await store.setThemeMode(mode);
        expect(store.themeMode, mode);
      }
    });

    test('an unrecognised stored value falls back to the system', () async {
      // A value written by an older or newer build must not strand someone
      // on an appearance the app cannot resolve.
      final store = await freshStore({'theme_mode': 'sepia'});
      expect(store.themeMode, ThemeMode.system);
    });
  });

  test('the other preferences keep their defaults', () async {
    final store = await freshStore();
    expect(store.hideAmounts, isFalse);
    expect(store.budgetAlerts, isTrue);
  });
}

# Kharcha

An offline-first personal expense tracker for Android, built in Flutter.
Everything lives in a SQLite file on the handset — there is no backend, no
account, and no `INTERNET` permission in the release manifest.

<!-- Screens: Home, Report, Plan, Settings -->

## Running it

The toolchain is the stock Flutter one; no extra setup beyond the Android SDK.

```bash
flutter pub get
flutter run                     # debug, on a connected device or emulator
flutter test                    # 35 unit + widget tests
flutter build apk --release     # signed with the debug key — see Shipping
```

Requires Flutter 3.38+ (Dart 3.10) and JDK 17. `minSdk` is 24, `targetSdk` 36.

## What is in it

**Home** — a violet balance header over a sheet of summary cards, then the
month's transactions grouped by day, each row carrying the running balance at
that point in time.

**Report** — expenses or income for the month as a donut or a daily bar chart,
with a per-category breakdown showing each category's share and its change
against the previous calendar month. Both charts are hand-drawn with
`CustomPainter`: the comps call for rounded arc caps, gaps between slices and a
hatched "other" wedge, none of which a charting package does out of the box.

**Plan** — savings goals and monthly budgets. A goal's bar fills to what you
have actually saved and hatches the gap to where the schedule says you should
be, with an off-target warning when you fall behind. Budgets show a ring that
turns amber at their alert threshold and red once the limit is passed.

**Settings** — profile, a global "hide amounts" mask, budget alerts, PIN and
biometric app lock, and category / account management.

Adding or editing a transaction uses a custom numeric keypad so the category
picker and the running total stay visible while you type.

## How it is put together

```
lib/
  core/        theme, money and date helpers, shared widgets
  data/        models, SQLite schema + seed, preference stores, repository
  providers/   Riverpod providers and the write-side actions
  features/    home · report · plan · settings · transaction · lock · shell
```

- **State** is Riverpod 3. `sqflite` has no change stream, so every write bumps
  a revision counter that each derived provider watches — one place to
  invalidate, and no screen can go stale.
- **Money** is stored as an integer number of paisa, never a double, so no
  rounding error can reach a balance. It is rendered with Pakistani digit
  grouping (`2,95,776`) and the two-tone rupee/paisa treatment from the comps.
- **Icons** are persisted by name against a fixed table rather than by code
  point. Building `IconData` from a stored int would defeat Flutter's icon
  tree-shaking; keeping the table lets the release build drop 99% of the
  Material icon font.
- **Inter** is bundled as an asset rather than fetched at runtime, so the app
  renders identically with no network.
- The data layer takes an injectable `DatabaseFactory`, which is how the
  repository tests run against an in-memory database.

## Decisions worth knowing

- **Currency is PKR only.** The comps show dollars; the app shows `₨`, per the
  brief. There is no conversion logic anywhere.
- **First launch is seeded** with six months of plausible history from a fixed
  random seed, so the app opens on something that looks like the designs
  instead of five empty screens. *Settings → Reset sample data* rebuilds it and
  *Delete all transactions* clears it.
- **Settings and the add/edit screens had no comps**, so they are designed in
  the same language as the three that did.
- **No CSV export and no recurring transactions** — both were explicitly out of
  scope.

## Shipping

The release build is currently signed with the debug key so that
`flutter run --release` works out of the box. Before publishing, create a
keystore and a `key.properties`, then point `signingConfigs.release` at it;
`key.properties` and `*.jks` are already in `.gitignore`.

`flutter build apk --release` produces a universal APK carrying three ABIs.
`flutter build apk --split-per-abi` (or an app bundle) is much smaller per
device.

## Tests

```
test/money_test.dart        formatting, grouping, parsing, compact forms
test/repository_test.dart   balances, running totals, breakdowns, budget
                            thresholds, goal contributions — on a real
                            in-memory SQLite database
test/home_screen_test.dart  Home layout, including regression guards for two
                            bugs that rendered the screen blank or invisible
```

Widget tests load the bundled Inter font: the default test font measures every
glyph as a square, which invents overflows the real app never has.

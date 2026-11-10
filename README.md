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
flutter test                    # 41 unit + widget tests
flutter build apk --release     # signed with the debug key — see Shipping
```

Requires Flutter 3.38+ (Dart 3.10) and JDK 17. `minSdk` is 24, `targetSdk` 36.

## What is in it

**Home** — a green balance header over a sheet of summary cards (In and Out
for the month), then the month's transactions grouped by day, each row carrying
the running balance at that point in time.

**Report** — expenses or income for the month as a donut or a daily bar chart,
with a per-category breakdown showing each category's share and its change
against the previous calendar month. Both charts are hand-drawn with
`CustomPainter`: the comps call for rounded arc caps, gaps between slices and a
hatched "other" wedge, none of which a charting package does out of the box.

**Plan** — savings goals and monthly budgets. One goal is pinned and featured
at the top; its bar fills to what you have actually saved and hatches the gap
to where the schedule says you should be, with an off-target warning when you
fall behind. Budgets show a ring that turns amber at their alert threshold and
red once the limit is passed, and say so in words as well as colour.

**Settings** — profile, a global "hide amounts" mask, budget alerts, PIN and
biometric app lock, and category / account management.

Everything is offline. There is no `INTERNET` permission in the release
manifest, so the app cannot phone home even by accident — your ledger
never leaves the handset.

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
- **Plus Jakarta Sans** is bundled as static 400–800 cuts, instanced from the
  variable font so `fontWeight` resolves without `fontVariations`. It is an
  asset rather than a runtime fetch: `google_fonts` would have to download the
  face, and this app declares no `INTERNET` permission, so it would silently
  fall back to Roboto.
- **Both appearances** follow the system setting. A `static const` cannot
  adapt, so every colour whose value depends on the surface behind it lives in
  an `AppPalette` theme extension read as `context.palette`; `AppColors` keeps
  only what does not change. Every dark foreground clears 4.5:1 against both
  the page and the card, and elevation reads through lightness rather than
  shadow.
- The data layer takes an injectable `DatabaseFactory`, which is how the
  repository tests run against an in-memory database.

## The data model

Five tables in one SQLite file, `kharcha.db`, currently at schema version 2.

| Table | Holds |
| --- | --- |
| `accounts` | where money sits: name, glyph, colour, opening balance |
| `categories` | what money is for, each typed income or expense |
| `txns` | one amount, its type, its category and account, a date, a note and tags |
| `budgets` | a monthly ceiling, optionally scoped to one category, with an alert threshold |
| `goals` | a savings target, what has been put aside, an optional deadline, and whether it is pinned |

Three things are worth knowing before changing any of it:

- **Amounts are integers of paisa**, never doubles. `Money` owns the
  conversion in both directions, so no rounding error can reach a balance.
- **A transaction's `amount` is always positive**; `type` carries the
  direction, and `Txn.signed` is the only place that applies the sign.
- **A category cannot be deleted while transactions point at it.** The
  foreign key is `ON DELETE RESTRICT` and the repository checks first, so the
  UI can say so rather than fail.

`txns` is indexed on date, category and account, which is what every screen
reads it by. Schema changes go in `_migrate`; version 2 added the goal
`pinned` column and pinned whichever goal already sorted first, so an
upgrade keeps a featured goal instead of suddenly having none.

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

## Accessibility

Contrast figures below are WCAG ratios computed from the tokens, not eyeballed
from a screenshot.

- **Contrast.** Every foreground clears its threshold in both appearances —
  4.5:1 for text up to 17pt, 3:1 for larger or bold. The header gradient is
  deliberately deeper than the brand ramp used on white, because white 16pt
  text could not carry 4.5:1 over the lighter greens; the worst stop is now
  4.74:1. In dark, every foreground clears 4.5:1 against both the page and
  the card.
- **Targets.** Controls keep their drawn size but sit in a hit area of at
  least 48dp, which is Material's floor and above Apple's 44.
- **Never colour alone.** A tripped budget carries an icon and the words
  "Near limit" or "Over limit", not just an amber ring. Money in and out are
  separated by sign as well as hue.
- **Labels.** Icon-only controls carry a tooltip or a semantic label, so
  TalkBack announces them.
- **Appearance** follows the system setting by default. Settings also offers
  System / Light / Dark for anyone who wants the app to differ from their
  phone; leaving it on System is what `dark-mode.md` asks for, and that is
  the default.

Two known gaps, both deliberate rather than overlooked:

- Text scaling is capped at 1.2x in `app.dart`. Lifting the cap is one line;
  making every layout survive 2x is the real work, and the transactions
  header is the first thing that collides.
- Screen-reader coverage is partial. Home's controls are named; the other
  screens have not been walked end to end.

## What it does not do

Worth knowing before you rely on it.

- **No transfers between accounts.** A transaction is money in or money out,
  so moving cash into the bank has to be recorded as an expense on one and
  income on the other, which overstates both of the month's totals.
- **No export or import.** The ledger is a SQLite file inside the app's
  sandbox and there is no way to get it out from inside the app. The manifest
  does not configure backup either way, so Android's default applies — which
  depends on the device's own backup settings and is not something to count
  on. Losing the handset means losing the data.
- **No recurring transactions.** The salary and rent in the sample data are
  ordinary rows written once, not a rule that keeps firing.
- **One currency.** Amounts are Pakistani rupees throughout, with no
  conversion anywhere.
- **Deleting a transaction is confirmed but not reversible.** There is no
  undo.

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
test/money_test.dart              formatting, grouping, parsing, compact forms
test/repository_test.dart         balances, running totals, breakdowns, budget
                                  thresholds, goal pinning and contributions —
                                  on a real in-memory SQLite database
test/home_screen_test.dart        Home layout, including regression guards for
                                  two bugs that rendered the screen blank or
                                  invisible
test/text_prompt_dialog_test.dart a dialog that outlives its own controller
```

Widget tests load the bundled font: the default test font measures every glyph
as a square, which invents overflows the real app never has.

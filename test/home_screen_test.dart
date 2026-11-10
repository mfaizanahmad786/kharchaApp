import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/theme/app_theme.dart';
import 'package:kharcha/data/models/models.dart';
import 'package:kharcha/data/prefs/settings_store.dart';
import 'package:kharcha/data/repository/finance_repository.dart';
import 'package:kharcha/features/home/home_screen.dart';
import 'package:kharcha/features/home/widgets/home_header.dart';
import 'package:kharcha/features/home/widgets/transaction_tile.dart';
import 'package:kharcha/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_fonts.dart';

/// These exercise the Home layout, so the data providers are stubbed rather
/// than driven off sqflite: the widget binding's fake clock cannot advance the
/// database's real async I/O. Database behaviour is covered in
/// repository_test.dart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const account = Account(
    id: 'acc',
    name: 'Cash',
    iconName: 'cash',
    colorValue: 0xFF8B5CF6,
    openingBalance: 0,
  );
  const category = Category(
    id: 'cafe',
    name: 'Cafes',
    iconName: 'cafe',
    colorValue: 0xFF4CBF7F,
    type: TxType.expense,
  );

  final today = DateTime.now();
  final view = TxnView(
    txn: Txn(
      id: 't1',
      amount: 245100,
      type: TxType.expense,
      categoryId: category.id,
      accountId: account.id,
      date: today,
    ),
    category: category,
    account: account,
    runningBalance: 73819683,
  );

  late SettingsStore settings;

  setUpAll(loadAppFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = await SettingsStore.create();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    // A phone-sized surface: the default 800x600 leaves the transaction list
    // below the fold, and slivers off-screen are never built.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(settings),
          balanceProvider.overrideWith((ref) => 73819683),
          weekDeltaProvider.overrideWith((ref) => 8170000),
          monthTotalsProvider.overrideWith(
            (ref) => const Totals(income: 42788000, expense: 21624577),
          ),
          monthSpendProvider.overrideWith(
            (ref) => (current: 21624577, previous: 18000000),
          ),
          budgetAlertsProvider.overrideWith((ref) => const <BudgetStatus>[]),
          groupedTransactionsProvider.overrideWith(
            (ref) => [
              (
                day: DateTime(today.year, today.month, today.day),
                net: -245100,
                items: [view],
              ),
            ],
          ),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the header, the month spend and transactions', (
    t,
  ) async {
    await pumpHome(t);

    expect(find.text('Current Balance'), findsOneWidget);
    expect(find.text('Your Money'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Spent this month'), findsOneWidget);
    expect(find.byType(TransactionTile), findsOneWidget);
    expect(find.text('Cafes'), findsOneWidget);
  });

  testWidgets('the header occupies real space', (t) async {
    await pumpHome(t);

    // Regression guard: an unbounded cross axis inside a sliver once collapsed
    // this entire screen to nothing, without throwing anything.
    final size = t.getSize(find.byType(HomeHeader));
    expect(size.height, greaterThan(200));
    expect(size.width, greaterThan(0));
  });

  testWidgets('section titles inherit a visible colour', (t) async {
    await pumpHome(t);

    // The theme once replaced rather than merged its text styles, which
    // dropped the colour and painted every title white on white.
    final element = t.element(find.text('Your Money'));
    final widget = t.widget<Text>(find.text('Your Money'));
    final colour =
        widget.style?.color ?? DefaultTextStyle.of(element).style.color;
    expect(colour, isNotNull);
    expect(colour, isNot(Colors.white));
  });

  testWidgets('amounts are formatted with South-Asian grouping', (t) async {
    await pumpHome(t);

    expect(find.textContaining('7,38,196', findRichText: true), findsWidgets);
  });

  testWidgets('hiding amounts masks every figure', (t) async {
    await settings.setHideAmounts(true);
    await pumpHome(t);

    expect(find.textContaining('7,38,196', findRichText: true), findsNothing);
    expect(find.textContaining('••••'), findsWidgets);
  });
}

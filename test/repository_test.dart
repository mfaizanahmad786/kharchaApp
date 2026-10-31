import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/data/db/app_database.dart';
import 'package:kharcha/data/models/models.dart';
import 'package:kharcha/data/repository/finance_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase db;
  late FinanceRepository repo;

  // A fixed month so the windows in these tests never depend on "now".
  final june = DateTime(2026, 6);
  final juneEnd = DateTime(2026, 7).subtract(const Duration(milliseconds: 1));
  final may = DateTime(2026, 5);

  setUp(() async {
    db = await AppDatabase.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
      seed: false,
    );
    repo = FinanceRepository(db);

    await repo.upsertAccount(
      const Account(
        id: 'acc',
        name: 'Cash',
        iconName: 'cash',
        colorValue: 0xFF000000,
        openingBalance: 100000, // ₨1,000
      ),
    );
    await repo.upsertCategory(
      const Category(
        id: 'food',
        name: 'Food',
        iconName: 'cafe',
        colorValue: 0xFF000000,
        type: TxType.expense,
      ),
    );
    await repo.upsertCategory(
      const Category(
        id: 'travel',
        name: 'Travel',
        iconName: 'travel',
        colorValue: 0xFF000000,
        type: TxType.expense,
      ),
    );
    await repo.upsertCategory(
      const Category(
        id: 'pay',
        name: 'Salary',
        iconName: 'salary',
        colorValue: 0xFF000000,
        type: TxType.income,
      ),
    );
  });

  tearDown(() => db.close());

  Future<void> add(int amount, TxType type, String cat, DateTime date) =>
      repo.addTransaction(
        amount: amount,
        type: type,
        categoryId: cat,
        accountId: 'acc',
        date: date,
      );

  group('balance', () {
    test('is the opening balance plus the signed transaction total', () async {
      await add(50000, TxType.income, 'pay', DateTime(2026, 6, 2));
      await add(20000, TxType.expense, 'food', DateTime(2026, 6, 3));

      expect(await repo.currentBalance(), 100000 + 50000 - 20000);
    });

    test(
      'an amount is stored as a magnitude whatever sign is passed',
      () async {
        await repo.addTransaction(
          amount: -7500,
          type: TxType.expense,
          categoryId: 'food',
          accountId: 'acc',
          date: DateTime(2026, 6, 4),
        );
        final txns = await repo.transactions();
        expect(txns.single.amount, 7500);
        expect(txns.single.signed, -7500);
      },
    );
  });

  group('totals', () {
    test('separates income from expense inside the window', () async {
      await add(50000, TxType.income, 'pay', DateTime(2026, 6, 2));
      await add(20000, TxType.expense, 'food', DateTime(2026, 6, 3));
      await add(99999, TxType.expense, 'food', DateTime(2026, 5, 3)); // outside

      final t = await repo.totals(june, juneEnd);
      expect(t.income, 50000);
      expect(t.expense, 20000);
      expect(t.net, 30000);
    });

    test('includes transactions sitting exactly on the window edges', () async {
      await add(1000, TxType.expense, 'food', june);
      await add(2000, TxType.expense, 'food', juneEnd);

      expect((await repo.totals(june, juneEnd)).expense, 3000);
    });
  });

  group('hydrate', () {
    test('threads a running balance and returns newest first', () async {
      await add(50000, TxType.income, 'pay', DateTime(2026, 6, 1));
      await add(20000, TxType.expense, 'food', DateTime(2026, 6, 2));
      await add(5000, TxType.expense, 'travel', DateTime(2026, 6, 3));

      final views = await repo.hydrate(await repo.transactions());

      expect(views.map((v) => v.category.name), ['Travel', 'Food', 'Salary']);
      // Newest first: 125000, then 130000, then 150000.
      expect(views[0].runningBalance, 125000);
      expect(views[1].runningBalance, 130000);
      expect(views[2].runningBalance, 150000);
      // The newest row must agree with the headline balance.
      expect(views.first.runningBalance, await repo.currentBalance());
    });

    test('offsets a partial page by everything that came before it', () async {
      await add(50000, TxType.income, 'pay', DateTime(2026, 6, 1));
      await add(20000, TxType.expense, 'food', DateTime(2026, 6, 2));

      final page = await repo.transactions(limit: 1); // newest only
      final views = await repo.hydrate(page);
      expect(views.single.runningBalance, 130000);
    });

    test('returns nothing for an empty page', () async {
      expect(await repo.hydrate([]), isEmpty);
    });
  });

  group('breakdown', () {
    test('ranks categories and compares with the previous window', () async {
      await add(30000, TxType.expense, 'food', DateTime(2026, 6, 5));
      await add(10000, TxType.expense, 'travel', DateTime(2026, 6, 6));
      await add(20000, TxType.expense, 'food', may); // previous window

      final rows = await repo.breakdown(
        from: june,
        to: juneEnd,
        type: TxType.expense,
        previousFrom: may,
        previousTo: june.subtract(const Duration(milliseconds: 1)),
      );

      expect(rows.map((r) => r.category.id), ['food', 'travel']);
      expect(rows.first.total, 30000);
      expect(rows.first.previousTotal, 20000);
      expect(rows.first.changePercent, closeTo(50, 0.001));
      // No baseline last month, so there is nothing to compare against.
      expect(rows.last.previousTotal, 0);
      expect(rows.last.changePercent, isNull);
    });

    test('ignores the other direction', () async {
      await add(30000, TxType.expense, 'food', DateTime(2026, 6, 5));
      await add(80000, TxType.income, 'pay', DateTime(2026, 6, 5));

      final rows = await repo.breakdown(
        from: june,
        to: juneEnd,
        type: TxType.expense,
      );
      expect(rows.single.category.id, 'food');
    });
  });

  group('daily series', () {
    test('zero-fills every day of the window, oldest first', () async {
      await add(1000, TxType.expense, 'food', DateTime(2026, 6, 2, 9));
      await add(2000, TxType.expense, 'food', DateTime(2026, 6, 2, 18));

      final series = await repo.dailySeries(
        from: june,
        to: juneEnd,
        type: TxType.expense,
      );

      expect(series.length, 30);
      expect(series.first.day, DateTime(2026, 6, 1));
      expect(series[0].total, 0);
      expect(series[1].total, 3000); // both of the 2nd's rows, summed
    });
  });

  group('budgets', () {
    setUp(() async {
      await repo.upsertBudget(
        const Budget(
          id: 'b_food',
          name: 'Food',
          iconName: 'cafe',
          colorValue: 0xFF000000,
          limit: 10000,
          categoryId: 'food',
          alertThreshold: 0.8,
        ),
      );
    });

    test('counts only its own category', () async {
      await add(4000, TxType.expense, 'food', DateTime(2026, 6, 5));
      await add(9000, TxType.expense, 'travel', DateTime(2026, 6, 5));

      final s = (await repo.budgetStatuses(june)).single;
      expect(s.spent, 4000);
      expect(s.remaining, 6000);
      expect(s.needsAttention, isFalse);
    });

    test('warns once past the threshold but under the limit', () async {
      await add(8500, TxType.expense, 'food', DateTime(2026, 6, 5));

      final s = (await repo.budgetStatuses(june)).single;
      expect(s.isNearLimit, isTrue);
      expect(s.isOver, isFalse);
      expect(s.needsAttention, isTrue);
    });

    test(
      'reports going over, and clamps the bar while rawProgress does not',
      () async {
        await add(15000, TxType.expense, 'food', DateTime(2026, 6, 5));

        final s = (await repo.budgetStatuses(june)).single;
        expect(s.isOver, isTrue);
        expect(s.remaining, -5000);
        expect(s.progress, 1.0);
        expect(s.rawProgress, closeTo(1.5, 0.001));
      },
    );

    test('stays silent when alerts are switched off', () async {
      await repo.upsertBudget(
        const Budget(
          id: 'b_food',
          name: 'Food',
          iconName: 'cafe',
          colorValue: 0xFF000000,
          limit: 10000,
          categoryId: 'food',
          alertsEnabled: false,
        ),
      );
      await add(15000, TxType.expense, 'food', DateTime(2026, 6, 5));

      expect((await repo.budgetStatuses(june)).single.needsAttention, isFalse);
    });

    test('a budget with no category covers all spending', () async {
      await repo.deleteBudget('b_food');
      await repo.upsertBudget(
        const Budget(
          id: 'b_all',
          name: 'Everything',
          iconName: 'wallet',
          colorValue: 0xFF000000,
          limit: 100000,
        ),
      );
      await add(4000, TxType.expense, 'food', DateTime(2026, 6, 5));
      await add(9000, TxType.expense, 'travel', DateTime(2026, 6, 5));

      expect((await repo.budgetStatuses(june)).single.spent, 13000);
    });
  });

  group('categories', () {
    test('refuses to delete one that still has transactions', () async {
      await add(1000, TxType.expense, 'food', DateTime(2026, 6, 5));

      expect(await repo.deleteCategory('food'), isFalse);
      expect((await repo.categories()).map((c) => c.id), contains('food'));
    });

    test('deletes an unused one', () async {
      expect(await repo.deleteCategory('travel'), isTrue);
      expect(
        (await repo.categories()).map((c) => c.id),
        isNot(contains('travel')),
      );
    });
  });

  group('goals', () {
    test('contributions accumulate and never go below zero', () async {
      await repo.upsertGoal(
        Goal(
          id: 'g',
          name: 'Car',
          iconName: 'car',
          colorValue: 0xFF000000,
          target: 100000,
          saved: 0,
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      await repo.contributeToGoal('g', 30000);
      expect((await repo.goals()).single.saved, 30000);

      await repo.contributeToGoal('g', -999999);
      expect((await repo.goals()).single.saved, 0);
    });
  });
}

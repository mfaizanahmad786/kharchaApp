import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../models/models.dart';

/// One slice of a breakdown: a category and what it adds up to over a window.
class CategoryTotal {
  const CategoryTotal({
    required this.category,
    required this.total,
    required this.count,
    required this.previousTotal,
  });

  final Category category;
  final int total;
  final int count;

  /// Same category over the previous window, for the "vs last month" badge.
  final int previousTotal;

  /// Signed percentage change against [previousTotal]; null when there is no
  /// baseline to compare against.
  double? get changePercent {
    if (previousTotal == 0) return null;
    return (total - previousTotal) / previousTotal * 100;
  }
}

/// A budget paired with what has actually been spent against it this period.
class BudgetStatus {
  const BudgetStatus({required this.budget, required this.spent});

  final Budget budget;
  final int spent;

  int get remaining => budget.limit - spent;
  double get progress => budget.limit == 0 ? 0 : (spent / budget.limit).clamp(0.0, 1.0);
  double get rawProgress => budget.limit == 0 ? 0 : spent / budget.limit;
  bool get isOver => spent > budget.limit;
  bool get isNearLimit =>
      budget.alertsEnabled && !isOver && rawProgress >= budget.alertThreshold;
  bool get needsAttention => budget.alertsEnabled && (isOver || isNearLimit);
}

class Totals {
  const Totals({required this.income, required this.expense});
  final int income;
  final int expense;
  int get net => income - expense;

  static const zero = Totals(income: 0, expense: 0);
}

/// Every read and write in the app goes through here.
class FinanceRepository {
  FinanceRepository(this._app);

  final AppDatabase _app;
  static const _uuid = Uuid();

  Database get _db => _app.db;

  // ---------------------------------------------------------------- accounts

  Future<List<Account>> accounts() async {
    final rows = await _db.query('accounts', orderBy: 'sort_order ASC, name ASC');
    return rows.map(Account.fromMap).toList(growable: false);
  }

  Future<void> upsertAccount(Account a) =>
      _db.insert('accounts', a.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> deleteAccount(String id) =>
      _db.delete('accounts', where: 'id = ?', whereArgs: [id]);

  // -------------------------------------------------------------- categories

  Future<List<Category>> categories({TxType? type}) async {
    final rows = await _db.query(
      'categories',
      where: type == null ? null : 'type = ?',
      whereArgs: type == null ? null : [type.db],
      orderBy: 'sort_order ASC, name ASC',
    );
    return rows.map(Category.fromMap).toList(growable: false);
  }

  Future<void> upsertCategory(Category c) =>
      _db.insert('categories', c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  /// Refuses to delete a category that still has transactions pointing at it.
  Future<bool> deleteCategory(String id) async {
    final used = Sqflite.firstIntValue(await _db.rawQuery(
      'SELECT COUNT(*) FROM txns WHERE category_id = ?',
      [id],
    ));
    if ((used ?? 0) > 0) return false;
    await _db.delete('categories', where: 'id = ?', whereArgs: [id]);
    return true;
  }

  // ------------------------------------------------------------ transactions

  Future<List<Txn>> transactions({
    DateTime? from,
    DateTime? to,
    TxType? type,
    String? categoryId,
    String? accountId,
    int? limit,
  }) async {
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) {
      where.add('date >= ?');
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      where.add('date <= ?');
      args.add(to.millisecondsSinceEpoch);
    }
    if (type != null) {
      where.add('type = ?');
      args.add(type.db);
    }
    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    if (accountId != null) {
      where.add('account_id = ?');
      args.add(accountId);
    }
    final rows = await _db.query(
      'txns',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );
    return rows.map(Txn.fromMap).toList(growable: false);
  }

  Future<Txn?> transactionById(String id) async {
    final rows = await _db.query('txns', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Txn.fromMap(rows.first);
  }

  Future<String> addTransaction({
    required int amount,
    required TxType type,
    required String categoryId,
    required String accountId,
    required DateTime date,
    String note = '',
    List<String> tags = const [],
  }) async {
    final id = _uuid.v4();
    await _db.insert('txns', {
      'id': id,
      'amount': amount.abs(),
      'type': type.db,
      'category_id': categoryId,
      'account_id': accountId,
      'date': date.millisecondsSinceEpoch,
      'note': note,
      'tags': tags.join('|'),
    });
    return id;
  }

  Future<void> updateTransaction(Txn t) => _db.update(
        'txns',
        t.toMap(),
        where: 'id = ?',
        whereArgs: [t.id],
      );

  Future<void> deleteTransaction(String id) =>
      _db.delete('txns', where: 'id = ?', whereArgs: [id]);

  /// Joins transactions to their category/account and threads a running
  /// all-accounts balance through them, newest first.
  Future<List<TxnView>> hydrate(List<Txn> txns) async {
    if (txns.isEmpty) return const [];
    final cats = {for (final c in await categories()) c.id: c};
    final accs = {for (final a in await accounts()) a.id: a};

    // Balance at the moment just before the oldest row in this list.
    final oldest = txns.last;
    final opening = Sqflite.firstIntValue(
          await _db.rawQuery('SELECT COALESCE(SUM(opening_balance), 0) FROM accounts'),
        ) ??
        0;
    final priorNet = Sqflite.firstIntValue(await _db.rawQuery(
          '''SELECT COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END), 0)
             FROM txns WHERE date < ? OR (date = ? AND id < ?)''',
          [
            oldest.date.millisecondsSinceEpoch,
            oldest.date.millisecondsSinceEpoch,
            oldest.id,
          ],
        )) ??
        0;

    // Walk oldest -> newest accumulating, then flip back to newest-first.
    var running = opening + priorNet;
    final ascending = txns.reversed.toList(growable: false);
    final out = <TxnView>[];
    final fallbackCat = Category(
      id: '_missing',
      name: 'Uncategorised',
      iconName: 'other',
      colorValue: 0xFF9A9AA6,
      type: TxType.expense,
    );
    const fallbackAcc = Account(
      id: '_missing',
      name: 'Account',
      iconName: 'wallet',
      colorValue: 0xFF9A9AA6,
      openingBalance: 0,
    );
    for (final t in ascending) {
      running += t.signed;
      out.add(TxnView(
        txn: t,
        category: cats[t.categoryId] ?? fallbackCat,
        account: accs[t.accountId] ?? fallbackAcc,
        runningBalance: running,
      ));
    }
    return out.reversed.toList(growable: false);
  }

  // ------------------------------------------------------------------ totals

  Future<int> currentBalance() async {
    final opening = Sqflite.firstIntValue(
          await _db.rawQuery('SELECT COALESCE(SUM(opening_balance), 0) FROM accounts'),
        ) ??
        0;
    final net = Sqflite.firstIntValue(await _db.rawQuery(
          "SELECT COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END), 0) FROM txns",
        )) ??
        0;
    return opening + net;
  }

  Future<Totals> totals(DateTime from, DateTime to) async {
    final rows = await _db.rawQuery(
      'SELECT type, COALESCE(SUM(amount), 0) AS total FROM txns '
      'WHERE date BETWEEN ? AND ? GROUP BY type',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    var income = 0;
    var expense = 0;
    for (final r in rows) {
      final total = (r['total'] as num?)?.toInt() ?? 0;
      if (r['type'] == 'income') {
        income = total;
      } else {
        expense = total;
      }
    }
    return Totals(income: income, expense: expense);
  }

  Future<int> sumFor({
    required DateTime from,
    required DateTime to,
    required TxType type,
    String? categoryId,
  }) async {
    final where = StringBuffer('date BETWEEN ? AND ? AND type = ?');
    final args = <Object?>[
      from.millisecondsSinceEpoch,
      to.millisecondsSinceEpoch,
      type.db,
    ];
    if (categoryId != null) {
      where.write(' AND category_id = ?');
      args.add(categoryId);
    }
    return Sqflite.firstIntValue(await _db.rawQuery(
          'SELECT COALESCE(SUM(amount), 0) FROM txns WHERE $where',
          args,
        )) ??
        0;
  }

  /// Per-category totals for a window, each carrying the same category's total
  /// over the immediately preceding window of equal length.
  Future<List<CategoryTotal>> breakdown({
    required DateTime from,
    required DateTime to,
    required TxType type,
  }) async {
    final span = to.difference(from);
    final prevTo = from.subtract(const Duration(milliseconds: 1));
    final prevFrom = prevTo.subtract(span);

    Future<Map<String, (int, int)>> agg(DateTime a, DateTime b) async {
      final rows = await _db.rawQuery(
        'SELECT category_id, COALESCE(SUM(amount), 0) AS total, COUNT(*) AS n '
        'FROM txns WHERE date BETWEEN ? AND ? AND type = ? GROUP BY category_id',
        [a.millisecondsSinceEpoch, b.millisecondsSinceEpoch, type.db],
      );
      return {
        for (final r in rows)
          r['category_id']! as String: (
            (r['total'] as num).toInt(),
            (r['n'] as num).toInt(),
          ),
      };
    }

    final current = await agg(from, to);
    final previous = await agg(prevFrom, prevTo);
    final cats = {for (final c in await categories(type: type)) c.id: c};

    final out = <CategoryTotal>[];
    for (final entry in current.entries) {
      final cat = cats[entry.key];
      if (cat == null) continue;
      out.add(CategoryTotal(
        category: cat,
        total: entry.value.$1,
        count: entry.value.$2,
        previousTotal: previous[entry.key]?.$1 ?? 0,
      ));
    }
    out.sort((a, b) => b.total.compareTo(a.total));
    return out;
  }

  /// Daily sums across a window, zero-filled, oldest first. Drives the bar chart.
  Future<List<({DateTime day, int total})>> dailySeries({
    required DateTime from,
    required DateTime to,
    required TxType type,
  }) async {
    final rows = await _db.rawQuery(
      'SELECT date, amount FROM txns WHERE date BETWEEN ? AND ? AND type = ?',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch, type.db],
    );
    final buckets = <int, int>{};
    for (final r in rows) {
      final d = DateTime.fromMillisecondsSinceEpoch(r['date']! as int);
      final key = DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;
      buckets[key] = (buckets[key] ?? 0) + (r['amount']! as int);
    }
    final out = <({DateTime day, int total})>[];
    var cursor = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    while (!cursor.isAfter(end)) {
      out.add((day: cursor, total: buckets[cursor.millisecondsSinceEpoch] ?? 0));
      cursor = cursor.add(const Duration(days: 1));
    }
    return out;
  }

  /// Net worth at the end of each of the last [months] months, oldest first.
  Future<List<({DateTime month, int income, int expense})>> monthlySeries(
      int months) async {
    final now = DateTime.now();
    final out = <({DateTime month, int income, int expense})>[];
    for (var i = months - 1; i >= 0; i--) {
      final start = DateTime(now.year, now.month - i);
      final end = DateTime(now.year, now.month - i + 1)
          .subtract(const Duration(milliseconds: 1));
      final t = await totals(start, end);
      out.add((month: start, income: t.income, expense: t.expense));
    }
    return out;
  }

  // ----------------------------------------------------------------- budgets

  Future<List<BudgetStatus>> budgetStatuses(DateTime month) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1)
        .subtract(const Duration(milliseconds: 1));
    final rows = await _db.query('budgets', orderBy: 'sort_order ASC, name ASC');
    final out = <BudgetStatus>[];
    for (final r in rows) {
      final b = Budget.fromMap(r);
      final spent = await sumFor(
        from: from,
        to: to,
        type: TxType.expense,
        categoryId: b.categoryId,
      );
      out.add(BudgetStatus(budget: b, spent: spent));
    }
    return out;
  }

  Future<void> upsertBudget(Budget b) =>
      _db.insert('budgets', b.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> deleteBudget(String id) =>
      _db.delete('budgets', where: 'id = ?', whereArgs: [id]);

  String newId() => _uuid.v4();

  // ------------------------------------------------------------------- goals

  Future<List<Goal>> goals() async {
    final rows = await _db.query('goals', orderBy: 'created_at DESC');
    return rows.map(Goal.fromMap).toList(growable: false);
  }

  Future<void> upsertGoal(Goal g) =>
      _db.insert('goals', g.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> deleteGoal(String id) =>
      _db.delete('goals', where: 'id = ?', whereArgs: [id]);

  Future<void> contributeToGoal(String id, int amount) async {
    await _db.rawUpdate(
      'UPDATE goals SET saved_amount = MAX(0, saved_amount + ?) WHERE id = ?',
      [amount, id],
    );
  }

  // ------------------------------------------------------------- maintenance

  Future<void> resetToSeed() => _app.resetToSeed();
  Future<void> clearTransactions() => _app.clearTransactions();
}

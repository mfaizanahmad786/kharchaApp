import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/app_date.dart';
import '../data/db/app_database.dart';
import '../data/models/models.dart';
import '../data/prefs/security_store.dart';
import '../data/prefs/settings_store.dart';
import '../data/repository/finance_repository.dart';

// ---------------------------------------------------------------- injection
// These three are overridden in main() once the async setup has finished.

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden in main()');
});

final settingsStoreProvider = Provider<SettingsStore>((ref) {
  throw UnimplementedError('settingsStoreProvider must be overridden in main()');
});

final securityStoreProvider = Provider<SecurityStore>((ref) => SecurityStore());

final repositoryProvider = Provider<FinanceRepository>(
  (ref) => FinanceRepository(ref.watch(databaseProvider)),
);

// ----------------------------------------------------------------- refresh
// sqflite has no change stream, so writes bump a revision counter and every
// derived read watches it. One place to invalidate, no stale screens.

class Revision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

final revisionProvider = NotifierProvider<Revision, int>(Revision.new);

/// The repository, plus a guarantee that the UI refreshes after a write.
class FinanceActions {
  FinanceActions(this._ref);

  final Ref _ref;
  FinanceRepository get repo => _ref.read(repositoryProvider);

  Future<T> _write<T>(Future<T> Function(FinanceRepository r) op) async {
    final result = await op(repo);
    _ref.read(revisionProvider.notifier).bump();
    return result;
  }

  Future<String> addTransaction({
    required int amount,
    required TxType type,
    required String categoryId,
    required String accountId,
    required DateTime date,
    String note = '',
    List<String> tags = const [],
  }) =>
      _write((r) => r.addTransaction(
            amount: amount,
            type: type,
            categoryId: categoryId,
            accountId: accountId,
            date: date,
            note: note,
            tags: tags,
          ));

  Future<void> updateTransaction(Txn t) => _write((r) => r.updateTransaction(t));
  Future<void> deleteTransaction(String id) => _write((r) => r.deleteTransaction(id));

  Future<void> upsertCategory(Category c) => _write((r) => r.upsertCategory(c));
  Future<bool> deleteCategory(String id) => _write((r) => r.deleteCategory(id));

  Future<void> upsertAccount(Account a) => _write((r) => r.upsertAccount(a));
  Future<void> deleteAccount(String id) => _write((r) => r.deleteAccount(id));

  Future<void> upsertBudget(Budget b) => _write((r) => r.upsertBudget(b));
  Future<void> deleteBudget(String id) => _write((r) => r.deleteBudget(id));

  Future<void> upsertGoal(Goal g) => _write((r) => r.upsertGoal(g));
  Future<void> deleteGoal(String id) => _write((r) => r.deleteGoal(id));
  Future<void> contributeToGoal(String id, int amount) =>
      _write((r) => r.contributeToGoal(id, amount));

  Future<void> resetToSeed() => _write((r) => r.resetToSeed());
  Future<void> clearTransactions() => _write((r) => r.clearTransactions());
}

final actionsProvider = Provider<FinanceActions>(FinanceActions.new);

// ------------------------------------------------------------ period / month

/// The month the whole app is looking at. Home, Report and Plan share it.
class SelectedMonth extends Notifier<DateTime> {
  @override
  DateTime build() => AppDate.startOfMonth(DateTime.now());

  void set(DateTime month) => state = AppDate.startOfMonth(month);
  void next() => state = AppDate.addMonths(state, 1);
  void previous() => state = AppDate.addMonths(state, -1);

  bool get isCurrentMonth {
    final now = DateTime.now();
    return state.year == now.year && state.month == now.month;
  }
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonth, DateTime>(SelectedMonth.new);

({DateTime from, DateTime to}) _monthRange(DateTime month) =>
    (from: AppDate.startOfMonth(month), to: AppDate.endOfMonth(month));

// -------------------------------------------------------------- derived data

final balanceProvider = FutureProvider<int>((ref) async {
  ref.watch(revisionProvider);
  return ref.watch(repositoryProvider).currentBalance();
});

/// Net change over the last 7 days, for the "+₨784 than last week" pill.
final weekDeltaProvider = FutureProvider<int>((ref) async {
  ref.watch(revisionProvider);
  final repo = ref.watch(repositoryProvider);
  final now = DateTime.now();
  final t = await repo.totals(now.subtract(const Duration(days: 7)), now);
  return t.net;
});

final monthTotalsProvider = FutureProvider<Totals>((ref) async {
  ref.watch(revisionProvider);
  final range = _monthRange(ref.watch(selectedMonthProvider));
  return ref.watch(repositoryProvider).totals(range.from, range.to);
});

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  ref.watch(revisionProvider);
  return ref.watch(repositoryProvider).accounts();
});

final allCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  ref.watch(revisionProvider);
  return ref.watch(repositoryProvider).categories();
});

final categoriesProvider =
    FutureProvider.family<List<Category>, TxType>((ref, type) async {
  ref.watch(revisionProvider);
  return ref.watch(repositoryProvider).categories(type: type);
});

/// Transactions for the selected month, hydrated and newest-first.
final monthTransactionsProvider = FutureProvider<List<TxnView>>((ref) async {
  ref.watch(revisionProvider);
  final repo = ref.watch(repositoryProvider);
  final range = _monthRange(ref.watch(selectedMonthProvider));
  final txns = await repo.transactions(from: range.from, to: range.to);
  return repo.hydrate(txns);
});

/// Month transactions grouped into day sections, newest day first.
typedef DaySection = ({DateTime day, int net, List<TxnView> items});

final groupedTransactionsProvider = FutureProvider<List<DaySection>>((ref) async {
  final views = await ref.watch(monthTransactionsProvider.future);
  final sections = <DateTime, List<TxnView>>{};
  for (final v in views) {
    final key = AppDate.startOfDay(v.txn.date);
    (sections[key] ??= <TxnView>[]).add(v);
  }
  final keys = sections.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final k in keys)
      (
        day: k,
        net: sections[k]!.fold<int>(0, (sum, v) => sum + v.txn.signed),
        items: sections[k]!,
      ),
  ];
});

final breakdownProvider =
    FutureProvider.family<List<CategoryTotal>, TxType>((ref, type) async {
  ref.watch(revisionProvider);
  final range = _monthRange(ref.watch(selectedMonthProvider));
  return ref
      .watch(repositoryProvider)
      .breakdown(from: range.from, to: range.to, type: type);
});

final dailySeriesProvider =
    FutureProvider.family<List<({DateTime day, int total})>, TxType>(
        (ref, type) async {
  ref.watch(revisionProvider);
  final range = _monthRange(ref.watch(selectedMonthProvider));
  return ref
      .watch(repositoryProvider)
      .dailySeries(from: range.from, to: range.to, type: type);
});

final budgetStatusesProvider = FutureProvider<List<BudgetStatus>>((ref) async {
  ref.watch(revisionProvider);
  return ref.watch(repositoryProvider).budgetStatuses(ref.watch(selectedMonthProvider));
});

/// Budgets that have tripped their alert threshold, worst first.
final budgetAlertsProvider = FutureProvider<List<BudgetStatus>>((ref) async {
  final all = await ref.watch(budgetStatusesProvider.future);
  final alerts = all.where((s) => s.needsAttention).toList()
    ..sort((a, b) => b.rawProgress.compareTo(a.rawProgress));
  return alerts;
});

final goalsProvider = FutureProvider<List<Goal>>((ref) async {
  ref.watch(revisionProvider);
  return ref.watch(repositoryProvider).goals();
});

// ---------------------------------------------------------------- settings

@immutable
class SettingsState {
  const SettingsState({
    required this.userName,
    required this.hideAmounts,
    required this.budgetAlerts,
  });

  final String userName;
  final bool hideAmounts;
  final bool budgetAlerts;

  SettingsState copyWith({String? userName, bool? hideAmounts, bool? budgetAlerts}) =>
      SettingsState(
        userName: userName ?? this.userName,
        hideAmounts: hideAmounts ?? this.hideAmounts,
        budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      );
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final s = ref.watch(settingsStoreProvider);
    return SettingsState(
      userName: s.userName,
      hideAmounts: s.hideAmounts,
      budgetAlerts: s.budgetAlerts,
    );
  }

  Future<void> setUserName(String v) async {
    await ref.read(settingsStoreProvider).setUserName(v);
    state = state.copyWith(userName: v);
  }

  Future<void> setHideAmounts(bool v) async {
    await ref.read(settingsStoreProvider).setHideAmounts(v);
    state = state.copyWith(hideAmounts: v);
  }

  Future<void> setBudgetAlerts(bool v) async {
    await ref.read(settingsStoreProvider).setBudgetAlerts(v);
    state = state.copyWith(budgetAlerts: v);
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

// ---------------------------------------------------------------- security

@immutable
class SecurityState {
  const SecurityState({
    required this.hasPin,
    required this.lockEnabled,
    required this.biometricEnabled,
    required this.biometricAvailable,
  });

  final bool hasPin;
  final bool lockEnabled;
  final bool biometricEnabled;
  final bool biometricAvailable;

  static const unknown = SecurityState(
    hasPin: false,
    lockEnabled: false,
    biometricEnabled: false,
    biometricAvailable: false,
  );
}

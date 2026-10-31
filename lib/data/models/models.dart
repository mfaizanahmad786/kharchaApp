import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';

enum TxType {
  expense,
  income;

  static TxType fromDb(String v) =>
      v == 'income' ? TxType.income : TxType.expense;
  String get db => name;
  bool get isExpense => this == TxType.expense;
  bool get isIncome => this == TxType.income;
}

@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.type,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String iconName;
  final int colorValue;
  final TxType type;
  final int sortOrder;

  IconData get icon => AppIcons.byName(iconName);
  Color get color => Color(colorValue);

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'icon_name': iconName,
    'color_value': colorValue,
    'type': type.db,
    'sort_order': sortOrder,
  };

  factory Category.fromMap(Map<String, Object?> m) => Category(
    id: m['id']! as String,
    name: m['name']! as String,
    iconName: m['icon_name']! as String,
    colorValue: m['color_value']! as int,
    type: TxType.fromDb(m['type']! as String),
    sortOrder: (m['sort_order'] as int?) ?? 0,
  );

  Category copyWith({
    String? name,
    String? iconName,
    int? colorValue,
    TxType? type,
  }) => Category(
    id: id,
    name: name ?? this.name,
    iconName: iconName ?? this.iconName,
    colorValue: colorValue ?? this.colorValue,
    type: type ?? this.type,
    sortOrder: sortOrder,
  );
}

@immutable
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.openingBalance,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String iconName;
  final int colorValue;

  /// In paisa.
  final int openingBalance;
  final int sortOrder;

  IconData get icon => AppIcons.byName(iconName);
  Color get color => Color(colorValue);

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'icon_name': iconName,
    'color_value': colorValue,
    'opening_balance': openingBalance,
    'sort_order': sortOrder,
  };

  factory Account.fromMap(Map<String, Object?> m) => Account(
    id: m['id']! as String,
    name: m['name']! as String,
    iconName: m['icon_name']! as String,
    colorValue: m['color_value']! as int,
    openingBalance: (m['opening_balance'] as int?) ?? 0,
    sortOrder: (m['sort_order'] as int?) ?? 0,
  );

  Account copyWith({
    String? name,
    String? iconName,
    int? colorValue,
    int? openingBalance,
  }) => Account(
    id: id,
    name: name ?? this.name,
    iconName: iconName ?? this.iconName,
    colorValue: colorValue ?? this.colorValue,
    openingBalance: openingBalance ?? this.openingBalance,
    sortOrder: sortOrder,
  );
}

@immutable
class Txn {
  const Txn({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.date,
    this.note = '',
    this.tags = const [],
  });

  final String id;

  /// Always a positive magnitude, in paisa. [type] carries the direction.
  final int amount;
  final TxType type;
  final String categoryId;
  final String accountId;
  final DateTime date;
  final String note;
  final List<String> tags;

  /// Signed value for summing into a balance.
  int get signed => type.isIncome ? amount : -amount;

  Map<String, Object?> toMap() => {
    'id': id,
    'amount': amount,
    'type': type.db,
    'category_id': categoryId,
    'account_id': accountId,
    'date': date.millisecondsSinceEpoch,
    'note': note,
    'tags': tags.join('|'),
  };

  factory Txn.fromMap(Map<String, Object?> m) => Txn(
    id: m['id']! as String,
    amount: m['amount']! as int,
    type: TxType.fromDb(m['type']! as String),
    categoryId: m['category_id']! as String,
    accountId: m['account_id']! as String,
    date: DateTime.fromMillisecondsSinceEpoch(m['date']! as int),
    note: (m['note'] as String?) ?? '',
    tags: ((m['tags'] as String?) ?? '')
        .split('|')
        .where((t) => t.trim().isNotEmpty)
        .toList(growable: false),
  );

  Txn copyWith({
    int? amount,
    TxType? type,
    String? categoryId,
    String? accountId,
    DateTime? date,
    String? note,
    List<String>? tags,
  }) => Txn(
    id: id,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    categoryId: categoryId ?? this.categoryId,
    accountId: accountId ?? this.accountId,
    date: date ?? this.date,
    note: note ?? this.note,
    tags: tags ?? this.tags,
  );
}

/// A monthly spending ceiling, optionally scoped to one category.
@immutable
class Budget {
  const Budget({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.limit,
    this.categoryId,
    this.alertsEnabled = true,
    this.alertThreshold = 0.8,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String iconName;
  final int colorValue;

  /// Monthly ceiling, in paisa.
  final int limit;
  final String? categoryId;
  final bool alertsEnabled;

  /// Fraction of [limit] at which a warning is raised (0.0–1.0).
  final double alertThreshold;
  final int sortOrder;

  IconData get icon => AppIcons.byName(iconName);
  Color get color => Color(colorValue);

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'icon_name': iconName,
    'color_value': colorValue,
    'limit_amount': limit,
    'category_id': categoryId,
    'alerts_enabled': alertsEnabled ? 1 : 0,
    'alert_threshold': alertThreshold,
    'sort_order': sortOrder,
  };

  factory Budget.fromMap(Map<String, Object?> m) => Budget(
    id: m['id']! as String,
    name: m['name']! as String,
    iconName: m['icon_name']! as String,
    colorValue: m['color_value']! as int,
    limit: m['limit_amount']! as int,
    categoryId: m['category_id'] as String?,
    alertsEnabled: ((m['alerts_enabled'] as int?) ?? 1) == 1,
    alertThreshold: ((m['alert_threshold'] as num?) ?? 0.8).toDouble(),
    sortOrder: (m['sort_order'] as int?) ?? 0,
  );

  Budget copyWith({
    String? name,
    String? iconName,
    int? colorValue,
    int? limit,
    String? categoryId,
    bool clearCategory = false,
    bool? alertsEnabled,
    double? alertThreshold,
  }) => Budget(
    id: id,
    name: name ?? this.name,
    iconName: iconName ?? this.iconName,
    colorValue: colorValue ?? this.colorValue,
    limit: limit ?? this.limit,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    alertsEnabled: alertsEnabled ?? this.alertsEnabled,
    alertThreshold: alertThreshold ?? this.alertThreshold,
    sortOrder: sortOrder,
  );
}

/// A savings target with a deadline.
@immutable
class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.target,
    required this.saved,
    required this.createdAt,
    this.deadline,
  });

  final String id;
  final String name;
  final String iconName;
  final int colorValue;

  /// In paisa.
  final int target;
  final int saved;
  final DateTime createdAt;
  final DateTime? deadline;

  IconData get icon => AppIcons.byName(iconName);
  Color get color => Color(colorValue);

  int get remaining => (target - saved).clamp(0, target);
  double get progress => target == 0 ? 0 : (saved / target).clamp(0.0, 1.0);

  /// How far along we *should* be, judged purely by elapsed time.
  double get expectedProgress {
    final end = deadline;
    if (end == null) return progress;
    final total = end.difference(createdAt).inSeconds;
    if (total <= 0) return 1;
    final done = DateTime.now().difference(createdAt).inSeconds;
    return (done / total).clamp(0.0, 1.0);
  }

  /// Positive = behind schedule, as a fraction of the target.
  double get scheduleGap => expectedProgress - progress;
  bool get isBehind => deadline != null && scheduleGap > 0.05;

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'icon_name': iconName,
    'color_value': colorValue,
    'target_amount': target,
    'saved_amount': saved,
    'created_at': createdAt.millisecondsSinceEpoch,
    'deadline': deadline?.millisecondsSinceEpoch,
  };

  factory Goal.fromMap(Map<String, Object?> m) => Goal(
    id: m['id']! as String,
    name: m['name']! as String,
    iconName: m['icon_name']! as String,
    colorValue: m['color_value']! as int,
    target: m['target_amount']! as int,
    saved: m['saved_amount']! as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int),
    deadline: m['deadline'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(m['deadline']! as int),
  );

  Goal copyWith({
    String? name,
    String? iconName,
    int? colorValue,
    int? target,
    int? saved,
    DateTime? deadline,
    bool clearDeadline = false,
  }) => Goal(
    id: id,
    name: name ?? this.name,
    iconName: iconName ?? this.iconName,
    colorValue: colorValue ?? this.colorValue,
    target: target ?? this.target,
    saved: saved ?? this.saved,
    createdAt: createdAt,
    deadline: clearDeadline ? null : (deadline ?? this.deadline),
  );
}

/// A transaction joined with the rows it points at — what the UI actually needs.
@immutable
class TxnView {
  const TxnView({
    required this.txn,
    required this.category,
    required this.account,
    required this.runningBalance,
  });

  final Txn txn;
  final Category category;
  final Account account;

  /// Balance across all accounts immediately after this transaction.
  final int runningBalance;

  Color get accent => category.color;
  Color get amountColor =>
      txn.type.isIncome ? AppColors.income : AppColors.expense;
}

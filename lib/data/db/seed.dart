import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../../core/theme/app_colors.dart';

/// First-run content. A brand-new install opens on a populated app rather than
/// five empty screens, which is also what the design comps show.
///
/// The generator is seeded with a fixed value so the demo history is stable
/// across reinstalls and across devices.
abstract final class Seed {
  static const accounts = <Map<String, Object?>>[
    {
      'id': 'acc_cash',
      'name': 'Cash',
      'icon_name': 'cash',
      'color_value': 0xFF8B5CF6,
      'opening_balance': 4500000,
      'sort_order': 0,
    },
    {
      'id': 'acc_card',
      'name': 'Red Card',
      'icon_name': 'card',
      'color_value': 0xFFF0384F,
      'opening_balance': 3200000,
      'sort_order': 1,
    },
    {
      'id': 'acc_bank',
      'name': 'Meezan Bank',
      'icon_name': 'bank',
      'color_value': 0xFF4A9BF0,
      'opening_balance': 11000000,
      'sort_order': 2,
    },
  ];

  /// name, icon, colour, weight (relative frequency), min/max in rupees
  static const _expenseSpec = <List<Object>>[
    ['Groceries', 'groceries', 0xFF4A9BF0, 22, 1500, 11000],
    ['Clothing & Shoes', 'clothing', 0xFFE8743B, 6, 2500, 18000],
    ['Cafes', 'cafe', 0xFF4CBF7F, 18, 350, 2600],
    ['Restaurants', 'restaurant', 0xFFEC6A9C, 10, 900, 7500],
    ['Transport', 'transport', 0xFF5B6CF0, 16, 150, 2200],
    ['Fuel', 'fuel', 0xFF2CBFBF, 7, 3000, 9000],
    ['Rent', 'rent', 0xFF8B5CF6, 2, 55000, 55000],
    ['Bills & Utilities', 'bills', 0xFFF0B429, 6, 1800, 14000],
    ['Health', 'health', 0xFFF0384F, 4, 800, 12000],
    ['Education', 'education', 0xFF7C4DEF, 3, 5000, 25000],
    ['Entertainment', 'entertainment', 0xFFEC6A9C, 7, 600, 4500],
    ['Shopping', 'shopping', 0xFF4CBF7F, 8, 1200, 16000],
    ['Travel', 'travel', 'skip', 2, 8000, 45000],
    ['Gifts', 'gift', 0xFFF0B429, 3, 1000, 9000],
  ];

  static const _incomeSpec = <List<Object>>[
    ['Salary', 'salary', 0xFF2FB573, 1, 285000, 285000],
    ['Freelance', 'freelance', 0xFF4A9BF0, 4, 15000, 90000],
    ['Business', 'business', 0xFF8B5CF6, 2, 20000, 120000],
    ['Investment', 'investment', 0xFF2CBFBF, 2, 5000, 40000],
    ['Bonus', 'bonus', 0xFFF0B429, 1, 25000, 75000],
    ['Refund', 'refund', 0xFF5B6CF0, 2, 500, 6000],
  ];

  static const _tagPool = <String>[
    'Vacation',
    'Family',
    'Work',
    'Monthly',
    'Urgent',
    'Planned',
    'Gift',
  ];

  static Future<void> populate(DatabaseExecutor d) async {
    final rng = Random(20260112);
    final batch = d.batch();

    for (final a in accounts) {
      batch.insert('accounts', a);
    }

    final expenseCats = <String>[];
    final expenseWeights = <int>[];
    final expenseRanges = <List<int>>[];
    var order = 0;
    for (final spec in _expenseSpec) {
      final id = 'cat_${(spec[1] as String)}';
      final color = spec[2] is int
          ? spec[2] as int
          : AppColors.chartPalette[order % AppColors.chartPalette.length]
                .toARGB32();
      batch.insert('categories', {
        'id': id,
        'name': spec[0],
        'icon_name': spec[1],
        'color_value': color,
        'type': 'expense',
        'sort_order': order,
      });
      expenseCats.add(id);
      expenseWeights.add(spec[3] as int);
      expenseRanges.add([spec[4] as int, spec[5] as int]);
      order++;
    }

    final incomeCats = <String>[];
    final incomeWeights = <int>[];
    final incomeRanges = <List<int>>[];
    order = 0;
    for (final spec in _incomeSpec) {
      final id = 'cat_${(spec[1] as String)}';
      batch.insert('categories', {
        'id': id,
        'name': spec[0],
        'icon_name': spec[1],
        'color_value': spec[2],
        'type': 'income',
        'sort_order': order,
      });
      incomeCats.add(id);
      incomeWeights.add(spec[3] as int);
      incomeRanges.add([spec[4] as int, spec[5] as int]);
      order++;
    }

    final accountIds = accounts.map((a) => a['id']! as String).toList();
    final now = DateTime.now();
    var txIndex = 0;

    // Six months of history, ending today.
    for (var monthsBack = 5; monthsBack >= 0; monthsBack--) {
      final anchor = DateTime(now.year, now.month - monthsBack);
      final isCurrentMonth = monthsBack == 0;
      final lastDay = isCurrentMonth
          ? now.day
          : DateTime(anchor.year, anchor.month + 1, 0).day;

      // Salary on the 1st and rent on the 3rd — but never dated after today,
      // or the current month opens on an entry that has not happened yet.
      final salaryOn = DateTime(anchor.year, anchor.month, 1, 9, 30);
      if (!salaryOn.isAfter(now)) {
        batch.insert('txns', {
          'id': 'tx_${txIndex++}',
          'amount': 28500000,
          'type': 'income',
          'category_id': 'cat_salary',
          'account_id': 'acc_bank',
          'date': salaryOn.millisecondsSinceEpoch,
          'note': 'Monthly salary',
          'tags': 'Work|Monthly',
        });
      }

      final rentOn = DateTime(anchor.year, anchor.month, 3, 11);
      if (!rentOn.isAfter(now)) {
        batch.insert('txns', {
          'id': 'tx_${txIndex++}',
          'amount': 5500000,
          'type': 'expense',
          'category_id': 'cat_rent',
          'account_id': 'acc_bank',
          'date': rentOn.millisecondsSinceEpoch,
          'note': 'Apartment rent',
          'tags': 'Monthly',
        });
      }

      // A couple of extra income events.
      final extraIncome = 1 + rng.nextInt(3);
      for (var i = 0; i < extraIncome; i++) {
        final ci = _weighted(rng, incomeWeights);
        if (incomeCats[ci] == 'cat_salary') continue;
        final r = incomeRanges[ci];
        batch.insert('txns', {
          'id': 'tx_${txIndex++}',
          'amount': _amount(rng, r[0], r[1]),
          'type': 'income',
          'category_id': incomeCats[ci],
          'account_id': accountIds[rng.nextInt(accountIds.length)],
          'date': DateTime(
            anchor.year,
            anchor.month,
            1 + rng.nextInt(lastDay),
            10 + rng.nextInt(9),
          ).millisecondsSinceEpoch,
          'note': '',
          'tags': rng.nextBool() ? _tagPool[rng.nextInt(_tagPool.length)] : '',
        });
      }

      // Day-to-day spending.
      final spendCount = isCurrentMonth
          ? (lastDay * 1.4).round()
          : 38 + rng.nextInt(14);
      for (var i = 0; i < spendCount; i++) {
        final ci = _weighted(rng, expenseWeights);
        if (expenseCats[ci] == 'cat_rent') continue;
        final r = expenseRanges[ci];
        final day = 1 + rng.nextInt(lastDay);
        final tagCount = rng.nextInt(10) < 3 ? 1 + rng.nextInt(2) : 0;
        final tags = <String>{};
        for (var t = 0; t < tagCount; t++) {
          tags.add(_tagPool[rng.nextInt(_tagPool.length)]);
        }
        batch.insert('txns', {
          'id': 'tx_${txIndex++}',
          'amount': _amount(rng, r[0], r[1]),
          'type': 'expense',
          'category_id': expenseCats[ci],
          'account_id': accountIds[rng.nextInt(accountIds.length)],
          'date': DateTime(
            anchor.year,
            anchor.month,
            day,
            8 + rng.nextInt(13),
            rng.nextInt(60),
          ).millisecondsSinceEpoch,
          'note': '',
          'tags': tags.join('|'),
        });
      }
    }

    const budgets = <Map<String, Object?>>[
      {
        'id': 'bud_groceries',
        'name': 'Groceries',
        'icon_name': 'groceries',
        'color_value': 0xFF4A9BF0,
        'limit_amount': 6500000,
        'category_id': 'cat_groceries',
        'alerts_enabled': 1,
        'alert_threshold': 0.8,
        'sort_order': 0,
      },
      {
        'id': 'bud_cafe',
        'name': 'Cafes & Dining',
        'icon_name': 'cafe',
        'color_value': 0xFF4CBF7F,
        'limit_amount': 2500000,
        'category_id': 'cat_cafe',
        'alerts_enabled': 1,
        'alert_threshold': 0.75,
        'sort_order': 1,
      },
      {
        'id': 'bud_transport',
        'name': 'Transport',
        'icon_name': 'transport',
        'color_value': 0xFF5B6CF0,
        'limit_amount': 1800000,
        'category_id': 'cat_transport',
        'alerts_enabled': 1,
        'alert_threshold': 0.8,
        'sort_order': 2,
      },
      {
        'id': 'bud_shopping',
        'name': 'Shopping',
        'icon_name': 'shopping',
        'color_value': 0xFFE8743B,
        'limit_amount': 3500000,
        'category_id': 'cat_shopping',
        'alerts_enabled': 1,
        'alert_threshold': 0.8,
        'sort_order': 3,
      },
      {
        'id': 'bud_all',
        'name': 'Everything this month',
        'icon_name': 'wallet',
        'color_value': 0xFF8B5CF6,
        'limit_amount': 22000000,
        'category_id': null,
        'alerts_enabled': 1,
        'alert_threshold': 0.9,
        'sort_order': 4,
      },
    ];
    for (final b in budgets) {
      batch.insert('budgets', b);
    }

    final goalBase = DateTime(
      now.year,
      now.month - 7,
      1,
    ).millisecondsSinceEpoch;
    final goals = <Map<String, Object?>>[
      {
        'id': 'goal_house',
        'name': 'House by the Sea',
        'icon_name': 'home',
        'color_value': 0xFFE8743B,
        'target_amount': 250000000,
        'saved_amount': 87500000,
        'created_at': goalBase,
        'pinned': 1,
        // Deliberately behind schedule, so the Plan screen shows the
        // off-target warning rather than only the happy path.
        'deadline': DateTime(now.year, now.month + 4, 1).millisecondsSinceEpoch,
      },
      {
        'id': 'goal_car',
        'name': 'Save for a Car',
        'icon_name': 'car',
        'color_value': 0xFFF0384F,
        'target_amount': 75000000,
        'saved_amount': 41250000,
        'created_at': goalBase,
        'deadline': DateTime(now.year + 1, now.month, 1).millisecondsSinceEpoch,
      },
      {
        'id': 'goal_education',
        'name': 'Save for Education',
        'icon_name': 'education',
        'color_value': 0xFF8B5CF6,
        'target_amount': 25000000,
        'saved_amount': 6250000,
        'created_at': goalBase,
        'deadline': DateTime(now.year + 2, now.month, 1).millisecondsSinceEpoch,
      },
      {
        'id': 'goal_vacation',
        'name': 'Vacation fund',
        'icon_name': 'vacation',
        'color_value': 0xFF4A9BF0,
        'target_amount': 50000000,
        'saved_amount': 32500000,
        'created_at': goalBase,
        'deadline': DateTime(now.year, now.month + 5, 1).millisecondsSinceEpoch,
      },
      {
        'id': 'goal_health',
        'name': 'Health Savings',
        'icon_name': 'health',
        'color_value': 0xFF4CBF7F,
        'target_amount': 30000000,
        'saved_amount': 13500000,
        'created_at': goalBase,
        'deadline': DateTime(
          now.year + 1,
          now.month + 6,
          1,
        ).millisecondsSinceEpoch,
      },
    ];
    for (final g in goals) {
      batch.insert('goals', g);
    }

    await batch.commit(noResult: true);
  }

  /// Rupees -> paisa, rounded to a believable 50-rupee-ish granularity.
  static int _amount(Random rng, int minRupees, int maxRupees) {
    final span = maxRupees - minRupees;
    final rupees = minRupees + (span == 0 ? 0 : rng.nextInt(span + 1));
    final cents = rng.nextInt(10) < 6 ? 0 : rng.nextInt(100);
    return rupees * 100 + cents;
  }

  static int _weighted(Random rng, List<int> weights) {
    final total = weights.fold<int>(0, (a, b) => a + b);
    var roll = rng.nextInt(total);
    for (var i = 0; i < weights.length; i++) {
      roll -= weights[i];
      if (roll < 0) return i;
    }
    return weights.length - 1;
  }
}

import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'seed.dart';

/// Opens and migrates the on-device SQLite file. Nothing in this app ever
/// leaves the handset — there is no network permission in the manifest.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const _fileName = 'kharcha.db';
  static const _version = 1;

  static Future<AppDatabase> open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _fileName);
    final db = await openDatabase(
      path,
      version: _version,
      onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, v) async {
        await _createSchema(d);
        await Seed.populate(d);
      },
      onUpgrade: _migrate,
    );
    return AppDatabase._(db);
  }

  /// Used by tests and by "reset all data" in Settings.
  static Future<void> _createSchema(Database d) async {
    final batch = d.batch();
    batch.execute('''
      CREATE TABLE accounts (
        id              TEXT PRIMARY KEY,
        name            TEXT NOT NULL,
        icon_name       TEXT NOT NULL,
        color_value     INTEGER NOT NULL,
        opening_balance INTEGER NOT NULL DEFAULT 0,
        sort_order      INTEGER NOT NULL DEFAULT 0
      )
    ''');
    batch.execute('''
      CREATE TABLE categories (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        icon_name   TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        type        TEXT NOT NULL,
        sort_order  INTEGER NOT NULL DEFAULT 0
      )
    ''');
    batch.execute('''
      CREATE TABLE txns (
        id          TEXT PRIMARY KEY,
        amount      INTEGER NOT NULL,
        type        TEXT NOT NULL,
        category_id TEXT NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
        account_id  TEXT NOT NULL REFERENCES accounts(id)   ON DELETE CASCADE,
        date        INTEGER NOT NULL,
        note        TEXT NOT NULL DEFAULT '',
        tags        TEXT NOT NULL DEFAULT ''
      )
    ''');
    batch.execute('CREATE INDEX idx_txns_date ON txns(date DESC)');
    batch.execute('CREATE INDEX idx_txns_category ON txns(category_id)');
    batch.execute('CREATE INDEX idx_txns_account ON txns(account_id)');
    batch.execute('''
      CREATE TABLE budgets (
        id              TEXT PRIMARY KEY,
        name            TEXT NOT NULL,
        icon_name       TEXT NOT NULL,
        color_value     INTEGER NOT NULL,
        limit_amount    INTEGER NOT NULL,
        category_id     TEXT REFERENCES categories(id) ON DELETE SET NULL,
        alerts_enabled  INTEGER NOT NULL DEFAULT 1,
        alert_threshold REAL NOT NULL DEFAULT 0.8,
        sort_order      INTEGER NOT NULL DEFAULT 0
      )
    ''');
    batch.execute('''
      CREATE TABLE goals (
        id            TEXT PRIMARY KEY,
        name          TEXT NOT NULL,
        icon_name     TEXT NOT NULL,
        color_value   INTEGER NOT NULL,
        target_amount INTEGER NOT NULL,
        saved_amount  INTEGER NOT NULL DEFAULT 0,
        created_at    INTEGER NOT NULL,
        deadline      INTEGER
      )
    ''');
    await batch.commit(noResult: true);
  }

  static Future<void> _migrate(Database d, int from, int to) async {
    // v1 is the first shipped schema; future versions append their steps here.
  }

  /// Drops every row and re-seeds. Backs the "Reset data" action in Settings.
  Future<void> resetToSeed() async {
    await db.transaction((t) async {
      for (final table in ['txns', 'budgets', 'goals', 'categories', 'accounts']) {
        await t.delete(table);
      }
      await Seed.populate(t);
    });
  }

  /// Drops every row and leaves only the default categories and accounts.
  Future<void> clearTransactions() async {
    await db.delete('txns');
  }

  Future<void> close() => db.close();
}

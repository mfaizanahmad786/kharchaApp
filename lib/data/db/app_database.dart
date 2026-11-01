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
  static const _version = 2;

  /// [factory] and [path] exist so tests can open an in-memory database
  /// through sqflite_common_ffi; the app passes neither.
  static Future<AppDatabase> open({
    String? path,
    DatabaseFactory? factory,
    bool seed = true,
  }) async {
    final f = factory ?? databaseFactory;
    final target = path ?? p.join(await f.getDatabasesPath(), _fileName);
    final db = await f.openDatabase(
      target,
      options: OpenDatabaseOptions(
        version: _version,
        onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
        onCreate: (d, v) async {
          await _createSchema(d);
          if (seed) await Seed.populate(d);
        },
        onUpgrade: _migrate,
      ),
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
        deadline      INTEGER,
        pinned        INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await batch.commit(noResult: true);
  }

  static Future<void> _migrate(Database d, int from, int to) async {
    // v1 is the first shipped schema; future versions append their steps here.
    if (from < 2) {
      // The Plan screen used to feature whichever goal sorted first, which
      // moved whenever a row was rewritten. It is now an explicit choice.
      await d.execute(
        'ALTER TABLE goals ADD COLUMN pinned INTEGER NOT NULL DEFAULT 0',
      );
      await d.execute(
        'UPDATE goals SET pinned = 1 WHERE id = ('
        'SELECT id FROM goals ORDER BY created_at DESC, id ASC LIMIT 1)',
      );
    }
  }

  /// Drops every row and re-seeds. Backs the "Reset data" action in Settings.
  Future<void> resetToSeed() async {
    await db.transaction((t) async {
      for (final table in [
        'txns',
        'budgets',
        'goals',
        'categories',
        'accounts',
      ]) {
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

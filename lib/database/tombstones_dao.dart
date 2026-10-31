import 'package:sqflite/sqflite.dart';
import '../models/tombstone.dart';
import 'database_helper.dart';

class TombstonesDao {
  final DatabaseHelper _dbHelper;

  TombstonesDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> addTombstone(
    String uuid,
    String entityType, {
    DateTime? deletedAt,
    Transaction? txn,
  }) async {
    final db = txn ?? await _dbHelper.database;
    final date = (deletedAt ?? DateTime.now()).toIso8601String();

    await db.insert(
      'tombstones',
      {
        'uuid': uuid,
        'entity_type': entityType,
        'deleted_at': date,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Keep legacy purged_checks table in sync if entity_type is check
    if (entityType == 'check') {
      await db.insert(
        'purged_checks',
        {
          'uuid': uuid,
          'purged_at': date,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Tombstone>> getAll({Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final rows = await db.query('tombstones', orderBy: 'deleted_at DESC');
    return rows.map((r) => Tombstone.fromMap(r)).toList();
  }

  Future<bool> isTombstoned(String uuid, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final rows = await db.query(
      'tombstones',
      columns: ['uuid'],
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<Tombstone?> getTombstone(String uuid, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final rows = await db.query(
      'tombstones',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Tombstone.fromMap(rows.first);
  }

  /// Remove tombstones older than retentionDays (default 90 days)
  Future<int> cleanOldTombstones(int retentionDays, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays)).toIso8601String();
    return await db.delete(
      'tombstones',
      where: 'deleted_at < ?',
      whereArgs: [cutoff],
    );
  }
}

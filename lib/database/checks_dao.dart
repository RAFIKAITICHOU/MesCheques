import 'package:sqflite/sqflite.dart';
import '../models/check.dart';
import '../models/check_filter.dart';
import '../services/auto_backup_service.dart';
import '../utils/text_normalizer.dart';
import 'database_helper.dart';

class ChecksDao {
  final DatabaseHelper _dbHelper;

  ChecksDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  void _notifyDataChanged([Transaction? txn]) {
    if (txn != null) return;
    try {
      AutoBackupService.instance.onDataChanged();
    } catch (_) {}
  }

  /// Check if an active check with this number already exists
  Future<bool> existsNumber(String checkNumber, {int? excludeId, String? excludeUuid, Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final trimmedNumber = checkNumber.trim();

    String sql = 'SELECT COUNT(*) FROM checks WHERE deleted_at IS NULL AND check_number = ? COLLATE NOCASE';
    List<dynamic> args = [trimmedNumber];

    if (excludeId != null) {
      sql += ' AND id != ?';
      args.add(excludeId);
    } else if (excludeUuid != null) {
      sql += ' AND uuid != ?';
      args.add(excludeUuid);
    }

    final result = await db.rawQuery(sql, args);
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  /// Get total count of active checks
  Future<int> countAll({Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM checks WHERE deleted_at IS NULL');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get active check by number
  Future<Check?> getActiveByNumber(String checkNumber, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'checks',
      where: 'deleted_at IS NULL AND check_number = ? COLLATE NOCASE',
      whereArgs: [checkNumber.trim()],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Check.fromMap(maps.first);
    }
    return null;
  }

  /// Insert a check
  Future<int> insert(Check check, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final id = await db.insert('checks', check.toMap());
    _notifyDataChanged(txn);
    return id;
  }

  /// Update an existing check by id or uuid
  Future<int> update(Check check, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    int affected;
    if (check.id != null) {
      affected = await db.update(
        'checks',
        check.toMap(),
        where: 'id = ?',
        whereArgs: [check.id],
      );
    } else {
      affected = await db.update(
        'checks',
        check.toMap(),
        where: 'uuid = ?',
        whereArgs: [check.uuid],
      );
    }
    _notifyDataChanged(txn);
    return affected;
  }

  /// Soft delete: move to trash
  Future<int> softDelete(int id, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final nowIso = DateTime.now().toIso8601String();
    final affected = await db.update(
      'checks',
      {
        'deleted_at': nowIso,
        'updated_at': nowIso,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyDataChanged(txn);
    return affected;
  }

  /// Restore from trash. Throws StateError if check_number is already used by an active check.
  Future<void> restore(int id, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;

    final List<Map<String, dynamic>> checkMaps = await db.query(
      'checks',
      columns: ['check_number'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (checkMaps.isEmpty) {
      throw Exception('Chèque introuvable.');
    }

    final checkNumber = checkMaps.first['check_number'] as String;

    final duplicateQuery = await db.rawQuery(
      'SELECT COUNT(*) FROM checks WHERE deleted_at IS NULL AND check_number = ? COLLATE NOCASE AND id != ?',
      [checkNumber, id],
    );
    final count = Sqflite.firstIntValue(duplicateQuery) ?? 0;
    if (count > 0) {
      throw StateError('Le numéro de chèque "$checkNumber" est déjà utilisé par un chèque actif.');
    }

    final nowIso = DateTime.now().toIso8601String();
    await db.update(
      'checks',
      {
        'deleted_at': null,
        'updated_at': nowIso,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyDataChanged(txn);
  }

  /// Permanent hard delete: records UUID in purged_checks to prevent resurrecting
  Future<int> hardDelete(int id, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final check = await getRawById(id, txn: txn);
    if (check != null) {
      await addPurgedCheck(check.uuid, DateTime.now().toIso8601String(), txn: txn);
    }
    final affected = await db.delete(
      'checks',
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyDataChanged(txn);
    return affected;
  }

  /// Empty trash completely: records all purged UUIDs
  Future<int> emptyTrash({Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final trashChecks = await db.query(
      'checks',
      columns: ['uuid'],
      where: 'deleted_at IS NOT NULL',
    );
    final nowIso = DateTime.now().toIso8601String();
    for (final row in trashChecks) {
      final uuid = row['uuid'] as String?;
      if (uuid != null) {
        await addPurgedCheck(uuid, nowIso, txn: txn);
      }
    }
    final affected = await db.delete(
      'checks',
      where: 'deleted_at IS NOT NULL',
    );
    _notifyDataChanged(txn);
    return affected;
  }

  /// Mark check as used
  Future<int> markAsUsed({
    required int id,
    required int paidToId,
    required String paidDate,
    Transaction? txn,
  }) async {
    final db = txn ?? await _dbHelper.database;
    final nowIso = DateTime.now().toIso8601String();
    final affected = await db.update(
      'checks',
      {
        'paid_to_id': paidToId,
        'paid_date': paidDate,
        'updated_at': nowIso,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyDataChanged(txn);
    return affected;
  }

  /// Cancel payment (back to stock)
  Future<int> cancelPayment(int id, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final nowIso = DateTime.now().toIso8601String();
    final affected = await db.update(
      'checks',
      {
        'paid_to_id': null,
        'paid_date': null,
        'updated_at': nowIso,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyDataChanged(txn);
    return affected;
  }

  /// Fetch check details by id
  Future<CheckWithNames?> getById(int id, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT c.*,
             g.name AS giver_name, g.name_normalized AS giver_name_normalized,
             d.name AS drawer_name, d.name_normalized AS drawer_name_normalized,
             p.name AS paid_to_name, p.name_normalized AS paid_to_name_normalized,
             (SELECT COUNT(*) FROM check_images i WHERE i.check_id = c.id) AS image_count,
             (SELECT file_name FROM check_images i WHERE i.check_id = c.id ORDER BY sort_order ASC, id ASC LIMIT 1) AS primary_image_file_name
      FROM checks c
      JOIN persons g       ON g.id = c.giver_id
      LEFT JOIN persons d  ON d.id = c.drawer_id
      LEFT JOIN persons p  ON p.id = c.paid_to_id
      WHERE c.id = ?
      LIMIT 1
      ''',
      [id],
    );

    if (maps.isNotEmpty) {
      return CheckWithNames.fromMap(maps.first);
    }
    return null;
  }

  /// Fetch raw check by id
  Future<Check?> getRawById(int id, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'checks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Check.fromMap(maps.first);
    }
    return null;
  }

  /// Fetch raw check by uuid
  Future<Check?> getByUuid(String uuid, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'checks',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Check.fromMap(maps.first);
    }
    return null;
  }

  /// Fetch check with names by uuid
  Future<CheckWithNames?> getWithNamesByUuid(String uuid, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT c.*,
             g.name AS giver_name, g.name_normalized AS giver_name_normalized,
             d.name AS drawer_name, d.name_normalized AS drawer_name_normalized,
             p.name AS paid_to_name, p.name_normalized AS paid_to_name_normalized,
             (SELECT COUNT(*) FROM check_images i WHERE i.check_id = c.id) AS image_count,
             (SELECT file_name FROM check_images i WHERE i.check_id = c.id ORDER BY sort_order ASC, id ASC LIMIT 1) AS primary_image_file_name
      FROM checks c
      JOIN persons g       ON g.id = c.giver_id
      LEFT JOIN persons d  ON d.id = c.drawer_id
      LEFT JOIN persons p  ON p.id = c.paid_to_id
      WHERE c.uuid = ?
      LIMIT 1
      ''',
      [uuid],
    );

    if (maps.isNotEmpty) {
      return CheckWithNames.fromMap(maps.first);
    }
    return null;
  }

  /// Query checks with filters, search, and sorting
  Future<List<CheckWithNames>> getChecks(CheckFilter filter) async {
    final db = await _dbHelper.database;
    final whereClauses = <String>['c.deleted_at IS NULL'];
    final args = <dynamic>[];

    _buildFilterClauses(filter, whereClauses, args);

    final whereString = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final orderByString = filter.sortOption.sqlOrderBy;

    final sql = '''
      SELECT c.*,
             g.name AS giver_name, g.name_normalized AS giver_name_normalized,
             d.name AS drawer_name, d.name_normalized AS drawer_name_normalized,
             p.name AS paid_to_name, p.name_normalized AS paid_to_name_normalized,
             (SELECT COUNT(*) FROM check_images i WHERE i.check_id = c.id) AS image_count,
             (SELECT file_name FROM check_images i WHERE i.check_id = c.id ORDER BY sort_order ASC, id ASC LIMIT 1) AS primary_image_file_name
      FROM checks c
      JOIN persons g       ON g.id = c.giver_id
      LEFT JOIN persons d  ON d.id = c.drawer_id
      LEFT JOIN persons p  ON p.id = c.paid_to_id
      $whereString
      ORDER BY $orderByString
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);
    return maps.map((m) => CheckWithNames.fromMap(m)).toList();
  }

  /// Get summary statistics for header badge
  Future<CheckStats> getStats() async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT
        COUNT(*) AS total_count,
        COALESCE(SUM(amount_cents), 0) AS total_amount,
        COUNT(CASE WHEN paid_to_id IS NULL THEN 1 END) AS in_stock_count,
        COALESCE(SUM(CASE WHEN paid_to_id IS NULL THEN amount_cents ELSE 0 END), 0) AS in_stock_amount,
        COUNT(CASE WHEN paid_to_id IS NOT NULL THEN 1 END) AS used_count,
        COALESCE(SUM(CASE WHEN paid_to_id IS NOT NULL THEN amount_cents ELSE 0 END), 0) AS used_amount
      FROM checks
      WHERE deleted_at IS NULL;
    ''');

    final row = result.first;
    return CheckStats(
      totalCount: (row['total_count'] as int?) ?? 0,
      totalAmountCents: (row['total_amount'] as int?) ?? 0,
      inStockCount: (row['in_stock_count'] as int?) ?? 0,
      inStockAmountCents: (row['in_stock_amount'] as int?) ?? 0,
      usedCount: (row['used_count'] as int?) ?? 0,
      usedAmountCents: (row['used_amount'] as int?) ?? 0,
    );
  }

  /// Get all checks currently in trash
  Future<List<CheckWithNames>> getTrashChecks() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT c.*,
             g.name AS giver_name, g.name_normalized AS giver_name_normalized,
             d.name AS drawer_name, d.name_normalized AS drawer_name_normalized,
             p.name AS paid_to_name, p.name_normalized AS paid_to_name_normalized,
             (SELECT COUNT(*) FROM check_images i WHERE i.check_id = c.id) AS image_count,
             (SELECT file_name FROM check_images i WHERE i.check_id = c.id ORDER BY sort_order ASC, id ASC LIMIT 1) AS primary_image_file_name
      FROM checks c
      JOIN persons g       ON g.id = c.giver_id
      LEFT JOIN persons d  ON d.id = c.drawer_id
      LEFT JOIN persons p  ON p.id = c.paid_to_id
      WHERE c.deleted_at IS NOT NULL
      ORDER BY c.deleted_at DESC
      ''',
    );
    return maps.map((m) => CheckWithNames.fromMap(m)).toList();
  }

  /// Auto-cleanup expired trash older than cutoffIso: records purged UUIDs
  Future<int> cleanupExpiredTrash(String cutoffIso, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final expired = await db.query(
      'checks',
      columns: ['uuid'],
      where: 'deleted_at IS NOT NULL AND deleted_at < ?',
      whereArgs: [cutoffIso],
    );
    final nowIso = DateTime.now().toIso8601String();
    for (final row in expired) {
      final uuid = row['uuid'] as String?;
      if (uuid != null) {
        await addPurgedCheck(uuid, nowIso, txn: txn);
      }
    }
    return await db.delete(
      'checks',
      where: 'deleted_at IS NOT NULL AND deleted_at < ?',
      whereArgs: [cutoffIso],
    );
  }

  /// All raw checks for backup/transfer export
  Future<List<Check>> getAllRawChecks({Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('checks', orderBy: 'id ASC');
    return maps.map((m) => Check.fromMap(m)).toList();
  }

  // -------------------------------------------------------------
  // Purged checks (tombstone) management
  // -------------------------------------------------------------

  /// Record a purged check uuid
  Future<void> addPurgedCheck(String uuid, String purgedAt, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    await db.insert(
      'purged_checks',
      {'uuid': uuid, 'purged_at': purgedAt},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    try {
      await db.insert(
        'tombstones',
        {'uuid': uuid, 'entity_type': 'check', 'deleted_at': purgedAt},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  /// Check if a uuid is in purged_checks
  Future<bool> isPurged(String uuid, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final result = await db.query(
      'purged_checks',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Get purged check record
  Future<Map<String, dynamic>?> getPurgedRecord(String uuid, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final result = await db.query(
      'purged_checks',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Get all purged checks records
  Future<List<Map<String, dynamic>>> getAllPurgedChecks({Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    return await db.query('purged_checks');
  }

  /// Clean up tombstone records older than retentionDays (e.g. 90 days)
  Future<int> cleanupOldPurgedRecords(int retentionDays, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final cutoffIso = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .toIso8601String();
    return await db.delete(
      'purged_checks',
      where: 'purged_at < ?',
      whereArgs: [cutoffIso],
    );
  }

  /// Helper to build query where clauses dynamically with normalized search
  void _buildFilterClauses(CheckFilter filter, List<String> whereClauses, List<dynamic> args) {
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final normalizedQuery = TextNormalizer.normalize(filter.searchQuery);
      final term = '%$normalizedQuery%';
      whereClauses.add('''
        (g.name_normalized LIKE ?
         OR (d.name_normalized IS NOT NULL AND d.name_normalized LIKE ?)
         OR (p.name_normalized IS NOT NULL AND p.name_normalized LIKE ?)
         OR c.search_text LIKE ?
         OR c.check_number LIKE ?)
      ''');
      args.addAll([term, term, term, term, '%${filter.searchQuery!.trim()}%']);
    }

    switch (filter.status) {
      case CheckStatusFilter.stock:
        whereClauses.add('c.paid_to_id IS NULL');
        break;
      case CheckStatusFilter.used:
        whereClauses.add('c.paid_to_id IS NOT NULL');
        break;
      case CheckStatusFilter.all:
        break;
    }

    if (filter.giverId != null) {
      whereClauses.add('c.giver_id = ?');
      args.add(filter.giverId);
    }

    if (filter.drawerId != null) {
      whereClauses.add('c.drawer_id = ?');
      args.add(filter.drawerId);
    }

    if (filter.paidToId != null) {
      whereClauses.add('c.paid_to_id = ?');
      args.add(filter.paidToId);
    }

    switch (filter.imageFilter) {
      case CheckImageFilter.withImage:
        whereClauses.add('(SELECT COUNT(*) FROM check_images i WHERE i.check_id = c.id) > 0');
        break;
      case CheckImageFilter.withoutImage:
        whereClauses.add('(SELECT COUNT(*) FROM check_images i WHERE i.check_id = c.id) = 0');
        break;
      case CheckImageFilter.all:
        break;
    }

    if (filter.minAmountCents != null) {
      whereClauses.add('c.amount_cents >= ?');
      args.add(filter.minAmountCents);
    }

    if (filter.maxAmountCents != null) {
      whereClauses.add('c.amount_cents <= ?');
      args.add(filter.maxAmountCents);
    }

    if (filter.checkDateFrom != null && filter.checkDateFrom!.isNotEmpty) {
      whereClauses.add('c.check_date >= ?');
      args.add(filter.checkDateFrom);
    }

    if (filter.checkDateTo != null && filter.checkDateTo!.isNotEmpty) {
      whereClauses.add('c.check_date <= ?');
      args.add(filter.checkDateTo);
    }

    if (filter.receivedDateFrom != null && filter.receivedDateFrom!.isNotEmpty) {
      whereClauses.add('c.received_date >= ?');
      args.add(filter.receivedDateFrom);
    }

    if (filter.receivedDateTo != null && filter.receivedDateTo!.isNotEmpty) {
      whereClauses.add('c.received_date <= ?');
      args.add(filter.receivedDateTo);
    }

    if (filter.checkNumber != null && filter.checkNumber!.trim().isNotEmpty) {
      whereClauses.add('c.check_number LIKE ? COLLATE NOCASE');
      args.add('%${filter.checkNumber!.trim()}%');
    }

    if (filter.notes != null && filter.notes!.trim().isNotEmpty) {
      final normalizedNotes = TextNormalizer.normalize(filter.notes);
      whereClauses.add('c.search_text LIKE ?');
      args.add('%$normalizedNotes%');
    }
  }
}

import 'package:sqflite/sqflite.dart';
import '../models/check_image.dart';
import '../services/auto_backup_service.dart';
import 'database_helper.dart';

class ImagesDao {
  final DatabaseHelper _dbHelper;

  ImagesDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  void _notifyDataChanged([Transaction? txn]) {
    if (txn != null) return;
    try {
      AutoBackupService.instance.onDataChanged();
    } catch (_) {}
  }

  /// Insert a check image
  Future<int> insert(CheckImage image, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final id = await db.insert('check_images', image.toMap());
    _notifyDataChanged(txn);
    return id;
  }

  /// Get all images for a check ordered by sort_order ASC, id ASC
  Future<List<CheckImage>> getByCheckId(int checkId, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'check_images',
      where: 'check_id = ?',
      whereArgs: [checkId],
      orderBy: 'sort_order ASC, id ASC',
    );
    return maps.map((m) => CheckImage.fromMap(m)).toList();
  }

  /// Get all images for a check by check UUID
  Future<List<CheckImage>> getByCheckUuid(String checkUuid, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT i.*
      FROM check_images i
      JOIN checks c ON c.id = i.check_id
      WHERE c.uuid = ?
      ORDER BY i.sort_order ASC, i.id ASC
      ''',
      [checkUuid],
    );
    return maps.map((m) => CheckImage.fromMap(m)).toList();
  }

  /// Get image by UUID
  Future<CheckImage?> getByUuid(String uuid, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'check_images',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return CheckImage.fromMap(maps.first);
    }
    return null;
  }

  /// Check if an image with the same sha256 already exists for this check
  Future<CheckImage?> findDuplicate(int checkId, String sha256, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'check_images',
      where: 'check_id = ? AND sha256 = ?',
      whereArgs: [checkId, sha256],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return CheckImage.fromMap(maps.first);
    }
    return null;
  }

  /// Count images for a check
  Future<int> countByCheckId(int checkId, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM check_images WHERE check_id = ?',
      [checkId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Update sort order of an image
  Future<int> updateOrder(int id, int sortOrder, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    return await db.update(
      'check_images',
      {'sort_order': sortOrder},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update kind (front, back, other)
  Future<int> updateKind(int id, String kind, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    return await db.update(
      'check_images',
      {'kind': kind},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete image by ID
  Future<int> deleteById(int id, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final affected = await db.delete(
      'check_images',
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyDataChanged(txn);
    return affected;
  }

  /// Delete all images for a check
  Future<int> deleteByCheckId(int checkId, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final affected = await db.delete(
      'check_images',
      where: 'check_id = ?',
      whereArgs: [checkId],
    );
    _notifyDataChanged(txn);
    return affected;
  }

  /// Get all raw images (for backup / sync)
  Future<List<CheckImage>> getAllRawImages({Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'check_images',
      orderBy: 'check_id ASC, sort_order ASC, id ASC',
    );
    return maps.map((m) => CheckImage.fromMap(m)).toList();
  }

  /// Convenience alias for getAllRawImages
  Future<List<CheckImage>> getAllImages({Transaction? txn}) => getAllRawImages(txn: txn);

  /// Get all internal file names in database (for orphan file cleanup)
  Future<List<String>> getAllFileNames({Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'check_images',
      columns: ['file_name'],
    );
    return maps.map((m) => m['file_name'] as String).toList();
  }
}

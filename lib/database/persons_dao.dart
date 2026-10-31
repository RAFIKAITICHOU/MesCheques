import 'package:sqflite/sqflite.dart';
import '../models/person.dart';
import '../services/auto_backup_service.dart';
import '../utils/text_normalizer.dart';
import 'database_helper.dart';

class PersonsDao {
  final DatabaseHelper _dbHelper;

  PersonsDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  void _notifyDataChanged([Transaction? txn]) {
    if (txn != null) return;
    try {
      AutoBackupService.instance.onDataChanged();
    } catch (_) {}
  }

  /// Finds existing person by normalized name (Arabic/French diacritic/accent-insensitive) or creates a new one
  Future<Person> findOrCreate(String name, {String? uuid, Transaction? txn}) async {
    final trimmedName = name.trim();
    final normalized = TextNormalizer.normalize(trimmedName);
    final db = txn ?? await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'persons',
      where: 'name_normalized = ?',
      whereArgs: [normalized],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Person.fromMap(maps.first);
    }

    final nowIso = DateTime.now().toIso8601String();
    final newPerson = Person(
      uuid: uuid,
      name: trimmedName,
      nameNormalized: normalized,
      createdAt: nowIso,
    );

    final id = await db.insert(
      'persons',
      newPerson.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    _notifyDataChanged(txn);

    // If there was a race condition and ignore triggered id 0
    if (id <= 0) {
      final existing = await db.query(
        'persons',
        where: 'name_normalized = ?',
        whereArgs: [normalized],
        limit: 1,
      );
      return Person.fromMap(existing.first);
    }

    return newPerson.copyWith(id: id);
  }

  /// Insert person directly
  Future<int> insert(Person person, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final id = await db.insert(
      'persons',
      person.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyDataChanged(txn);
    return id;
  }

  /// Autocomplete search for persons using normalized query
  Future<List<Person>> search(String query, {int limit = 8}) async {
    final db = await _dbHelper.database;
    final normalized = TextNormalizer.normalize(query);

    if (normalized.isEmpty) {
      final List<Map<String, dynamic>> maps = await db.query(
        'persons',
        orderBy: 'name_normalized ASC',
        limit: limit,
      );
      return maps.map((m) => Person.fromMap(m)).toList();
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT * FROM persons
      WHERE name_normalized LIKE ?
      ORDER BY name_normalized ASC
      LIMIT ?
      ''',
      ['%$normalized%', limit],
    );

    return maps.map((m) => Person.fromMap(m)).toList();
  }

  /// Get all persons
  Future<List<Person>> getAll({Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'persons',
      orderBy: 'name_normalized ASC',
    );
    return maps.map((m) => Person.fromMap(m)).toList();
  }

  /// Get person by id
  Future<Person?> getById(int id, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'persons',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Person.fromMap(maps.first);
    }
    return null;
  }

  /// Get person by uuid
  Future<Person?> getByUuid(String uuid, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'persons',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Person.fromMap(maps.first);
    }
    return null;
  }

  /// Get person by normalized name
  Future<Person?> getByNormalized(String normalized, {Transaction? txn}) async {
    final db = txn ?? await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'persons',
      where: 'name_normalized = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Person.fromMap(maps.first);
    }
    return null;
  }
}

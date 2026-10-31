import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';
import '../utils/text_normalizer.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mescheques.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE persons (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid             TEXT NOT NULL UNIQUE,
        name             TEXT NOT NULL,
        name_normalized  TEXT NOT NULL UNIQUE,
        created_at       TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE checks (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid            TEXT NOT NULL UNIQUE,
        check_number    TEXT    NOT NULL,
        amount_cents    INTEGER NOT NULL CHECK (amount_cents > 0),
        check_date      TEXT    NOT NULL,
        received_date   TEXT    NOT NULL,
        giver_id        INTEGER NOT NULL REFERENCES persons(id) ON DELETE RESTRICT,
        drawer_id       INTEGER REFERENCES persons(id) ON DELETE SET NULL,
        paid_to_id      INTEGER REFERENCES persons(id) ON DELETE SET NULL,
        paid_date       TEXT,
        notes           TEXT,
        search_text     TEXT,
        created_at      TEXT NOT NULL,
        updated_at      TEXT NOT NULL,
        deleted_at      TEXT,
        CHECK ( (paid_to_id IS NULL AND paid_date IS NULL)
             OR (paid_to_id IS NOT NULL AND paid_date IS NOT NULL) )
      );
    ''');

    // Partial unique index for active checks
    await db.execute('''
      CREATE UNIQUE INDEX idx_check_number_active
        ON checks(check_number) WHERE deleted_at IS NULL;
    ''');

    // Images table
    await db.execute('''
      CREATE TABLE check_images (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid        TEXT NOT NULL UNIQUE,
        check_id    INTEGER NOT NULL REFERENCES checks(id) ON DELETE CASCADE,
        file_name   TEXT NOT NULL,
        kind        TEXT NOT NULL DEFAULT 'front',
        sort_order  INTEGER NOT NULL DEFAULT 0,
        size_bytes  INTEGER NOT NULL,
        sha256      TEXT NOT NULL,
        created_at  TEXT NOT NULL
      );
    ''');

    // Tombstone table for permanently purged checks (legacy compatibility)
    await db.execute('''
      CREATE TABLE purged_checks (
        uuid       TEXT PRIMARY KEY,
        purged_at  TEXT NOT NULL
      );
    ''');

    // General tombstones table (uuid, entity_type, deleted_at)
    await db.execute('''
      CREATE TABLE tombstones (
        uuid        TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        deleted_at  TEXT NOT NULL
      );
    ''');

    // App metadata table (last_backup_at, changes_counter, drive_file_id, etc.)
    await db.execute('''
      CREATE TABLE app_meta (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    // Performance & search indexes
    await db.execute('CREATE INDEX idx_persons_uuid ON persons(uuid);');
    await db.execute('CREATE INDEX idx_persons_normalized ON persons(name_normalized);');
    await db.execute('CREATE INDEX idx_checks_uuid ON checks(uuid);');
    await db.execute('CREATE INDEX idx_checks_created ON checks(created_at);');
    await db.execute('CREATE INDEX idx_checks_giver ON checks(giver_id);');
    await db.execute('CREATE INDEX idx_checks_drawer ON checks(drawer_id);');
    await db.execute('CREATE INDEX idx_checks_paid_to ON checks(paid_to_id);');
    await db.execute('CREATE INDEX idx_checks_deleted ON checks(deleted_at);');
    await db.execute('CREATE INDEX idx_checks_search ON checks(search_text);');
    await db.execute('CREATE INDEX idx_images_check ON check_images(check_id);');
    await db.execute('CREATE INDEX idx_images_uuid ON check_images(uuid);');
    await db.execute('CREATE INDEX idx_tombstones_deleted ON tombstones(deleted_at);');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _ensureSchemaIntegrity(db);
  }

  Future<void> _onOpen(Database db) async {
    await _ensureSchemaIntegrity(db);
  }

  /// Self-healing schema validation: ensures all required columns, tables, and indexes exist
  Future<void> _ensureSchemaIntegrity(Database db) async {
    // 1. Verify persons table
    final personTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='persons';",
    );
    if (personTables.isNotEmpty) {
      final personColumns = await db.rawQuery('PRAGMA table_info(persons);');
      final colNames = personColumns.map((c) => c['name'] as String).toSet();

      // Ensure uuid column exists
      if (!colNames.contains('uuid')) {
        await db.execute('ALTER TABLE persons ADD COLUMN uuid TEXT;');
        final persons = await db.query('persons', columns: ['id']);
        const uuidGen = Uuid();
        for (final p in persons) {
          final id = p['id'] as int;
          await db.update('persons', {'uuid': uuidGen.v4()}, where: 'id = ?', whereArgs: [id]);
        }
        await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_persons_uuid ON persons(uuid);');
      }

      // Ensure name_normalized column exists
      if (!colNames.contains('name_normalized')) {
        await db.execute('ALTER TABLE persons ADD COLUMN name_normalized TEXT;');
        final persons = await db.query('persons', columns: ['id', 'name']);
        for (final p in persons) {
          final id = p['id'] as int;
          final name = (p['name'] as String? ?? '').trim();
          final norm = TextNormalizer.normalize(name);
          await db.update('persons', {'name_normalized': norm}, where: 'id = ?', whereArgs: [id]);
        }
        await db.execute('CREATE INDEX IF NOT EXISTS idx_persons_normalized ON persons(name_normalized);');
      }
    }

    // 2. Verify checks table
    final checkTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='checks';",
    );
    if (checkTables.isNotEmpty) {
      final checkColumns = await db.rawQuery('PRAGMA table_info(checks);');
      final colNames = checkColumns.map((c) => c['name'] as String).toSet();

      // Ensure uuid column exists
      if (!colNames.contains('uuid')) {
        await db.execute('ALTER TABLE checks ADD COLUMN uuid TEXT;');
        final checks = await db.query('checks', columns: ['id']);
        const uuidGen = Uuid();
        for (final c in checks) {
          final id = c['id'] as int;
          await db.update('checks', {'uuid': uuidGen.v4()}, where: 'id = ?', whereArgs: [id]);
        }
        await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_checks_uuid ON checks(uuid);');
      }

      // Ensure drawer_id column exists
      if (!colNames.contains('drawer_id')) {
        await db.execute('ALTER TABLE checks ADD COLUMN drawer_id INTEGER REFERENCES persons(id) ON DELETE SET NULL;');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_checks_drawer ON checks(drawer_id);');
      }

      // Ensure search_text column exists
      if (!colNames.contains('search_text')) {
        await db.execute('ALTER TABLE checks ADD COLUMN search_text TEXT;');
        final checks = await db.query('checks', columns: ['id', 'check_number', 'notes']);
        for (final c in checks) {
          final id = c['id'] as int;
          final checkNumber = (c['check_number'] as String? ?? '').trim();
          final notes = (c['notes'] as String? ?? '').trim();
          final norm = TextNormalizer.normalize('$checkNumber $notes');
          await db.update('checks', {'search_text': norm}, where: 'id = ?', whereArgs: [id]);
        }
        await db.execute('CREATE INDEX IF NOT EXISTS idx_checks_search ON checks(search_text);');
      }
    }

    // 3. Ensure check_images table exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS check_images (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid        TEXT NOT NULL UNIQUE,
        check_id    INTEGER NOT NULL REFERENCES checks(id) ON DELETE CASCADE,
        file_name   TEXT NOT NULL,
        kind        TEXT NOT NULL DEFAULT 'front',
        sort_order  INTEGER NOT NULL DEFAULT 0,
        size_bytes  INTEGER NOT NULL,
        sha256      TEXT NOT NULL,
        created_at  TEXT NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_images_check ON check_images(check_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_images_uuid ON check_images(uuid);');

    // 4. Ensure purged_checks tombstone table exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purged_checks (
        uuid       TEXT PRIMARY KEY,
        purged_at  TEXT NOT NULL
      );
    ''');

    // 5. Ensure tombstones table exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tombstones (
        uuid        TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        deleted_at  TEXT NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tombstones_deleted ON tombstones(deleted_at);');

    // 6. Ensure app_meta table exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_meta (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    // Sync any existing purged_checks into tombstones
    try {
      final purged = await db.query('purged_checks');
      for (final row in purged) {
        final u = row['uuid'] as String?;
        final d = row['purged_at'] as String?;
        if (u != null && d != null) {
          await db.insert(
            'tombstones',
            {'uuid': u, 'entity_type': 'check', 'deleted_at': d},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    } catch (_) {}
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Visible for testing: inject an in-memory database
  void setDatabaseForTesting(Database? db) {
    _database = db;
  }

  /// Visible for testing: manually trigger table creation
  Future<void> createTablesForTesting(Database db) => _createDB(db, AppConstants.dbVersion);

  /// Visible for testing: manually trigger schema integrity validation
  Future<void> ensureSchemaIntegrityForTesting(Database db) => _ensureSchemaIntegrity(db);
}

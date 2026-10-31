import 'package:flutter_test/flutter_test.dart';
import 'package:mescheques/database/database_helper.dart';
import 'package:mescheques/database/persons_dao.dart';
import 'package:mescheques/utils/text_normalizer.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('Database migration and schema self-healing tests', () {
    late Database db;
    late DatabaseHelper helper;

    setUp(() async {
      final dbFactory = databaseFactoryFfi;
      db = await dbFactory.openDatabase(inMemoryDatabasePath);
      helper = DatabaseHelper.instance;
      helper.setDatabaseForTesting(db);
    });

    tearDown(() async {
      await db.close();
      helper.setDatabaseForTesting(null);
    });

    test('Self-heals older schema missing name_normalized and search_text', () async {
      // 1. Simulate an old schema (v1) where persons table only had id, name, created_at
      await db.execute('''
        CREATE TABLE persons (
          id         INTEGER PRIMARY KEY AUTOINCREMENT,
          name       TEXT NOT NULL,
          created_at TEXT NOT NULL
        );
      ''');

      await db.execute('''
        CREATE TABLE checks (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          check_number    TEXT    NOT NULL,
          amount_cents    INTEGER NOT NULL,
          check_date      TEXT    NOT NULL,
          received_date   TEXT    NOT NULL,
          giver_id        INTEGER NOT NULL,
          paid_to_id      INTEGER,
          paid_date       TEXT,
          notes           TEXT,
          created_at      TEXT NOT NULL,
          updated_at      TEXT NOT NULL,
          deleted_at      TEXT
        );
      ''');

      // Insert pre-existing person without uuid or name_normalized
      await db.insert('persons', {
        'name': 'Hélène Aït Ali',
        'created_at': DateTime.now().toIso8601String(),
      });

      await db.insert('persons', {
        'name': 'أحمد بن محمد',
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Trigger schema integrity self-healing
      await helper.ensureSchemaIntegrityForTesting(db);

      // Verify columns in persons
      final personColumns = await db.rawQuery('PRAGMA table_info(persons)');
      final personColNames = personColumns.map((c) => c['name'] as String).toSet();
      expect(personColNames.contains('uuid'), isTrue);
      expect(personColNames.contains('name_normalized'), isTrue);

      // Verify columns in checks
      final checkColumns = await db.rawQuery('PRAGMA table_info(checks)');
      final checkColNames = checkColumns.map((c) => c['name'] as String).toSet();
      expect(checkColNames.contains('uuid'), isTrue);
      expect(checkColNames.contains('search_text'), isTrue);

      // Verify purged_checks table exists
      final purgedTable = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='purged_checks';",
      );
      expect(purgedTable.isNotEmpty, isTrue);

      // Verify populated normalized values
      final persons = await db.query('persons', orderBy: 'id ASC');
      expect(persons[0]['name_normalized'], equals(TextNormalizer.normalize('Hélène Aït Ali')));
      expect(persons[1]['name_normalized'], equals(TextNormalizer.normalize('أحمد بن محمد')));
      expect(persons[0]['uuid'], isNotNull);
      expect((persons[0]['uuid'] as String).isNotEmpty, isTrue);

      // 3. Verify PersonsDao works seamlessly now (autocomplete search and findOrCreate)
      final personsDao = PersonsDao(dbHelper: helper);

      // Search normalized
      final results1 = await personsDao.search('helene');
      expect(results1.length, equals(1));
      expect(results1.first.name, equals('Hélène Aït Ali'));

      final results2 = await personsDao.search('احمد');
      expect(results2.length, equals(1));
      expect(results2.first.name, equals('أحمد بن محمد'));

      // findOrCreate new person
      final created = await personsDao.findOrCreate('Karim Tazi');
      expect(created.id, isNotNull);
      expect(created.nameNormalized, equals('karim tazi'));
    });
  });
}
